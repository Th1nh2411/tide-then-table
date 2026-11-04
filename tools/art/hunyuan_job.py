"""Generate and reduce an image-to-shape asset using Tencent's public Space.

Fallback only (quota-limited): the main tool is tools/art/hunyuan_local.py.
On Windows: tools/art/hunyuan.ps1.

Run in an isolated client environment, for example:
uvx --from gradio-client==1.3.0 python tools/art/hunyuan_job.py \
    --image assets/concepts/example.png --out-dir assets/models/ready/example \
    --name example --faces 2000

Uploads the specified image to the public Tencent demo. No paid provider or
local model installation is used. The returned mesh has no generated textures/rig.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import json
import os
import shutil
import time
import httpx
from urllib.parse import urlsplit
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


def returned_file(value, client, download_dir):
    if isinstance(value, dict):
        value = value.get('value', value.get('path'))
    if isinstance(value, dict):
        value = value.get('path')
    path = Path(value)
    if path.is_file() and path.resolve().is_relative_to(download_dir.resolve()):
        return path
    url = value if str(value).startswith('https://') else client.src.rstrip('/')+'/file='+str(value)
    if (urlsplit(url).scheme, urlsplit(url).netloc) != (urlsplit(client.src).scheme, urlsplit(client.src).netloc):
        raise ValueError('Mesh result must belong to the connected Space')
    target = download_dir/path.name
    partial = target.with_suffix(target.suffix+'.part')
    print('Downloading mesh:', path.name, flush=True)
    for attempt in range(3):
        try:
            with httpx.stream('GET', url, headers=client.headers, cookies=client.cookies,
                              follow_redirects=True, timeout=120.0) as response:
                response.raise_for_status()
                with partial.open('wb') as output:
                    for chunk in response.iter_bytes():
                        output.write(chunk)
            partial.replace(target)
            return target
        except (httpx.TransportError, httpx.HTTPStatusError):
            partial.unlink(missing_ok=True)
            if attempt == 2:
                raise
            print('Retrying mesh download (no new GPU job)', attempt+1, flush=True)


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
    parser.add_argument('--fresh', action='store_true', help='Ignore a cached remote shape result and generate again')
    parser.add_argument('--direct-space', action='store_true', help='Connect to the same official Space URL without the Hub runtime lookup')
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
    resume_result = (not args.fresh and old.get('input_sha256') == digest(args.image)
                     and old.get('shape_parameters') == parameters and old.get('shape_result_reference'))
    record = dict(old) if args.reuse_raw or resume_result else {}
    record.update({'provider': SPACE, 'space': 'https://huggingface.co/spaces/'+SPACE,
                   'client_version': 'gradio-client==1.3.0', 'started_utc': datetime.now(timezone.utc).isoformat(),
                   'input': str(args.image), 'input_sha256': digest(args.image),
                   'shape_parameters': old.get('shape_parameters', parameters) if args.reuse_raw else parameters,
                   'texture_generated': False, 'rig_generated': False,
                   'reduction': {'target_face_num': args.faces, 'file_type': 'glb', 'reduce_face': True, 'export_texture': False}})
    print('Connecting to official Tencent Space:', args.name, flush=True)
    try:
        token = os.environ.get('HF_TOKEN') or False
        print('Authentication:', 'HF_TOKEN' if token else 'anonymous', flush=True)
        # Large GLB downloads can pause longer than httpx's short default timeout.
        endpoint = 'https://tencent-hunyuan3d-2-1.hf.space/' if args.direct_space else SPACE
        client = Client(endpoint, download_files=False, hf_token=token, verbose=False,
                        httpx_kwargs={'timeout': 120.0})
        if not args.reuse_raw:
            if resume_result:
                print('Resuming cached shape download (no new GPU job)', flush=True)
                reference = old['shape_result_reference']
            else:
                print('Submitting shape:', args.image, flush=True)
                result = wait_job(client.submit(image=handle_file(str(args.image.resolve())),
                              mv_image_front=None, mv_image_back=None, mv_image_left=None, mv_image_right=None,
                              **parameters, api_name='/shape_generation'), args.timeout)
                reference = result[0]
                record['shape_result_reference'] = reference
                record['shape_stats'] = result[2]
                record['status'] = 'shape_generated'
                provenance_path.write_text(json.dumps(record, indent=2, default=str)+'\n')
            shutil.copy2(returned_file(reference, client, download_dir), raw)
            record['raw_sha256'] = digest(raw)
            record['status'] = 'shape_complete'
            provenance_path.write_text(json.dumps(record, indent=2, default=str)+'\n')
        assert raw.is_file(), 'No raw mesh available for reduction'
        print('Submitting reduction:', args.faces, flush=True)
        result = wait_job(client.submit(file_out=handle_file(str(raw)), file_out2=None,
                          file_type='glb', reduce_face=True, export_texture=False,
                          target_face_num=args.faces, api_name='/on_export_click'), args.timeout)
        record['reduction_result_reference'] = result[1]
        provenance_path.write_text(json.dumps(record, indent=2, default=str)+'\n')
        shutil.copy2(returned_file(result[1], client, download_dir), reduced)
        record.update({'status': 'success', 'reduced_sha256': digest(reduced),
                       'raw': raw.name, 'reduced': reduced.name})
        if 'error' in record:
            record.setdefault('previous_failures', []).append({
                'error_type': record.pop('error_type', None),
                'error': record.pop('error')})
        license_path = ROOT/'assets/models/characters/rin_hunyuan_shape/LICENSE-HUNYUAN.txt'
        if not license_path.exists():
            license_path = ROOT/'assets/models/LICENSE-HUNYUAN.txt'
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
