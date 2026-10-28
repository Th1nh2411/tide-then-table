"""Generate and reduce image-to-shape assets with Hunyuan3D-2mini on this machine (CPU).

Main tool; tools/art/hunyuan_job.py (public 2.1 Space) is the fallback. Run through
tools/art/hunyuan_local.ps1, which picks the Hunyuan3D-2 venv and local weights:
    powershell -File tools/art/hunyuan_local.ps1 -Image assets/concepts/x.png \
        -OutDir assets/models/pilots/x -Name x -Faces 2000
Several images (or -InputDir) = batch: each goes to <OutDir>/<image stem>/.
~3.5 min per asset on CPU (octree 128, FlashVDM). No texture or rig is generated.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import json
import os
import shutil
import sys
import time

HY3D_HOME = Path(os.environ.get('HY3D_HOME', 'E:/workSpace/Hunyuan3D-2'))
sys.path.insert(0, str(HY3D_HOME))
import torch
from PIL import Image
from hy3dgen.rembg import BackgroundRemover
from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline, FloaterRemover, DegenerateFaceRemover, FaceReducer

REPO = 'tencent/Hunyuan3D-2mini'
ROOT = Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def repo_path(path):
    # Forward slashes, repo-relative when possible, so the checker works on any OS.
    path = path.resolve()
    return path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path.as_posix()


def has_alpha(image):
    # Concept PNGs that are already cut out skip rembg.
    return image.mode == 'RGBA' and image.getchannel('A').getextrema()[0] < 255


def load_pipeline(subfolder, flashvdm):
    models = Path(os.environ.get('HY3DGEN_MODELS', 'E:/workSpace/hy3d_models'))
    weights = models/REPO/subfolder/'model.fp16.safetensors'
    assert weights.is_file(), f'Missing weights: {weights} (see docs/ART_PIPELINE.md)'
    os.environ['HY3DGEN_MODELS'] = str(models)
    pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
        REPO, subfolder=subfolder, use_safetensors=True, device='cpu', dtype=torch.float32)
    info = {'file': f'{REPO}/{subfolder}/{weights.name}', 'bytes': weights.stat().st_size}
    if flashvdm:
        vae = models/REPO/'hunyuan3d-vae-v2-mini-turbo/model.fp16.safetensors'
        assert vae.is_file(), f'Missing FlashVDM VAE: {vae} (see docs/ART_PIPELINE.md)'
        pipe.enable_flashvdm(mc_algo='mc')
        pipe.vae.to(dtype=torch.float32)  # turbo VAE loads as fp16; CPU needs fp32
        info['flashvdm_vae'] = {'file': f'{REPO}/hunyuan3d-vae-v2-mini-turbo/{vae.name}', 'bytes': vae.stat().st_size}
    return pipe, info


def run_one(pipe, weights, rembg, image_path, out, name, args):
    out.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    raw = out/(name+'_raw.glb')
    reduced = out/(name+'_reduced.glb')
    for path in [raw, reduced]:
        if path.exists():
            backup = ROOT/'build/art_pilots/backups'/stamp/name/path.name
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, backup)
    parameters = {'steps': args.steps, 'guidance_scale': 5.0, 'seed': args.seed,
                  'octree_resolution': args.octree, 'num_chunks': 8000}
    record = {'provider': REPO, 'runtime': 'local CPU, float32', 'model_subfolder': args.model,
              'weights': weights, 'code': 'https://github.com/Tencent-Hunyuan/Hunyuan3D-2',
              'started_utc': datetime.now(timezone.utc).isoformat(),
              'input': repo_path(image_path), 'input_sha256': digest(image_path),
              'shape_parameters': parameters, 'texture_generated': False, 'rig_generated': False,
              'reduction': {'target_face_num': args.faces, 'file_type': 'glb', 'tool': 'hy3dgen FaceReducer'}}
    provenance_path = out/'hunyuan_provenance.json'
    try:
        image = Image.open(image_path)
        cut = has_alpha(image)
        image = image.convert('RGBA') if cut else rembg(image.convert('RGB'))
        record['background_removed'] = not cut
        start = time.monotonic()
        mesh = pipe(image=image, num_inference_steps=args.steps, guidance_scale=5.0,
                    octree_resolution=args.octree, num_chunks=8000,
                    generator=torch.manual_seed(args.seed), output_type='trimesh')[0]
        mesh = DegenerateFaceRemover()(FloaterRemover()(mesh))
        mesh.export(raw)
        record['shape_stats'] = {'number_of_faces': len(mesh.faces), 'number_of_vertices': len(mesh.vertices),
                                 'seconds': round(time.monotonic()-start, 1)}
        low = FaceReducer()(mesh, max_facenum=args.faces)
        low.export(reduced, file_type='glb', include_normals=True)
        record.update({'status': 'success', 'raw': raw.name, 'reduced': reduced.name,
                       'raw_sha256': digest(raw), 'reduced_sha256': digest(reduced),
                       'reduced_faces': len(low.faces)})
        license_path = ROOT/'assets/models/characters/rin_hunyuan_shape/LICENSE-HUNYUAN.txt'
        if license_path.exists() and not (out/'LICENSE-HUNYUAN.txt').exists():
            shutil.copy2(license_path, out/'LICENSE-HUNYUAN.txt')
        print('HUNYUAN_OK', name, record['shape_stats']['seconds'], 's', raw, reduced, flush=True)
    except Exception as error:
        record.update({'status': 'failed', 'error_type': type(error).__name__, 'error': str(error)})
        raise
    finally:
        provenance_path.write_text(json.dumps(record, indent=2, default=str)+'\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', type=Path, nargs='*', default=[])
    parser.add_argument('--input-dir', type=Path, help='Batch every PNG in this folder')
    parser.add_argument('--out-dir', type=Path, required=True)
    parser.add_argument('--name', help='Output ID for a single image (default: image stem)')
    parser.add_argument('--faces', type=int, default=2000)
    parser.add_argument('--steps', type=int, default=5)
    parser.add_argument('--octree', type=int, default=128)
    parser.add_argument('--seed', type=int, default=1234)
    parser.add_argument('--model', default='hunyuan3d-dit-v2-mini-turbo')
    parser.add_argument('--no-flashvdm', dest='flashvdm', action='store_false',
                        help='Old volume decoding (~10 min/asset instead of ~3.5; same shape on stool/Rin/table)')
    args = parser.parse_args()
    images = list(args.image)
    if args.input_dir:
        images += sorted(args.input_dir.glob('*.png'))
    assert images, 'Give --image or --input-dir'
    for image in images:
        assert image.is_file(), image
    batch = len(images) > 1
    assert not (batch and args.name), '--name is for a single image'
    jobs = []
    for image in images:
        name = args.name or image.stem
        assert name.replace('_', '').isalnum(), f'Use a filename ID, not a path: {name}'
        jobs.append((image, args.out_dir/name if batch else args.out_dir, name))
    print('Loading', REPO, args.model, 'on CPU', flush=True)
    pipe, weights = load_pipeline(args.model, args.flashvdm)
    rembg = BackgroundRemover()
    failures = 0
    for index, (image, out, name) in enumerate(jobs, 1):
        print(f'[{index}/{len(jobs)}] {image}', flush=True)
        try:
            run_one(pipe, weights, rembg, image, out.resolve(), name, args)
        except Exception as error:
            failures += 1
            print('HUNYUAN_FAIL', name, type(error).__name__, error, flush=True)
            if not batch:
                raise
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
