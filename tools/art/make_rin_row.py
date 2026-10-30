"""Add a looping "Row" clip to Rin (assets/models/ready/rin/rin_pilot.glb).

One-sided paddle stroke on his right for the basket boat (thúng), phase 0..1:
catch forward, pull back (0.15..0.6, the part that pushes the boat), lift and
swing forward again. Body/legs come from pilot2 Idle; the chest twists and
leans with the stroke; both arms are solved with two-bone IK so the hands sit
on a straight paddle shaft (game code draws the paddle through the hands).
Model space: Rin faces +z, his left is +x; in the thúng he stands by the
right-hand rim (SeaWorldBuilder3D.build_boat) so the blade clears it. Re-runnable; needs numpy
(use /usr/bin/python3).
"""
import sys
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/art'))
from glb_common import load_glb, read_accessor, write_document, backup  # noqa: E402

GLB = ROOT / 'assets/models/ready/rin/rin_pilot.glb'
FPS = 30
LENGTH = 1.0
GRIP = 0.22           # metres from the top hand down the shaft to the lower hand (arms are short)
PULL = (0.15, 0.6)    # phase window of the power stroke (keep in sync with RowStroke)
# Paddle keys: phase -> (top hand T, blade tip B), model space metres.
KEYS = [
    (0.00, (-0.05, 1.33, 0.30), (-1.15, -0.10, 0.85)),   # catch: reach forward, over the rim
    (0.15, (-0.06, 1.31, 0.26), (-1.20, -0.18, 0.65)),   # blade in
    (0.60, (-0.10, 1.25, -0.02), (-1.20, -0.18, -0.60)),  # pulled back
    (0.78, (-0.08, 1.32, 0.05), (-1.10, 0.35, -0.30)),   # lift out
    (1.00, (-0.05, 1.33, 0.30), (-1.15, -0.10, 0.85)),
]
POLE = {'L': np.array([0.5, -1.0, -0.4]), 'R': np.array([-0.6, -1.0, -0.2])}


def q_mat(q):
    x, y, z, w = q
    return np.array([[1-2*y*y-2*z*z, 2*x*y-2*z*w, 2*x*z+2*y*w], [2*x*y+2*z*w, 1-2*x*x-2*z*z, 2*y*z-2*x*w],
                     [2*x*z-2*y*w, 2*y*z+2*x*w, 1-2*x*x-2*y*y]])


def mat_q(m):
    t = np.trace(m)
    if t > 0:
        s = np.sqrt(t+1)*2; q = [(m[2, 1]-m[1, 2])/s, (m[0, 2]-m[2, 0])/s, (m[1, 0]-m[0, 1])/s, s/4]
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = np.sqrt(1+m[0, 0]-m[1, 1]-m[2, 2])*2; q = [s/4, (m[0, 1]+m[1, 0])/s, (m[0, 2]+m[2, 0])/s, (m[2, 1]-m[1, 2])/s]
    elif m[1, 1] > m[2, 2]:
        s = np.sqrt(1+m[1, 1]-m[0, 0]-m[2, 2])*2; q = [(m[0, 1]+m[1, 0])/s, s/4, (m[1, 2]+m[2, 1])/s, (m[0, 2]-m[2, 0])/s]
    else:
        s = np.sqrt(1+m[2, 2]-m[0, 0]-m[1, 1])*2; q = [(m[0, 2]+m[2, 0])/s, (m[1, 2]+m[2, 1])/s, s/4, (m[1, 0]-m[0, 1])/s]
    q = np.array(q); return q/np.linalg.norm(q)


def unit(v):
    return v / np.linalg.norm(v)


def rot_between(a, b):
    a = unit(a); b = unit(b)
    v = np.cross(a, b); c = float(np.dot(a, b))
    k = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3)+k+k@k/(1+c)


def axis_angle(axis, ang):
    k = unit(np.asarray(axis, float))
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    return np.eye(3)+np.sin(ang)*K+(1-np.cos(ang))*K@K


def slerp(a, b, t):
    d = float(np.dot(a, b))
    if d < 0:
        b = -b; d = -d
    if d > 0.9995:
        r = a+(b-a)*t; return r/np.linalg.norm(r)
    th = np.arccos(d); return (np.sin((1-t)*th)*a+np.sin(t*th)*b)/np.sin(th)


d, raw = load_glb(GLB)
binary = bytearray(raw[:d['buffers'][0]['byteLength']])
nodes = d['nodes']
parents = {c: i for i, n in enumerate(nodes) for c in n.get('children', [])}
by_name = {n.get('name'): i for i, n in enumerate(nodes)}
joints = d['skins'][nodes[by_name['Beach_Head']]['skin']]['joints']
order = []


def walk(i):
    order.append(i)
    for c in nodes[i].get('children', []):
        walk(c)


for r in d['scenes'][d.get('scene', 0)]['nodes']:
    walk(r)
idle_anim = next(a for a in d['animations'] if a['name'] == 'CharacterArmature|Idle')
idle = {}
for ch in idle_anim['channels']:
    s = idle_anim['samplers'][ch['sampler']]
    idle[(ch['target']['node'], ch['target']['path'])] = read_accessor(d, raw, s['output'])[0]


