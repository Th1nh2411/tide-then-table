#!/usr/bin/env python3
"""Vy's restaurant sheet (16x32 frames, 4 columns): rows down / up / left.
Row 1 (down, idle + ping-pong walk) comes from the reference sheet the owner
picked (tools/ref/vy_spritesheet.webp, a 4-frame Stardew-style walk shown at
~4.8x): sampled back to its 80x80 pixels, background flood-filled away, then
recoloured to Vy (black glossy hair, pink blouse, cream mini skirt, bare legs,
white sneakers) plus gold earrings and a pastel clip. Rows 2-3 (up, left)
are drawn here as character maps; the up walk comes from tools/walk_frames.py.
Usage: python3 tools/make_vy_sheet.py [out.png]
"""
import colorsys
import os
import subprocess
import sys
from PIL import Image

PALETTE = {
    ".": None,
    "a": "151d28",  # outline
    "H": "202e37",  # hair
    "h": "394a50",  # hair mid
    "l": "577277",  # hair shine
    "c": "73bed3",  # clip / hair tie
    "s": "e7d5b3",  # skin
    "S": "d7b594",  # skin shade
    "o": "c09473",  # skin edge
    "w": "ebede9",  # eye white
    "m": "cf573c",  # lips
    "b": "ad7757",  # blush
    "g": "e8c170",  # earring
    "P": "c65197",  # blouse
    "p": "752438",  # blouse shade
    "K": "ebede9",  # skirt / sneakers
    "k": "c7cfcc",  # skirt shade
}

# Up / left rows, drawn to the reference's front silhouette (13 px wide,
# skirt to row 21, hem row 22, 3 px shins, ankles 28-29, sneakers 30-31).
BACK = [
    "......aaaa......",
    ".....aHhHaa.....",
    "....aaHhhHHa.aa.",
    "...acHHhhhHHaHa.",
    "..aHHHHHhhhHHHa.",
    "..aHHhHHHhHHHaa.",
    "..aHHhHHHhHHHa..",
    ".aHHHhHHHhHHHa..",
    ".aHHhHHHhHHHaa..",
    "..aHhHHHhHHHHa..",
    "...agHhHHhHga...",
    "...aHHhHHhHHa...",
    "..aPaHhHHhHaPa..",
    "..aPaHhHHhHaPa..",
    "..aPPaHhhHaPa...",
    "..aPPPaHHaPPa...",
    ".asaPPPaaPPPsa..",
    ".assaPPPPPPssa..",
    "..asakkkkkkassa.",
    "...akkkKKkKkasa.",
    "...akKkkkKKkasa.",
    "...akkkkkKkkaa..",
    "...aaaaaaaaaa...",
    "....aSSa.aSSa...",
    "....aSSa.aSSa...",
] + [".....aSa..aSa..."] * 3 + [".....asa..asa..."] * 2 + [
    "....aKKa..aKKa..",
    "....aaaa..aaaa..",
]

SIDE_HEAD_TORSO = [
    ".....aaaaa......",
    "....aHhHHHa.....",
    "...aHhhHHHHa....",
    "..aHhHHHHcHHa...",
    "..aaHHHHHHHHa...",
    ".aSaaHHHHHHHHa..",
    ".asaHHHHHHHHHa..",
    "asHKSaHHHHHHHa..",
    ".asbsSaHHHHHHa..",
    "..asSSagHHHHHa..",
    "...aSSaHHHHHa...",
    "....aPPPPaHHa...",
    "...aHPPPPPaHHa..",
    "...ahPPPPPaHHa..",
    "...aHPPPPPaHa...",
    "...ahPPPPpaHa...",
    "...aPPPPPpaa....",
    "...aPPPPPpa.....",
    "...akkkkkka.....",
    "...akkkkkkka....",
    "..akkKkkkkkka...",
    "..akKkkkkKkka...",
    "..aaaaaaaaaaa...",
]

SIDE_STAND_LEGS = [".....aSsa......."] * 2 + [".....aSa........"] * 3 + [".....asa........"] * 2 + [
    "...aKKKa........",
    "...aaaaa........",
]

SIDE_STRIDE_LEGS = [
    ".....aSsa.......",
    "....aSaaSa......",
    "....aSa.aSa.....",
    "...aSa..aSa.....",
    "...aSa...aSa....",
    "...asa...asa....",
    "..asa.....asa...",
    ".aKKa.....aKKa..",
    ".aaaa.....aaaa..",
]


def side_frame(legs, arm_dx):
    """Side view: the near arm hangs at column 6 (+arm_dx swings it)."""
    rows = [list(r) for r in SIDE_HEAD_TORSO + legs]
    x = 6 + arm_dx
    for y in (14, 15, 16):
        rows[y][x] = "s"
    rows[17][x] = "S"
    rows[18][x], rows[18][x + 1] = "s", "S"
    return ["".join(r) for r in rows]


def frame(rows):
    assert len(rows) == 32, len(rows)
    img = Image.new("RGBA", (16, 32))
    for y, line in enumerate(rows):
        assert len(line) == 16, (y, line)
        for x, ch in enumerate(line):
            hex_color = PALETTE[ch]
            if hex_color:
                img.putpixel((x, y), tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (255,))
    return img


REF = "tools/ref/vy_spritesheet.webp"
REF_GRID = 80                      # the reference's real pixel size
REF_FRAMES = [(8 + i * 16, 32) for i in range(4)]  # top-left of each 16x32 frame


