"""Redraws the glasses on the Rin walk sheet (characters/rin.png, 16x32 frames).
usage: python3 tools/rin_glasses.py <original.png> <out.png> <variant a|b|c|d|e>
The game uses "e"; apply it to the original sheet: git show HEAD:assets/sprites/characters/rin.png > /tmp/rin_orig.png
"""
import sys
from PIL import Image
SRC, OUT, VARIANT = sys.argv[1], sys.argv[2], sys.argv[3]
SKIN = (0xc0, 0x94, 0x73); EDGE = (0x7a, 0x48, 0x41); W = (0xeb, 0xed, 0xe9); G = (0xc7, 0xcf, 0xcc); BLUE = (0x73, 0xbe, 0xd3); TEMPLE = (0x4d, 0x2b, 0x32)
FRAME = (0x09, 0x0a, 0x14); PUPIL = (0x15, 0x1d, 0x28); LENS = (0xa4, 0xdd, 0xdb)
im = Image.open(SRC).convert('RGBA'); px = im.load()
def put(c, r, x, y, col):
    px[c * 16 + x, r * 32 + y] = col + (255,)
for c in range(4):
    dy = 0 if c % 2 == 0 else -1   # frames 1, 3 are one pixel higher
    # front (row 0): frame -> skin
    for x in range(3, 12): put(c, 0, x, 12 + dy, SKIN)
    for x in (3, 6, 7, 8, 11): put(c, 0, x, 13 + dy, SKIN)
    for x in (4, 5, 6, 8, 9, 10): put(c, 0, x, 14 + dy, SKIN)
    if VARIANT == 'a':      # 2x1 lenses as before
        lenses = [(4, 13, W), (5, 13, G), (9, 13, W), (10, 13, G)]
    elif VARIANT == 'b':    # 3x1 lenses, bridge gap at the nose
        lenses = [(4, 13, W), (5, 13, W), (6, 13, G), (8, 13, W), (9, 13, W), (10, 13, G)]
    elif VARIANT == 'e':    # top bar + bridge, 2x2 light lenses with a pupil
        lenses = [(x, 12, FRAME) for x in range(3, 12)] + [(7, 13, FRAME),
            (4, 13, LENS), (5, 13, PUPIL), (4, 14, W), (5, 14, LENS),
            (9, 13, PUPIL), (10, 13, LENS), (9, 14, LENS), (10, 14, W)]
    elif VARIANT == 'd':    # reference: blue 2x1 lenses, no frame
        lenses = [(4, 13, BLUE), (5, 13, BLUE), (9, 13, BLUE), (10, 13, BLUE)]
    else:                   # 'c': 3x2 lenses
        lenses = [(x, y, W) for y in (13, 14) for x in (4, 5, 6, 8, 9, 10)] + [(6, 14, G), (10, 14, G)]
    for x, y, col in lenses: put(c, 0, x, y + dy, col)
    # side (row 2, facing left): frame -> skin, one lens at the front of the face
    put(c, 2, 2, 11 + dy, EDGE)
    for x in range(3, 8): put(c, 2, x, 11 + dy, SKIN)
    put(c, 2, 2, 12 + dy, EDGE); put(c, 2, 3, 12 + dy, SKIN); put(c, 2, 6, 12 + dy, SKIN)
    for x in (4, 5): put(c, 2, x, 13 + dy, SKIN)
    if VARIANT == 'a':
        side = [(4, 12, W), (5, 12, G)]
    elif VARIANT == 'b':
        side = [(3, 12, W), (4, 12, W), (5, 12, G)]
    elif VARIANT == 'e':    # top bar runs back as the temple, frame front edge, lens looks left
        side = [(x, 11, FRAME) for x in range(2, 8)] + [(2, 12, FRAME),
            (3, 12, PUPIL), (4, 12, LENS), (3, 13, LENS), (4, 13, W)]
    elif VARIANT == 'd':    # far lens peeks at the profile, near lens 2 px, dark temple
        side = [(2, 12, BLUE), (3, 12, EDGE), (4, 12, BLUE), (5, 12, BLUE), (6, 12, TEMPLE)]
    else:
        side = [(x, y, W) for y in (12, 13) for x in (3, 4, 5)] + [(5, 13, G)]
    for x, y, col in side: put(c, 2, x, y + dy, col)
im.save(OUT)
