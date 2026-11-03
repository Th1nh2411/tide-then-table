"""Stage the 25 completed Hunyuan props and derive runtime scale/material data.

uv run --with trimesh --with pillow python tools/art/prepare_horror_models.py
No inference, paid calls, scene edits, or changes to the source concepts.
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import struct
from datetime import datetime
import numpy as np
import trimesh
from PIL import Image
from glb_common import load_glb, read_accessor

ROOT = Path(__file__).resolve().parents[2]
GROUPS = {
    2000: 'fish_ca_thu fish_ca_mu fish_muc fish_cua fish_tom fish_oc_huong fish_glowing fishing_bobber hat_hook water_jar low_table_tea altar_ong_tu'.split(),
    3000: 'fish_basket fishing_rod bamboo_fence banana_clump power_pole roadside_shrine fishing_nets_drying stone_steps wooden_bed wooden_wardrobe'.split(),
    5000: 'rin_house neighbour_house_a neighbour_house_b'.split(),
}


def with_normals(source):
    """Append normals only; preserve source position/index buffers byte for byte.

    Some inferred leaves have coincident backfaces: cancelling vertex sums use
    their largest incident face rather than producing a zero/NaN normal.
    """
    doc, original = load_glb(source)
    binary = bytearray(original)
    added = 0
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            if 'NORMAL' in primitive['attributes']:
                continue
            points = read_accessor(doc, binary, primitive['attributes']['POSITION'])
            faces = read_accessor(doc, binary, primitive['indices']).reshape(-1, 3).astype(int)
            cross = np.cross(points[faces[:, 1]]-points[faces[:, 0]], points[faces[:, 2]]-points[faces[:, 0]])
            normals = np.zeros_like(points)
            for corner in range(3):
                np.add.at(normals, faces[:, corner], cross)
            lengths = np.linalg.norm(normals, axis=1)
            missing = lengths < 1e-10
            for face_index in np.argsort(np.linalg.norm(cross, axis=1))[::-1]:
                if np.linalg.norm(cross[face_index]) < 1e-10:
                    continue
                for vertex in faces[face_index]:
                    if missing[vertex]:
                        normals[vertex] = cross[face_index]
                        missing[vertex] = False
            normals[missing] = [0, 1, 0]
            normals /= np.linalg.norm(normals, axis=1)[:, None]
            assert np.isfinite(normals).all()
            binary.extend(b'\0' * ((-len(binary)) % 4))
            offset = len(binary)
            payload = normals.astype('<f4').tobytes()
            binary.extend(payload)
            doc['bufferViews'].append(dict(buffer=0, byteOffset=offset, byteLength=len(payload), target=34962))
            doc['accessors'].append(dict(bufferView=len(doc['bufferViews'])-1, componentType=5126, count=len(points), type='VEC3'))
            primitive['attributes']['NORMAL'] = len(doc['accessors'])-1
            added += 1
    if not added:
        return source.read_bytes(), 0
    doc['buffers'][0]['byteLength'] = len(binary)
    doc['asset']['generator'] = doc['asset'].get('generator', '') + '; finite smooth normals appended locally'
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * ((-len(encoded)) % 4)
    binary.extend(b'\0' * ((-len(binary)) % 4))
    data = struct.pack('<III', 0x46546C67, 2, 28+len(encoded)+len(binary))
    data += struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
    data += struct.pack('<II', len(binary), 0x004E4942) + binary
    return data, added


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT/'build/hunyuan_free')
    args = parser.parse_args()
    backup = ROOT/'.art_backups/horror_prepare'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    backups = []

    def write(path, content):
        if path.exists() and path.read_bytes() == content:
            return
        if path.exists():
            target = backup/path.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
            backups.append(dict(path=path.relative_to(ROOT).as_posix(), backup=str(target),
                                sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)

    metadata = {}
    triangles = 0
    for budget, names in GROUPS.items():
        for name in names:
            source = args.source/name
            provenance = json.loads((source/'hunyuan_provenance.json').read_text())
            assert provenance['status'] == 'success', name
            for kind in ['raw', 'reduced']:
                path = source/f'{name}_{kind}.glb'
                assert hashlib.sha256(path.read_bytes()).hexdigest() == provenance[kind+'_sha256'], path
            mesh = trimesh.load(source/f'{name}_reduced.glb', force='mesh')
            assert 0 < len(mesh.faces) <= budget and np.isfinite(mesh.vertices).all(), name
            triangles += len(mesh.faces)
            for filename in [f'{name}_raw.glb', 'LICENSE-HUNYUAN.txt']:
                write(ROOT/'assets/models/ready'/name/filename, (source/filename).read_bytes())
            finished, added = with_normals(source/f'{name}_reduced.glb')
            write(ROOT/'assets/models/ready'/name/f'{name}_reduced.glb', finished)
            provenance['source_reduced_sha256'] = provenance['reduced_sha256']
            provenance['reduced_sha256'] = hashlib.sha256(finished).hexdigest()
            provenance['integration'] = dict(normals_added_primitives=added, geometry_unchanged=True,
                                             tool='tools/art/prepare_horror_models.py',
                                             material_concept_sha256=hashlib.sha256((ROOT/f'assets/concepts/horror/{name}.png').read_bytes()).hexdigest(),
                                             source_directory=source.relative_to(ROOT).as_posix() if source.is_relative_to(ROOT) else str(source))
            write(ROOT/'assets/models/ready'/name/'hunyuan_provenance.json', (json.dumps(provenance, indent=2)+'\n').encode())
            vertices = mesh.vertices
            center = mesh.bounds.mean(axis=0)
            _, vectors = np.linalg.eigh(np.cov(vertices.T))
            axis = vectors[:, -1]
            if axis[np.argmax(np.abs(axis))] < 0:
                axis = -axis
            if name == 'fishing_rod' and axis[1] < 0:
                axis = -axis
            projections = (vertices-center)@axis
            image = np.asarray(Image.open(ROOT/f'assets/concepts/horror/{name}.png').convert('RGB'))
            mask = (np.ptp(image.astype(float), axis=2) > 18) | (image.max(axis=2) < 105)
            ys, xs = np.where(mask)
            low = np.array([xs.min(), ys.min()])
            high = np.array([xs.max()+1, ys.max()+1])
            dimensions = np.array([image.shape[1], image.shape[0]])
            metadata[name] = dict(size=mesh.extents.tolist(), axis=axis.tolist(),
                                  anchor=(center+axis*projections.min()).tolist(), length=float(np.ptp(projections)),
                                  crop=np.r_[low/dimensions, (high-low)/dimensions].tolist(),
                                  fallback=(np.median(image[mask], axis=0)/255).tolist())
    destination = ROOT/'assets/models/ready'
    write(destination/'horror_models.json', (json.dumps(metadata, indent=2)+'\n').encode())
    lines = ['extends RefCounted', '# Generated geometry / material calibration; source: horror_models.json.', 'const DATA := {']
    lines += ['\t'+json.dumps(name)+': '+json.dumps(spec, separators=(',', ':'))+',' for name, spec in metadata.items()]
    write(destination/'horror_models.gd', ('\n'.join(lines+['}'])+'\n').encode())
    if backups:
        (backup/'manifest.json').write_text(json.dumps(backups, indent=2))
    print(f'Prepared {len(metadata)} props; {triangles:,} triangles; {len(backups)} changed files backed up.')


if __name__ == '__main__':
    main()
