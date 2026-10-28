"""Generate and reduce an image-to-shape asset using Tencent's public Space.

Run in an isolated client environment, for example:
uvx --from gradio-client==1.3.0 python tools/art/hunyuan_job.py \
    --image assets/concepts/example.png --out-dir assets/models/pilots/example \
    --name example --faces 2000

Uploads the specified image to the public Tencent demo. No paid provider or
local model installation is used. The returned mesh has no generated textures/rig.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import json
import shutil
import time
from gradio_client import Client, handle_file

SPACE = 'tencent/Hunyuan3D-2.1'
ROOT = Path(__file__).resolve().parents[2]


def wait_job(job, seconds=300):
    start = time.monotonic()
    last = None
    while not job.done():
        status = job.status()
        code = str(status.code)
        if code != last:
            print('HUNYUAN_STATUS', code, 'rank', status.rank, flush=True)
            last = code
        if time.monotonic()-start > seconds:
            job.cancel()
            raise TimeoutError(f'Stopped public Space job after {seconds}s')
        time.sleep(2)
    return job.result()


def returned_file(value):
    if isinstance(value, dict):
        value = value.get('value', value.get('path'))
    if isinstance(value, dict):
        value = value.get('path')
    path = Path(value)
    if not path.is_file():
        raise FileNotFoundError('Gradio returned no downloaded mesh: '+str(path))
    return path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', type=Path, required=True)
    parser.add_argument('--out-dir', type=Path, required=True)
    parser.add_argument('--name', required=True)
    parser.add_argument('--faces', type=int, default=2000)
    parser.add_argument('--steps', type=int, default=20)
    parser.add_argument('--octree', type=int, default=192)
    parser.add_argument('--seed', type=int, default=1234)
    parser.add_argument('--timeout', type=int, default=300)
    parser.add_argument('--reuse-raw', action='store_true', help='Only reduce a raw result already in the output directory')
    args = parser.parse_args()
    assert args.image.is_file(), args.image
    assert args.name.replace('_', '').isalnum(), 'Use a filename ID, not a path'
    out = args.out_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    download_dir = ROOT/'build/art_pilots/downloads'/args.name/stamp
    download_dir.mkdir(parents=True, exist_ok=True)
    raw = out/(args.name+'_raw.glb')
    reduced = out/(args.name+'_reduced.glb')
    # Back up only files this command may replace. Keep raw intact in reduce-only runs.
    for path in ([reduced] if args.reuse_raw else [raw, reduced]):
        if path.exists():
            backup = ROOT/'build/art_pilots/backups'/stamp/args.name/path.name
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, backup)
    parameters = {'steps': args.steps, 'guidance_scale': 5.0, 'seed': args.seed,
                  'octree_resolution': args.octree, 'check_box_rembg': True,
                  'num_chunks': 8000, 'randomize_seed': False}
    provenance_path = out/'hunyuan_provenance.json'
    old = json.loads(provenance_path.read_text()) if provenance_path.exists() else {}
    record = dict(old) if args.reuse_raw else {}
    record.update({'provider': SPACE, 'space': 'https://huggingface.co/spaces/'+SPACE,
                   'client_version': 'gradio-client==1.3.0', 'started_utc': datetime.now(timezone.utc).isoformat(),
                   'input': str(args.image), 'input_sha256': digest(args.image),
                   'shape_parameters': old.get('shape_parameters', parameters) if args.reuse_raw else parameters,
                   'texture_generated': False, 'rig_generated': False,
                   'reduction': {'target_face_num': args.faces, 'file_type': 'glb', 'reduce_face': True, 'export_texture': False}})
    print('Connecting to official Tencent Space:', args.name, flush=True)
    try:
        client = Client(SPACE, download_files=str(download_dir), hf_token=False, verbose=False)
        if not args.reuse_raw:
            print('Submitting shape:', args.image, flush=True)
            result = wait_job(client.submit(image=handle_file(str(args.image.resolve())),
                              mv_image_front=None, mv_image_back=None, mv_image_left=None, mv_image_right=None,
                              **parameters, api_name='/shape_generation'), args.timeout)
            shutil.copy2(returned_file(result[0]), raw)
            record['shape_stats'] = result[2]
            record['raw_sha256'] = digest(raw)
            record['status'] = 'shape_complete'
            provenance_path.write_text(json.dumps(record, indent=2, default=str)+'\n')
        assert raw.is_file(), 'No raw mesh available for reduction'
        print('Submitting reduction:', args.faces, flush=True)
        result = wait_job(client.submit(file_out=handle_file(str(raw)), file_out2=None,
                          file_type='glb', reduce_face=True, export_texture=False,
                          target_face_num=args.faces, api_name='/on_export_click'), args.timeout)
        shutil.copy2(returned_file(result[1]), reduced)
        record.update({'status': 'success', 'reduced_sha256': digest(reduced),
                       'raw': raw.name, 'reduced': reduced.name})
        license_path = ROOT/'assets/models/characters/rin_hunyuan_shape/LICENSE-HUNYUAN.txt'
        if license_path.exists() and not (out/'LICENSE-HUNYUAN.txt').exists():
            shutil.copy2(license_path, out/'LICENSE-HUNYUAN.txt')
        print('HUNYUAN_OK', raw, reduced, flush=True)
    except Exception as error:
        record.update({'status': 'failed', 'error_type': type(error).__name__, 'error': str(error)})
        raise
    finally:
        provenance_path.write_text(json.dumps(record, indent=2, default=str)+'\n')


if __name__ == '__main__':
    main()
