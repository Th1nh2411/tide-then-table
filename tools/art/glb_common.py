"""Small GLB utilities for finishing inferred assets without a DCC dependency."""
from pathlib import Path
from datetime import datetime
import hashlib
import json
import shutil
import struct
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
WIDTH = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
DTYPE = {5120: '<i1', 5121: '<u1', 5122: '<i2', 5123: '<u2', 5125: '<u4', 5126: '<f4'}


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def backup(path):
    path = Path(path)
    if path.exists():
        relative = path.resolve().relative_to(ROOT)
        target = ROOT/'build/batch_integration/backups'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')/relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        return target


def load_glb(path):
    raw = Path(path).read_bytes()
    magic, version, length = struct.unpack_from('<III', raw)
    assert magic == 0x46546c67 and version == 2 and length == len(raw), path
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4e4f534a
    document = json.loads(raw[20:20+size])
    offset = 20+size
    binary_size, kind = struct.unpack_from('<II', raw, offset)
    assert kind == 0x004e4942 and len(document['buffers']) == 1
    return document, raw[offset+8:offset+8+binary_size]


def read_accessor(document, binary, index):
    a = document['accessors'][index]
    v = document['bufferViews'][a['bufferView']]
    assert 'sparse' not in a
    dtype = np.dtype(DTYPE[a['componentType']])
    width = WIDTH[a['type']]
    offset = v.get('byteOffset', 0)+a.get('byteOffset', 0)
    stride = v.get('byteStride', width*dtype.itemsize)
    return np.ndarray((a['count'], width), dtype=dtype, buffer=binary, offset=offset,
                      strides=(stride, dtype.itemsize)).copy()


def _matrix(node):
    if 'matrix' in node:
        return np.array(node['matrix'], dtype=float).reshape(4, 4).T
    x, y, z, w = node.get('rotation', [0, 0, 0, 1])
    r = np.array([[1-2*y*y-2*z*z, 2*x*y-2*z*w, 2*x*z+2*y*w],
                  [2*x*y+2*z*w, 1-2*x*x-2*z*z, 2*y*z-2*x*w],
                  [2*x*z-2*y*w, 2*y*z+2*x*w, 1-2*x*x-2*y*y]])
    m = np.eye(4)
    m[:3, :3] = r @ np.diag(node.get('scale', [1, 1, 1]))
    m[:3, 3] = node.get('translation', [0, 0, 0])
    return m


def load_mesh(path):
    """Return combined Y-up positions and triangle indices, baking node transforms."""
    document, binary = load_glb(path)
    assert not document.get('skins'), 'Use a rig-aware processor for skinned input'
    points, triangles = [], []
    count = 0
    def visit(index, parent):
        nonlocal count
        node = document['nodes'][index]
        matrix = parent @ _matrix(node)
        if 'mesh' in node:
            for primitive in document['meshes'][node['mesh']]['primitives']:
                assert primitive.get('mode', 4) == 4
                p = read_accessor(document, binary, primitive['attributes']['POSITION']).astype(float)
                p = (np.c_[p, np.ones(len(p))] @ matrix.T)[:, :3]
                f = read_accessor(document, binary, primitive['indices']).reshape(-1, 3).astype(int) if 'indices' in primitive else np.arange(len(p)).reshape(-1, 3)
                if np.linalg.det(matrix[:3, :3]) < 0:
                    f = f[:, ::-1]
                points.append(p); triangles.append(f+count); count += len(p)
        for child in node.get('children', []):
            visit(child, matrix)
    for root in document['scenes'][document.get('scene', 0)]['nodes']:
        visit(root, np.eye(4))
    assert points
    return np.concatenate(points), np.concatenate(triangles)


def normalize(points, size=None, height=None, bottom=0):
    points = np.array(points, float, copy=True)
    low, high = points.min(0), points.max(0)
    points -= [(low[0]+high[0])/2, low[1], (low[2]+high[2])/2]
    scale = np.asarray(size)/(high-low) if size is not None else height/(high[1]-low[1])
    points *= scale
    points[:, 1] += bottom
    return points


