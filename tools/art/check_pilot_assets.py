"""Read-only checks for the archived studies and final Hunyuan art pilots.

No GUI/import or asset mutations. Requires NumPy. Source palette dictionaries are read with ast.literal_eval,
never executed. A changed file snapshot is reported so active agent writes are visible.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import ast
import hashlib
import json
import struct
import sys
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE = ROOT/'.art_backups/art_studies_20261028_143130'
SNAPSHOTS = {}


def snapshot(path):
    raw = path.read_bytes()
    stamp = (path.stat().st_mtime_ns, len(raw), hashlib.sha256(raw).hexdigest())
    SNAPSHOTS[path] = stamp
    return raw


def read_json(path):
    return json.loads(snapshot(path))


def checksum(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''):
            h.update(block)
    return h.hexdigest()


def check_archive():
    manifest = read_json(ARCHIVE/'manifest.json')
    files = manifest['files']
    assert len(files) == 404, f'Expected 404 archived files, found {len(files)}'
    assert len({f['original'] for f in files}) == len(files)
    assert (ROOT/'.art_backups/.gdignore').is_file(), 'Archive must be excluded from Godot'
    for entry in files:
        path = (ARCHIVE/entry['archive']).resolve()
        assert path.is_relative_to(ARCHIVE.resolve()), 'Archive path escapes root'
        assert path.is_file(), f'Missing archived file {entry["archive"]}'
        assert path.stat().st_size == entry['bytes'], f'Archive size mismatch {entry["archive"]}'
        assert checksum(path) == entry['sha256'], f'Archive SHA mismatch {entry["archive"]}'
    print('PASS archive: 404/404 files present, sizes/SHA-256 intact, Godot ignore present')


def check_references():
    # Search actual old identifiers, allowing explicitly historical provenance only.
    old = ('rin_portrait_study', 'rin_painted', 'rin_lowpoly', 'rin_image_guided', 'tools/blender/')
    problems = []
    suffixes = {'.gd', '.tscn', '.py', '.json', '.md', '.txt', '.nd'}
    ignored = {'.git', '.godot', '.art_backups', 'build', 'tmp', '__pycache__'}
    for path in ROOT.rglob('*'):
        rel = path.relative_to(ROOT)
        if any(part in ignored for part in rel.parts) or str(rel).startswith('docs/archive/'):
            continue
        if path == Path(__file__).resolve() or path.suffix not in suffixes or not path.is_file():
            continue
        try:
            lines = path.read_text().splitlines()
        except UnicodeError:
            continue
        for number, line in enumerate(lines, 1):
            if any(value in line for value in old):
                if any(key in line for key in ('input_source_historical', 'archived_study', '.art_backups/')):
                    continue
                problems.append(f'{rel}:{number}: {line.strip()}')
    assert not problems, 'References to archived studies remain:\n'+'\n'.join(problems)
    print('PASS references: no active code/docs paths to archived studies (historical provenance retained)')


class GLB:
    def __init__(self, path):
        self.path = path
        raw = snapshot(path)
        assert len(raw) >= 28
        magic, version, length = struct.unpack_from('<III', raw)
        assert magic == 0x46546C67 and version == 2 and length == len(raw), 'Invalid GLB header'
        size, kind = struct.unpack_from('<II', raw, 12)
        assert kind == 0x4E4F534A and size % 4 == 0
        self.doc = json.loads(raw[20:20+size])
        bin_start = 20+size
        bin_size, kind = struct.unpack_from('<II', raw, bin_start)
        assert kind == 0x004E4942 and bin_start+8+bin_size == len(raw)
        assert self.doc['asset']['version'] == '2.0' and len(self.doc['buffers']) == 1
        declared = self.doc['buffers'][0]['byteLength']
        assert declared <= bin_size <= declared+3
        self.binary = raw[bin_start+8:bin_start+8+declared]
        for view in self.doc['bufferViews']:
            assert view.get('buffer', 0) == 0
            assert 0 <= view.get('byteOffset', 0) <= declared
            assert view.get('byteOffset', 0)+view['byteLength'] <= declared, 'Buffer view exceeds binary chunk'
        for i in range(len(self.doc['accessors'])):
            self.read(i)

    def read(self, index):
        a = self.doc['accessors'][index]
        assert 'sparse' not in a, 'Sparse accessor not supported by this checker'
        assert a['count'] > 0
        v = self.doc['bufferViews'][a['bufferView']]
        dtype = np.dtype({5120: 'i1', 5121: 'u1', 5122: '<i2', 5123: '<u2', 5125: '<u4', 5126: '<f4'}[a['componentType']])
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT2': 4, 'MAT3': 9, 'MAT4': 16}[a['type']]
        relative = a.get('byteOffset', 0)
        stride = v.get('byteStride', width*dtype.itemsize)
        assert stride >= width*dtype.itemsize and stride % dtype.itemsize == 0
        assert relative+(a['count']-1)*stride+width*dtype.itemsize <= v['byteLength'], 'Accessor exceeds view'
        offset = v.get('byteOffset', 0)+relative
        assert offset % dtype.itemsize == 0
        array = np.ndarray((a['count'], width), dtype=dtype, buffer=self.binary,
                           offset=offset, strides=(stride, dtype.itemsize))
        assert np.isfinite(array).all(), 'Non-finite accessor data'
        for key, actual in [('min', array.min(axis=0)), ('max', array.max(axis=0))]:
            if key in a:
                assert isinstance(a[key], list) and len(a[key]) == width
                assert np.allclose(actual, a[key], atol=2e-5), 'Accessor bounds differ from data'
        return array


def literal_assignment(path, name):
    for node in ast.parse(path.read_text()).body:
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == name for t in node.targets):
            return ast.literal_eval(node.value)
    raise ValueError('Missing literal '+name+' in '+str(path))


def palette_hex(factor):
    rgb = np.asarray(factor[:3], dtype=float)
    srgb = np.where(rgb <= .0031308, rgb*12.92, 1.055*rgb**(1/2.4)-.055)
    return ''.join(f'{int(round(float(v)*255)):02x}' for v in np.clip(srgb, 0, 1))


def check_asset(name, relative, meta_name, expected_triangles, expected_size, min_y, builder, palette_name):
    path = ROOT/relative
    meta = read_json(path.parent/meta_name)
    glb = GLB(path)
    d = glb.doc
    assert len(d['meshes']) == 1
    triangles, positions = 0, []
    joint_count = len(d['skins'][0]['joints']) if d.get('skins') else 0
    for mesh in d['meshes']:
        for p in mesh['primitives']:
            assert p.get('mode', 4) == 4
            attrs = p['attributes']
            points = glb.read(attrs['POSITION']); positions.append(points)
            assert points.shape[1] == 3
            normals = glb.read(attrs['NORMAL'])
            assert normals.shape == points.shape
            lengths = np.linalg.norm(normals, axis=1)
            assert np.allclose(lengths, 1, atol=.003), f'Non-unit normals ({lengths.min()}–{lengths.max()})'
            indices = glb.read(p['indices']).reshape(-1) if 'indices' in p else np.arange(len(points))
            assert len(indices) % 3 == 0 and indices.min() >= 0 and indices.max() < len(points)
            triangles += len(indices)//3
            assert p['material'] < len(d['materials'])
            if joint_count:
                joints = glb.read(attrs['JOINTS_0']); weights = glb.read(attrs['WEIGHTS_0'])
                assert joints.shape == weights.shape == (len(points), 4)
                assert joints.max() < joint_count and joints.min() >= 0
                assert weights.min() >= 0 and weights.max() <= 1
                assert np.allclose(weights.sum(axis=1), 1, atol=.002), 'Skin weights are not normalized'
    assert triangles == expected_triangles, (triangles, expected_triangles)
    all_points = np.concatenate(positions)
    bounds_min, bounds_max = all_points.min(axis=0), all_points.max(axis=0)
    size = bounds_max-bounds_min
    if expected_size is not None:
        assert np.allclose(size, expected_size, atol=.005), f'Dimensions {size} differ from {expected_size}'
    else:
        assert abs(float(size[1])-1.84) < .005
    assert abs(float(bounds_min[1])-min_y) < .005, f'Wrong floor origin: {bounds_min[1]}'
    palette = literal_assignment(ROOT/builder, palette_name)
    allowed = {v.lower() for v in palette.values()} if palette_name == 'PALETTE' else {v[1].lower() for v in palette[name]['colors']}
    used = set()
    for material in d['materials']:
        pbr = material['pbrMetallicRoughness']; factor = pbr['baseColorFactor']
        assert len(factor) == 4 and all(0 <= c <= 1 for c in factor)
        assert factor[3] == 1 and 'baseColorTexture' not in pbr
        assert 0 <= pbr.get('roughnessFactor', 1) <= 1 and 0 <= pbr.get('metallicFactor', 1) <= 1
        used.add(palette_hex(factor))
    assert used <= allowed, f'Palette mismatch: {used-allowed}'
    if joint_count:
        assert joint_count == 20
        for skin in d['skins']:
            assert len(set(skin['joints'])) == len(skin['joints'])
            assert max(skin['joints']) < len(d['nodes'])
            matrices = glb.read(skin['inverseBindMatrices']).reshape(-1, 4, 4)
            assert len(matrices) == len(skin['joints']) and np.all(np.abs(np.linalg.det(matrices)) > 1e-6)
        assert {a['name'] for a in d['animations']} == {'Idle', 'Walk', 'Carry', 'Raised'}
        for animation in d['animations']:
            for sampler in animation['samplers']:
                times = glb.read(sampler['input']).reshape(-1)
                assert np.all(np.diff(times) >= 0) and times[-1] > times[0]
                values = glb.read(sampler['output'])
                assert len(values) == len(times)
            for channel in animation['channels']:
                if channel['target']['path'] == 'rotation':
                    q = glb.read(animation['samplers'][channel['sampler']]['output'])
                    assert np.allclose(np.linalg.norm(q, axis=1), 1, atol=.003)
    else:
        assert not d.get('animations')
    digest = SNAPSHOTS[path][2]
    assert digest == meta['output_sha256'], 'Output checksum differs from provenance (possible concurrent rebuild)'
    source_value = meta.get('source_mesh', meta.get('geometry_source', meta.get('source')))
    source = ROOT/source_value if '/' in source_value else path.parent/source_value
    assert source.is_file() and checksum(source) == meta['source_sha256'], 'Geometry lineage checksum mismatch'
    # Verify the inference chain too, not only the final derivative's checksum.
    if name in ('stool', 'table', 'thuyen_thung'):
        inference = read_json(path.parent/'hunyuan_provenance.json')
        assert inference['status'] == 'success' and inference['provider'] in ('tencent/Hunyuan3D-2.1', 'tencent/Hunyuan3D-2mini')
        assert inference['reduction']['target_face_num'] == expected_triangles
        for kind in ['raw', 'reduced']:
            origin = path.parent/inference[kind]
            assert origin.is_file() and checksum(origin) == inference[kind+'_sha256'], f'{kind} inference checksum mismatch'
        image = Path(inference['input'])
        if not image.is_absolute():
            image = ROOT/image
        assert image.is_file() and checksum(image) == inference['input_sha256'], 'Inference input image checksum mismatch'
    else:
        lineage = read_json(source.parent/'provenance.json')
        assert lineage['provider'] == 'Official Tencent Hunyuan3D-2.1 Hugging Face Space'
        for filename, expected in lineage['sha256'].items():
            origin = source.parent/filename
            assert origin.is_file() and checksum(origin) == expected, f'Rin inference lineage checksum mismatch: {filename}'
    for key, filename in [('input_sha256', 'input.png'), ('prompt_sha256', 'prompt.txt')]:
        if key in meta:
            assert checksum(path.parent/filename) == meta[key]
    print(f'PASS {name}: {triangles} triangles, {len(d["materials"])} palette materials, {joint_count} bones, dimensions {size.round(5).tolist()}, minY={float(bounds_min[1]):.5f}; SHA {digest[:16]}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--skip-archive', action='store_true')
    args = parser.parse_args()
    jobs = [('references', check_references)]
    if not args.skip_archive:
        jobs.insert(0, ('archive', check_archive))
    jobs += [
        ('stool', lambda: check_asset('stool', 'assets/models/pilots/stool/stool.glb', 'provenance.json', 600, (.55, .52, .55), 0, 'tools/art/build_furniture_pilot.py', 'SPECS')),
        ('table', lambda: check_asset('table', 'assets/models/pilots/table/table.glb', 'provenance.json', 1200, (1.5, .86, 1.2), 0, 'tools/art/build_furniture_pilot.py', 'SPECS')),
        ('thuyen_thung', lambda: check_asset('thuyen_thung', 'assets/models/pilots/thuyen_thung/thuyen_thung.glb', 'prepared_provenance.json', 2400, (2.4, .535, 2.3960044), .025, 'tools/art/build_boat_pilot.py', 'PALETTE')),
        ('rin', lambda: check_asset('rin', 'assets/models/pilots/rin/rin_pilot.glb', 'provenance.json', 3000, None, 0, 'tools/art/build_rin_pilot.py', 'PALETTE')),
    ]
    failures = 0
    print('QA snapshot UTC:', datetime.now(timezone.utc).isoformat())
    for label, job in jobs:
        try:
            job()
        except Exception as error:
            failures += 1; print('FAIL', label+':', error)
    for path, previous in SNAPSHOTS.items():
        current = (path.stat().st_mtime_ns, path.stat().st_size, checksum(path))
        if current != previous:
            print('WARN concurrent file change:', path.relative_to(ROOT), 'UTC', datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat())
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