def hx(color):
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def ref_pixels(path):
    """The reference back at 80x80: average the middle of each big pixel."""
    big = Image.open(path).convert("RGB")
    scale = big.size[0] / REF_GRID
    small = Image.new("RGB", (REF_GRID, REF_GRID))
    for y in range(REF_GRID):
        for x in range(REF_GRID):
            pts = [big.getpixel((int((x + 0.5) * scale) + dx, int((y + 0.5) * scale) + dy))
                   for dx in (-1, 0) for dy in (-1, 0)]
            small.putpixel((x, y), tuple(sum(p[i] for p in pts) // 4 for i in range(3)))
    return small


def cut_out(small, left, top):
    """One frame with the brown card background flood-filled away."""
    frame = small.crop((left, top, left + 16, top + 32))
    px = frame.load()

    def is_bg(p):
        return (150 < p[0] < 225 and p[1] > 110 and p[2] > 75
                and sum(abs(a - b) for a, b in zip(p, (195, 150, 105))) < 95)

    bg = set()
    stack = [(x, y) for x in range(16) for y in (0, 31)] + [(x, y) for x in (0, 15) for y in range(32)]
    while stack:
        x, y = stack.pop()
        if (x, y) in bg or not (0 <= x < 16 and 0 <= y < 32) or not is_bg(px[x, y]):
            continue
        bg.add((x, y))
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    out = Image.new("RGBA", (16, 32))
    for y in range(32):
        for x in range(16):
            if (x, y) not in bg:
                out.putpixel((x, y), px[x, y] + (255,))
    return out


def vy_color(rgb, x, y):
    """Reference colour at (x, y) -> Vy's colour (by hue and body part)."""
    r, g, b = rgb
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    h *= 360
    red = h < 45 or h > 330
    if v < 0.30:
        return "151d28"
    if red and s > 0.7 and v < 0.5:  # dark red outline; straps on the top
        return "752438" if 11 <= y <= 17 and 6 <= x <= 12 else "151d28"
    if red and s > 0.6 and h < 12 and s < 0.85 and v > 0.7:  # salmon skin shadow
        return "d7b594" if y < 18 else "e7d5b3"
    if red and s > 0.6:  # orange hair -> black, belt / boots -> skin
        if y >= 18:
            return "e7d5b3"
        return "394a50" if v > 0.95 else ("202e37" if v > 0.75 else "151d28")
    if 75 < h < 170 and s > 0.25:  # green top -> pink blouse
        return "c65197" if v > 0.35 else "752438"
    if y <= 21 and h < 50 and 0.2 < s <= 0.6 and v > 0.75:  # hands by the skirt
        return "e7d5b3"
    if y >= 18:  # trousers -> skirt (18-21), hem, bare legs
        if y <= 21:
            return "ebede9" if v > 0.5 else "c7cfcc"
        if y == 22:
            return "151d28"
        return "e7d5b3" if v > 0.5 else "d7b594"
    if 230 < h < 345 and s > 0.15:  # purple eyes -> dark
        return "ebede9" if v > 0.75 else ("202e37" if v > 0.5 else "151d28")
    if s < 0.22:
        return "ebede9"
    if 16 <= y <= 17 and 5 <= x <= 10:  # blouse covers the midriff
        return "c65197"
    return "e7d5b3" if v > 0.75 else "d7b594"


def recolor(ref):
    out = Image.new("RGBA", (16, 32))
    for y in range(32):
        for x in range(16):
            p = ref.getpixel((x, y))
            if p[3]:
                out.putpixel((x, y), hx(vy_color(p[:3], x, y)))
    for y in range(28, 32):  # ankles, white sneakers, outline at both ends
        xs = [x for x in range(16) if out.getpixel((x, y))[3]]
        runs = []
        for x in xs:
            if runs and x == runs[-1][-1] + 1:
                runs[-1].append(x)
            else:
                runs.append([x])
        for run in runs:
            for x in run:
                edge = x in (run[0], run[-1]) or y == 31
                out.putpixel((x, y), hx("151d28" if edge else ("e7d5b3" if y < 30 else "ebede9")))
    add_details(out)
    return out


def add_details(frame):
    """Gold earrings beside the jaw, a pastel clip in the hair."""
    skin = [x for x in range(16) if frame.getpixel((x, 9))[:3] in (hx("e7d5b3")[:3], hx("d7b594")[:3])]
    if skin:
        for x in (min(skin) - 1, max(skin) + 1):
            if 0 <= x < 16 and frame.getpixel((x, 10))[3]:
                frame.putpixel((x, 10), hx("e8c170"))
    top = next(y for y in range(32) if any(frame.getpixel((x, y))[3] for x in range(16)))
    for x in (11, 10, 12):
        if frame.getpixel((x, top + 3))[:3] in (hx("202e37")[:3], hx("394a50")[:3]):
            frame.putpixel((x, top + 3), hx("73bed3"))
            break


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "assets/sprites/characters/vy.png")
    small = ref_pixels(os.path.join(root, REF))
    sheet = Image.new("RGBA", (64, 96))
    for column, (left, top) in enumerate(REF_FRAMES):
        sheet.paste(recolor(cut_out(small, left, top)), (column * 16, 0))
        sheet.paste(frame(BACK), (column * 16, 32))
        side = side_frame(SIDE_STRIDE_LEGS, (-1, 1)[column // 2]) if column % 2 else side_frame(SIDE_STAND_LEGS, 0)
        sheet.paste(frame(side), (column * 16, 64))
    sheet.save(out)
    subprocess.run([sys.executable, os.path.join(root, "tools/walk_frames.py"), out, out, "1"], check=True)


if __name__ == "__main__":
    main()