def material(name, color, metallic=0, roughness=.88, double_sided=False):
    rgb = [int(color[k:k+2], 16)/255 for k in (0, 2, 4)]
    rgb = [c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4 for c in rgb]
    return {'name': name, 'doubleSided': double_sided, 'pbrMetallicRoughness':
            {'baseColorFactor': rgb+[1], 'metallicFactor': metallic, 'roughnessFactor': roughness}}


def write_document(path, document, binary):
    binary = bytearray(binary)
    document['buffers'] = [{'byteLength': len(binary)}]
    encoded = json.dumps(document, separators=(',', ':')).encode()
    encoded += b' '*((-len(encoded)) % 4)
    binary.extend(b'\0'*((-len(binary)) % 4))
    payload = struct.pack('<III', 0x46546c67, 2, 28+len(encoded)+len(binary))
    payload += struct.pack('<II', len(encoded), 0x4e4f534a)+encoded
    payload += struct.pack('<II', len(binary), 0x004e4942)+binary
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_bytes() != payload:
        backup(path)
        path.write_bytes(payload)
    return sha256(path)


def write_mesh(path, points, triangles, palette, labels=None):
    """Write flat-shaded triangle geometry with face-level palette materials.

    palette is a dict of name->hex or an already prepared glTF material list.
    Returns metrics; degenerate triangles are removed and reported.
    """
    points = np.asarray(points, float)
    triangles = np.asarray(triangles, int)
    assert np.isfinite(points).all() and triangles.min() >= 0 and triangles.max() < len(points)
    labels = np.asarray(labels if labels is not None else np.zeros(len(triangles)), int)
    materials = [material(name, color) for name, color in palette.items()] if isinstance(palette, dict) else palette
    assert labels.min() >= 0 and labels.max() < len(materials)
    normals = np.cross(points[triangles[:, 1]]-points[triangles[:, 0]], points[triangles[:, 2]]-points[triangles[:, 0]])
    lengths = np.linalg.norm(normals, axis=1)
    valid = lengths > 1e-12
    removed = int((~valid).sum())
    triangles, labels, normals, lengths = triangles[valid], labels[valid], normals[valid], lengths[valid]
    normals /= lengths[:, None]
    binary, views, accessors = bytearray(), [], []
    def acc(array, component, kind, bounds=False):
        array = np.asarray(array, dtype=DTYPE[component])
        binary.extend(b'\0'*((-len(binary)) % 4))
        offset = len(binary); payload = array.tobytes(); binary.extend(payload)
        views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(payload)})
        data = {'bufferView': len(views)-1, 'componentType': component, 'count': len(array), 'type': kind}
        if bounds:
            data.update(min=np.atleast_1d(array.min(0)).tolist(), max=np.atleast_1d(array.max(0)).tolist())
        accessors.append(data)
        return len(accessors)-1
    primitives = []
    for label in sorted(set(labels.tolist())):
        selected = labels == label
        position = points[triangles[selected]].reshape(-1, 3)
        normal = np.repeat(normals[selected], 3, axis=0)
        primitives.append({'attributes': {'POSITION': acc(position, 5126, 'VEC3', True),
                                         'NORMAL': acc(normal, 5126, 'VEC3')},
                           'indices': acc(np.arange(len(position)), 5125, 'SCALAR'), 'material': label})
    name = Path(path).stem
    doc = {'asset': {'version': '2.0', 'generator': 'Hunyuan inferred geometry; flat material finishing with NumPy'},
           'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': [{'name': name, 'mesh': 0}],
           'meshes': [{'name': name, 'primitives': primitives}], 'materials': materials,
           'bufferViews': views, 'accessors': accessors}
    digest = write_document(path, doc, binary)
    return {'output_sha256': digest, 'triangles': len(triangles), 'surfaces': len(primitives),
            'dimensions_m': np.ptp(points, axis=0).tolist(), 'min_y': float(points[:, 1].min()),
            'removed_degenerate_triangles': removed}
