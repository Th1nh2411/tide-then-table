"""Normalize and flat-color actual Hunyuan furniture outputs. Never generates shape.

Inputs: assets/models/pilots/{table,stool}/{name}_reduced.glb, produced by hunyuan_job.py.
Outputs: canonical metre-scale {name}.glb with flat normals and palette materials.
Missing inference results are reported, never replaced by procedural furniture.
"""
from pathlib import Path
from datetime import datetime
import hashlib
import json
import math
import shutil
import struct
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SPECS = {
    'table': {'size': (1.5, .86, 1.2), 'colors': [('Top', 'c7cfcc', .25), ('Legs', '577277', .15)]},
    'stool': {'size': (.55, .52, .55), 'colors': [('Plastic', '3c5e8b', 0)]},
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def linear(value):
    return value/12.92 if value <= .04045 else ((value+.055)/1.055)**2.4


def build(name, spec):
    directory = ROOT/'assets/models/pilots'/name
    source = directory/(name+'_reduced.glb')
    if not source.exists():
        print('NOT BUILT', name, ': no Hunyuan output; see hunyuan_provenance.json')
        return
    raw = source.read_bytes()
    magic, version, length = struct.unpack_from('<III', raw)
    assert magic == 0x46546c67 and version == 2 and length == len(raw)
    json_length, _ = struct.unpack_from('<II', raw, 12)
    doc = json.loads(raw[20:20+json_length])
    bin_offset = 20+json_length
    _, kind = struct.unpack_from('<II', raw, bin_offset)
    assert kind == 0x004e4942 and len(doc['meshes']) == 1
    data = raw[bin_offset+8:]
    assert all('matrix' not in n and 'translation' not in n and 'scale' not in n and 'rotation' not in n for n in doc['nodes']), 'Input needs world transform baking first'

    def read(index):
        a = doc['accessors'][index]; v = doc['bufferViews'][a['bufferView']]
        assert 'sparse' not in a and 'byteStride' not in v
        count = {'SCALAR': 1, 'VEC3': 3}[a['type']]
        dtype = {5126: '<f4', 5123: '<u2', 5125: '<u4'}[a['componentType']]
        return np.frombuffer(data, dtype=dtype, offset=v.get('byteOffset', 0)+a.get('byteOffset', 0), count=a['count']*count).reshape(a['count'], count).copy()

    assert len(doc['meshes'][0]['primitives']) == 1
    primitive = doc['meshes'][0]['primitives'][0]
    points = read(primitive['attributes']['POSITION']).astype(np.float64)
    indices = read(primitive['indices']).reshape(-1, 3)
    # Align the rectangular footprint before scaling it. The inferred camera yaw
    # is not assumed to match the game's table/stool axes.
    center = (points.min(axis=0)+points.max(axis=0))*.5
    points -= center
    best = None
    for degrees in np.arange(0, 90, .25):
        theta = math.radians(degrees)
        rotation = np.array([[math.cos(theta), 0, math.sin(theta)], [0, 1, 0], [-math.sin(theta), 0, math.cos(theta)]])
        candidate = points@rotation.T
        size = np.ptp(candidate, axis=0)
        area = size[0]*size[2]
        if best is None or area < best[0]:
            best = (area, theta, candidate)
    _, theta, points = best
    # A dining table's long direction is X. Stools are square so either axis works.
    if name == 'table' and np.ptp(points[:, 0]) < np.ptp(points[:, 2]):
        points = points[:, [2, 1, 0]]*np.array([1, 1, -1])
        theta += math.pi/2
    low, high = points.min(axis=0), points.max(axis=0)
    size = high-low
    scale = np.asarray(spec['size'])/size
    points -= np.array([(low[0]+high[0])*.5, low[1], (low[2]+high[2])*.5])
    points *= scale
    assert np.all(np.isfinite(points))
    assert np.allclose(np.ptp(points, axis=0), spec['size'], atol=1e-6)
    assert abs(points[:, 1].min()) < 1e-6

    binary = bytearray(); views = []; accessors = []

    def accessor(array, component, kind):
        types = {5126: '<f4', 5125: '<u4'}
        array = np.asarray(array, dtype=types[component])
        while len(binary) % 4: binary.append(0)
        offset = len(binary); payload = array.tobytes(); binary.extend(payload)
        views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(payload)})
        a = {'bufferView': len(views)-1, 'componentType': component, 'count': len(array), 'type': kind}
        if kind == 'VEC3':
            a['min'] = array.min(axis=0).tolist(); a['max'] = array.max(axis=0).tolist()
        accessors.append(a)
        return len(accessors)-1

    material_data = []
    for title, color, metal in spec['colors']:
        rgb = [linear(int(color[k:k+2], 16)/255) for k in (0, 2, 4)]
        material_data.append({'name': name+'_'+title, 'doubleSided': True,
                              'pbrMetallicRoughness': {'baseColorFactor': rgb+[1], 'metallicFactor': metal, 'roughnessFactor': .72 if name == 'table' else .9}})
    grouped = [[] for _ in material_data]
    for tri in indices:
        positions = points[tri]
        mat_index = 0 if name == 'stool' or positions[:, 1].mean() > .74 else 1
        grouped[mat_index].append(positions)
    primitives = []
    for mat_index, triangles in enumerate(grouped):
        if not triangles: continue
        tris = np.asarray(triangles)
        normal = np.cross(tris[:, 1]-tris[:, 0], tris[:, 2]-tris[:, 0])
        normal /= np.maximum(np.linalg.norm(normal, axis=1, keepdims=True), 1e-12)
        position = tris.reshape(-1, 3)
        normals = np.repeat(normal, 3, axis=0)
        primitives.append({'attributes': {'POSITION': accessor(position, 5126, 'VEC3'), 'NORMAL': accessor(normals, 5126, 'VEC3')},
                           'indices': accessor(np.arange(len(position)), 5125, 'SCALAR'), 'material': mat_index})
    output = {'asset': {'version': '2.0', 'generator': 'Actual Hunyuan shape; normalized/flat-colored with NumPy'},
              'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': [{'name': name.title()+'Pilot', 'mesh': 0}],
              'meshes': [{'name': name.title()+'Pilot', 'primitives': primitives}], 'materials': material_data,
              'buffers': [{'byteLength': len(binary)}], 'bufferViews': views, 'accessors': accessors}
    encoded = json.dumps(output, separators=(',', ':')).encode(); encoded += b' '*((-len(encoded)) % 4)
    binary.extend(b'\0'*((-len(binary)) % 4))
    result = struct.pack('<III', 0x46546c67, 2, 12+8+len(encoded)+8+len(binary))
    result += struct.pack('<II', len(encoded), 0x4e4f534a)+encoded
    result += struct.pack('<II', len(binary), 0x004e4942)+binary
    target = directory/(name+'.glb')
    if target.exists():
        backup = ROOT/'build/art_pilots/backups'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')/name/target.name
        backup.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(target, backup)
    target.write_bytes(result)
    provenance = {'geometry_source': source.name, 'source_sha256': digest(source), 'hunyuan_provenance': 'hunyuan_provenance.json',
                  'image_tool': 'built-in image_gen.imagegen', 'image': 'input.png', 'prompt': 'prompt.txt',
                  'changes': ['normalized inferred yaw and metre dimensions', 'bottom-centred origin', 'flat per-triangle normals', 'solid-color lit PBR material'],
                  'yaw_radians': theta, 'axis_scale': scale.tolist(), 'dimensions_xyz_m': spec['size'],
                  'triangles': len(indices), 'mesh_count': 1, 'surfaces': len(primitives), 'no_shape_replacement': True,
                  'output': target.name, 'output_sha256': digest(target)}
    (directory/'provenance.json').write_text(json.dumps(provenance, indent=2)+'\n')
    print('FURNITURE_OK', name, len(indices), 'triangles', tuple(spec['size']))


if __name__ == '__main__':
    for name, spec in SPECS.items():
        build(name, spec)
