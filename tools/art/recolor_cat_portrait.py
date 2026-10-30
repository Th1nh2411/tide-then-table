"""Recolour the cat model (assets/models/ready/cat/cat.glb) to match its
approved portrait (assets/sprites/portraits/cat/base.png): blue-black tabby,
light grey chest/muzzle, teal eyes. Palette "Xóm Đèn" colours only.
Re-runnable (sets material colours by name). Needs numpy (/usr/bin/python3).
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/art'))
from glb_common import load_glb, write_document, backup  # noqa: E402

GLB = ROOT / 'assets/models/ready/cat/cat.glb'
# material name -> sRGB hex (palette)
COLOURS = {
    'Orange': '2c4058',        # body: "Anh toc xanh den" blue-black
    'Eyes': '2c4058',          # eye-socket patch, same as body
    'Cream': 'c7cfcc',         # chest / muzzle: Xam 7
    'cat_EyeWhite': 'c7cfcc',
    'cat_Iris': '73bed3',      # Xanh bien 5
    'cat_Pupil': '090a14',
    'cat_Highlight': 'ebede9',
}


def linear(hex_):
    out = []
    for i in (0, 2, 4):
        c = int(hex_[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return out + [1.0]


d, raw = load_glb(GLB)
binary = bytearray(raw[:d['buffers'][0]['byteLength']])
done = []
for m in d['materials']:
    if m.get('name') in COLOURS:
        m.setdefault('pbrMetallicRoughness', {})['baseColorFactor'] = linear(COLOURS[m['name']])
        done.append(m['name'])
backup(GLB)
write_document(GLB, d, binary)
print('recoloured:', ', '.join(done))
