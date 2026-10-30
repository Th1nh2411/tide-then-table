"""Add a "Faint" clip to Rin (assets/models/ready/rin/rin_pilot.glb).

Built from pilot2's "Death" (a shot-and-fly-back fall) so the end pose is the
same lying pose, but the way down is a faint: knees buckle with the arms still
hanging, then he tips over backwards with no leap (hips stay over the spot,
the legs slide out forward) and stays down.
Re-runnable: replaces an existing Faint clip. Needs numpy (use /usr/bin/python3).
"""
import sys
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/art'))
from glb_common import load_glb, read_accessor, write_document, backup  # noqa: E402

GLB = ROOT / 'assets/models/ready/rin/rin_pilot.glb'
FPS = 30
BUCKLE_AT = 0.20      # Death time used as the knees-buckled pose
BUCKLE_END = 0.85     # Faint time when the buckle is reached
DOWN_END = 1.95       # Faint time when he lies flat
LENGTH = 2.3          # holds the lying pose after DOWN_END
ARM_WORDS = ('Shoulder', 'UpperArm', 'LowerArm', 'Wrist', 'Thumb', 'Index', 'Middle', 'Ring', 'Pinky')


def slerp(a, b, t):
    a = np.asarray(a, float); b = np.asarray(b, float)
    d = float(np.dot(a, b))
    if d < 0:
        b = -b; d = -d
    if d > 0.9995:
        r = a + (b - a) * t
        return r / np.linalg.norm(r)
    th = np.arccos(d)
    return (np.sin((1 - t) * th) * a + np.sin(t * th) * b) / np.sin(th)


def smooth(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def fall(t):
    # Slow start, gravity-like finish, tiny ease at the very end.
    t = min(max(t, 0.0), 1.0)
    return smooth(t) * 0.35 + t * t * 0.65


d, raw = load_glb(GLB)
binary = bytearray(raw[:d['buffers'][0]['byteLength']])


def clip(name):
    a = next(a for a in d['animations'] if a['name'] == name)
    tr = {}
    for ch in a['channels']:
        s = a['samplers'][ch['sampler']]
        tr[(ch['target']['node'], ch['target']['path'])] = (
            read_accessor(d, raw, s['input']).ravel(), read_accessor(d, raw, s['output']))
    return tr, max(float(v[0][-1]) for v in tr.values())


def value(tr, node, path, t, default):
    if (node, path) not in tr:
        return np.array(default, dtype=float)
    ts, vs = tr[(node, path)]
    if len(ts) == 1:
        return np.array(vs[0], float)
    i = min(max(np.searchsorted(ts, t, side='right') - 1, 0), len(ts) - 2)
    f = min(max((t - ts[i]) / (ts[i + 1] - ts[i]) if ts[i + 1] > ts[i] else 0, 0), 1)
    return slerp(vs[i], vs[i + 1], f) if path == 'rotation' else vs[i] * (1 - f) + vs[i + 1] * f


death, death_len = clip('CharacterArmature|Death')
idle, _ = clip('CharacterArmature|Idle')
targets = sorted({key for key in death} | {(n, p) for (n, p) in idle if p == 'rotation'})


def pose(key, t):
    node, path = key
    n = d['nodes'][node]
    default = n.get(path, [0, 0, 0, 1] if path == 'rotation' else [0, 0, 0])
    stand = value(idle, node, path, 0.0, default)
    end = value(death, node, path, death_len, default)
    is_arm = any(w in n.get('name', '') for w in ARM_WORDS)
    buckle = stand if is_arm else value(death, node, path, BUCKLE_AT, default)
    if path == 'translation' and n.get('name') == 'Body':
        # Death flies 0.7 m back; keep the hips over the spot so the legs slide
        # out forward instead and he lies centred where he stood.
        buckle = buckle.copy(); end = end.copy()
        buckle[2] = stand[2]; end[2] = stand[2]
    mix = slerp if path == 'rotation' else (lambda a, b, f: a * (1 - f) + b * f)
    if t <= BUCKLE_END:
        return mix(stand, buckle, smooth(t / BUCKLE_END))
    f = (t - BUCKLE_END) / (DOWN_END - BUCKLE_END)
    # Arms trail the body a little, so they flop down last.
    return mix(buckle, end, smooth(f * 0.9) if is_arm else fall(f))


def append(data, kind):
    a = np.asarray(data, dtype='<f4')
    while len(binary) % 4:
        binary.append(0)
    off = len(binary)
    binary.extend(a.tobytes())
    d['bufferViews'].append({'buffer': 0, 'byteOffset': off, 'byteLength': a.nbytes})
    acc = {'bufferView': len(d['bufferViews']) - 1, 'componentType': 5126, 'count': len(a), 'type': kind}
    if kind == 'SCALAR':
        acc['min'] = [float(a.min())]
        acc['max'] = [float(a.max())]
    d['accessors'].append(acc)
    return len(d['accessors']) - 1


times = np.arange(int(round(LENGTH * FPS)) + 1) / FPS
tin = append(times, 'SCALAR')
samplers, channels = [], []
for key in targets:
    out = np.array([pose(key, t) for t in times])
    if key[1] == 'rotation':
        for k in range(1, len(out)):
            if np.dot(out[k], out[k - 1]) < 0:
                out[k] = -out[k]
    samplers.append({'input': tin, 'output': append(out, 'VEC4' if key[1] == 'rotation' else 'VEC3'),
                     'interpolation': 'LINEAR'})
    channels.append({'sampler': len(samplers) - 1, 'target': {'node': key[0], 'path': key[1]}})
d['animations'] = [a for a in d['animations'] if a['name'] != 'Faint']
d['animations'].append({'name': 'Faint', 'samplers': samplers, 'channels': channels})
backup(GLB)
write_document(GLB, d, binary)
print('Faint: %d channels, %.2f s' % (len(channels), LENGTH))
