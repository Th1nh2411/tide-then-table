#!/usr/bin/env python3
"""Builds assets/sprites/characters/cat.png (Mỡ, the restaurant cat) from the
grey cat sheet in build/pixelize/catpixel/cat 1.png (32x32 cells).

Output: 8 columns x 2 rows of 24x24 frames, feet on the bottom row.
  row 0 = sitting (front), tail flick + a blink
  row 1 = walking right (8 frames)
Recoloured to the Xóm Đèn palette as a chubby orange tabby, with our own
details: white bib, white socks, white tail tip, stripes on the back.

usage: python3 tools/make_cat_sheet.py [source.png] [out.png]
"""
import sys
from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else "build/pixelize/catpixel/cat 1.png"
OUT = sys.argv[2] if len(sys.argv) > 2 else "assets/sprites/characters/cat.png"
CELL = 32
FRAME = 24
CROP = (4, 1)  # top-left of the 24x24 window inside a 32x32 source cell

# Source colours -> Xóm Đèn.
OUTLINE = (21, 29, 40)       # 151d28
FUR = (190, 119, 43)         # be772b
FUR_DARK = (136, 75, 43)     # 884b2b
FUR_LIGHT = (222, 158, 65)   # de9e41
CREAM = (231, 213, 179)      # e7d5b3
WHITE = (235, 237, 233)      # ebede9
EAR = (192, 148, 115)        # c09473
NOSE = (207, 87, 60)         # cf573c
RECOLOR = {
    (18, 14, 20): OUTLINE,
    (98, 103, 115): FUR,
    (65, 71, 82): FUR_DARK,
    (134, 141, 155): FUR_LIGHT,
    (154, 135, 126): EAR,
    (202, 113, 159): NOSE,
    (225, 222, 231): WHITE,
    (225, 151, 198): CREAM,
}
FUR_COLORS = (FUR, FUR_DARK, FUR_LIGHT)

SIT = (0, 0)    # (column, row) in the source
WALK_ROW = 6    # walk right, 8 frames


def cell(src: Image.Image, col: int, row: int) -> Image.Image:
    x, y = col * CELL + CROP[0], row * CELL + CROP[1]
    frame = src.crop((x, y, x + FRAME, y + FRAME)).convert("RGBA")
    px = frame.load()
    for fy in range(FRAME):
        for fx in range(FRAME):
            r, g, b, a = px[fx, fy]
            if a:
                px[fx, fy] = RECOLOR.get((r, g, b), (r, g, b)) + (255,)
    return frame


def paint(frame: Image.Image, points, color) -> None:
    px = frame.load()
    for x, y in points:
        if px[x, y][3] and px[x, y][:3] in FUR_COLORS:
            px[x, y] = color + (255,)


def sit_base(src: Image.Image) -> Image.Image:
    f = cell(src, *SIT)
    # Coordinates below are in the 24x24 frame (source minus CROP).
    paint(f, [(x, y) for y in (14, 15, 16) for x in range(9, 14)], CREAM)       # bib
    paint(f, [(10, 13), (12, 13), (10, 17), (11, 17), (12, 17)], CREAM)  # muzzle, bib point
    paint(f, [(9, 21), (13, 21), (9, 22), (13, 22)], WHITE)                      # socks
    paint(f, [(19, 16), (20, 16), (20, 17)], WHITE)                              # tail tip
    paint(f, [(7, 17), (7, 18), (15, 17), (15, 18)], FUR_DARK)                   # side stripes
    return f


def sit_tail_up(base: Image.Image) -> Image.Image:
    # Tail tip lifted one pixel (rows 14-19, right of the body).
    f = base.copy()
    src, dst = base.load(), f.load()
    for y in range(14, 20):
        for x in range(18, 24):
            dst[x, y - 1] = src[x, y]
    return f


def sit_blink(base: Image.Image) -> Image.Image:
    f = base.copy()
    px = f.load()
    for x in (9, 13):  # eyes: top pixel closes
        px[x, 11] = FUR + (255,)
    return f


def walk(src: Image.Image, col: int) -> Image.Image:
    f = cell(src, col, WALK_ROW)
    px = f.load()
    # Back stripes: 3 short bars from the top of the torso.
    for x in (8, 11, 14):
        top = next((y for y in range(FRAME) if px[x, y][3] and px[x, y][:3] in FUR_COLORS), None)
        if top is not None:
            paint(f, [(x, top), (x, top + 1)], FUR_DARK)
    # Socks: the lowest fur pixel of every leg column.
    for x in range(FRAME):
        low = next((y for y in range(FRAME - 1, 18, -1) if px[x, y][3] and px[x, y][:3] in FUR_COLORS), None)
        if low is not None:
            paint(f, [(x, low)], WHITE)
    # Tail tip: the two highest fur pixels left of the body.
    tip = [(x, y) for y in range(FRAME) for x in range(0, 7) if px[x, y][3] and px[x, y][:3] in FUR_COLORS]
    paint(f, tip[:2], WHITE)
    return f


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    base = sit_base(src)
    tail, blink = sit_tail_up(base), sit_blink(base)
    sit = [base, base, tail, tail, base, base, blink, base]
    walking = [walk(src, c) for c in range(8)]
    sheet = Image.new("RGBA", (FRAME * 8, FRAME * 2), (0, 0, 0, 0))
    for i, frame in enumerate(sit):
        sheet.paste(frame, (i * FRAME, 0))
    for i, frame in enumerate(walking):
        sheet.paste(frame, (i * FRAME, FRAME))
    sheet.save(OUT)
    print(f"wrote {OUT} {sheet.size}")


if __name__ == "__main__":
    main()
