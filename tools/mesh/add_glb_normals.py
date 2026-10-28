"""Add smooth vertex normals to a single-buffer triangle GLB without changing geometry.
Usage: python3 tools/mesh/add_glb_normals.py input.glb output.glb
The input is preserved. Existing output is backed up before replacement.
"""
from pathlib import Path
from datetime import datetime
import json
import struct
import shutil
import sys
import numpy as np

source, target = map(Path, sys.argv[1:3])
assert source.resolve() != target.resolve(), 'Use a separate output file'
raw = source.read_bytes()
magic, version, total = struct.unpack_from('<III', raw)
assert magic == 0x46546C67 and version == 2 and total == len(raw)
json_size, _ = struct.unpack_from('<II', raw, 12)
doc = json.loads(raw[20:20+json_size])
bin_offset = 20+json_size
bin_size, bin_type = struct.unpack_from('<II', raw, bin_offset)
assert bin_type == 0x004E4942 and len(doc['buffers']) == 1
binary = bytearray(raw[bin_offset+8:bin_offset+8+doc['buffers'][0]['byteLength']])

def read_accessor(index):
    a = doc['accessors'][index]
    v = doc['bufferViews'][a['bufferView']]
    assert 'sparse' not in a and 'byteStride' not in v
    count = {'SCALAR': 1, 'VEC3': 3}[a['type']]
    dtype = {5126: '<f4', 5125: '<u4', 5123: '<u2'}[a['componentType']]
    offset = v.get('byteOffset', 0)+a.get('byteOffset', 0)
    return np.frombuffer(binary, dtype=dtype, count=a['count']*count, offset=offset).copy().reshape(a['count'], count)

added = 0
for mesh in doc['meshes']:
    for p in mesh['primitives']:
        if 'NORMAL' in p['attributes']:
            continue
        assert p.get('mode', 4) == 4
        points = read_accessor(p['attributes']['POSITION'])
        indices = read_accessor(p['indices']).reshape(-1, 3) if 'indices' in p else np.arange(len(points)).reshape(-1, 3)
        normals = np.zeros_like(points)
        cross = np.cross(points[indices[:, 1]]-points[indices[:, 0]], points[indices[:, 2]]-points[indices[:, 0]])
        for corner in range(3):
            np.add.at(normals, indices[:, corner], cross)
        lengths = np.linalg.norm(normals, axis=1, keepdims=True)
        assert np.all(lengths > 1e-12), 'Unreferenced or wholly degenerate vertex'
        normals /= lengths
        while len(binary) % 4:
            binary.append(0)
        offset = len(binary)
        data = normals.astype('<f4').tobytes()
        binary.extend(data)
        doc['bufferViews'].append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(data), 'target': 34962})
        doc['accessors'].append({'bufferView': len(doc['bufferViews'])-1, 'componentType': 5126, 'count': len(normals), 'type': 'VEC3'})
        p['attributes']['NORMAL'] = len(doc['accessors'])-1
        added += 1

doc['buffers'][0]['byteLength'] = len(binary)
doc['asset']['generator'] = doc['asset'].get('generator', '')+'; added smooth normals with NumPy'
encoded = json.dumps(doc, separators=(',', ':')).encode()
encoded += b' '*((-len(encoded)) % 4)
binary.extend(b'\0'*((-len(binary)) % 4))
length = 12+8+len(encoded)+8+len(binary)
result = struct.pack('<III', magic, version, length)
result += struct.pack('<II', len(encoded), 0x4E4F534A)+encoded
result += struct.pack('<II', len(binary), 0x004E4942)+binary
if target.exists():
    backup = target.parent/'backups'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')/target.name
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(target, backup)
target.write_bytes(result)
print('PASS added normals:', added, 'primitive(s), preserved input:', source)