def local(i, rot=None):
    n = nodes[i]
    m = np.eye(4)
    q = rot if rot is not None else idle.get((i, 'rotation'), n.get('rotation', [0, 0, 0, 1]))
    m[:3, :3] = q_mat(q) @ np.diag(n.get('scale', [1, 1, 1]))
    m[:3, 3] = idle.get((i, 'translation'), n.get('translation', [0, 0, 0]))
    return m


def paddle(p):
    for k in range(len(KEYS)-1):
        p0, t0, b0 = KEYS[k]; p1, t1, b1 = KEYS[k+1]
        if p0 <= p <= p1:
            f = (p - p0) / (p1 - p0); f = f*f*(3-2*f)
            return np.array(t0)*(1-f)+np.array(t1)*f, np.array(b0)*(1-f)+np.array(b1)*f
    return np.array(KEYS[0][1]), np.array(KEYS[0][2])


def frame(p):
    top, blade = paddle(p)
    shaft = unit(blade - top)
    hands = {'L': top, 'R': top + shaft*GRIP}
    pull = np.sin(np.pi*min(max((p-PULL[0])/(PULL[1]-PULL[0]), 0), 1)) if PULL[0] <= p <= PULL[1] else 0.0
    twist = 0.20*np.cos(2*np.pi*p)          # chest turns toward the paddle at the catch
    lean = 0.10 + 0.08*np.cos(2*np.pi*p)    # leans in to reach, upright at the exit
    world, rots = {}, {}
    for i in order:
        name = nodes[i].get('name', '')
        pw = world.get(parents.get(i), np.eye(4))
        m = pw @ local(i)
        if name in ('Chest',):
            extra = axis_angle([0, 1, 0], -twist) @ axis_angle([1, 0, 0], lean + 0.05*pull)
            r = m[:3, :3]
            m[:3, :3] = extra @ r
        side = name[-1] if name[-2:] in ('.L', '.R') else ''
        if side and name.startswith('UpperArm'):
            s = m[:3, 3]
            lo = by_name['LowerArm.'+side]; wr = by_name['Wrist.'+side]
            e0 = (m @ local(lo))[:3, 3]; h0 = (m @ local(lo) @ local(wr))[:3, 3]
            l1 = np.linalg.norm(e0-s); l2 = np.linalg.norm(h0-e0)
            h = hands[side]; dv = h-s; dist = min(np.linalg.norm(dv), (l1+l2)*0.999)
            u = unit(dv); a = (l1*l1-l2*l2+dist*dist)/(2*dist); hh = np.sqrt(max(l1*l1-a*a, 0))
            pole = POLE[side] - np.dot(POLE[side], u)*u
            elbow = s + u*a + unit(pole)*hh
            m[:3, :3] = rot_between(m[:3, :3] @ local(lo)[:3, 3], elbow - s) @ m[:3, :3]
            world['_target_'+side] = s + u*dist
        if side and name.startswith('LowerArm'):
            target = world['_target_'+side]
            wr = by_name['Wrist.'+side]
            m[:3, :3] = rot_between(m[:3, :3] @ local(wr)[:3, 3], target - m[:3, 3]) @ m[:3, :3]
        world[i] = m
        pr = pw[:3, :3]
        rl = np.linalg.solve(pr, m[:3, :3]) if parents.get(i) is not None else m[:3, :3]
        sc = np.diag(nodes[i].get('scale', [1, 1, 1]))
        rots[i] = mat_q(rl @ np.linalg.inv(sc))
    return rots, hands, world


def append(data, kind):
    a = np.asarray(data, dtype='<f4')
    while len(binary) % 4:
        binary.append(0)
    off = len(binary); binary.extend(a.tobytes())
    d['bufferViews'].append({'buffer': 0, 'byteOffset': off, 'byteLength': a.nbytes})
    acc = {'bufferView': len(d['bufferViews'])-1, 'componentType': 5126, 'count': len(a), 'type': kind}
    if kind == 'SCALAR':
        acc['min'] = [float(a.min())]; acc['max'] = [float(a.max())]
    d['accessors'].append(acc); return len(d['accessors'])-1


times = np.arange(int(round(LENGTH*FPS))+1)/FPS
tracks = {i: [] for i in joints}
err = 0.0
for t in times:
    rots, hands, world = frame(t/LENGTH)
    for side in 'LR':
        err = max(err, np.linalg.norm(world[by_name['Wrist.'+side]][:3, 3]-hands[side]))
    for i in joints:
        tracks[i].append(rots[i])
tin = append(times, 'SCALAR')
samplers, channels = [], []
for i in joints:
    o = np.array(tracks[i])
    for k in range(1, len(o)):
        if np.dot(o[k], o[k-1]) < 0:
            o[k] = -o[k]
    samplers.append({'input': tin, 'output': append(o, 'VEC4'), 'interpolation': 'LINEAR'})
    channels.append({'sampler': len(samplers)-1, 'target': {'node': i, 'path': 'rotation'}})
d['animations'] = [a for a in d['animations'] if a['name'] != 'Row']
d['animations'].append({'name': 'Row', 'samplers': samplers, 'channels': channels})
backup(GLB)
write_document(GLB, d, binary)
print('Row: %d channels, %.2f s, max hand error %.3f m' % (len(channels), LENGTH, err))
