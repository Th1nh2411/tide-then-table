#!/usr/bin/env python3
"""Idle sheets (characters/<name>_idle.png) from the standing frames (column 0)
of each person sheet: rows down / up / left like the walk sheet, 4 columns:
  0 standing, 1 breathing in (upper body 1 px down), 2 = 0 with eyes shut,
  3 = 1 with eyes shut. Art.draw_person plays 0/1 and blinks now and then.
Breathing moves rows 0..WAIST down 1 px (row WAIST+1 is covered); blinking
repaints the pixels listed in BLINK (front + side frames, coordinates of
the standing frame). Re-run after editing a sheet; update BLINK / WAIST if
a face or a waist moves.
Usage: python3 tools/make_idle.py [name ...]   (default: rin bao vy)
"""
import os
import sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "characters")

# Last row that moves when breathing (bottom of the top / arms).
WAIST = {"rin": 20, "bao": 18, "vy": 17}

# Per sheet row (0 down, 2 left): (x, y, colour) painted for shut eyes.
BLINK = {
    "rin": {  # glasses: pupils gone, the lenses flash (a lid line reads as sunglasses)
        0: [(4, 9, "a4dddb"), (8, 9, "a4dddb")],
        2: [(3, 8, "a4dddb")],
    },
    "bao": {  # whites + pupils -> skin, the upper lid stays as the shut eye
        0: [(5, 7, "d7b594"), (6, 7, "d7b594"), (8, 7, "d7b594"), (9, 7, "d7b594")],
        2: [(4, 6, "d7b594"), (5, 6, "d7b594")],
    },
    "vy": {
        0: [(5, 8, "e7d5b3"), (6, 8, "e7d5b3"), (9, 8, "e7d5b3"), (10, 8, "e7d5b3")],
        2: [(6, 7, "151d28"), (5, 8, "e7d5b3"), (6, 8, "e7d5b3")],
    },
}


def rgba(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def breathe(frame, waist):
    out = frame.copy()
    out.paste(Image.new("RGBA", (16, waist + 2)), (0, 0))
    out.paste(frame.crop((0, 0, 16, waist + 1)), (0, 1))
    return out


def blink(frame, edits, dy=0):
    out = frame.copy()
    for x, y, c in edits:
        if out.getpixel((x, y + dy))[3]:
            out.putpixel((x, y + dy), rgba(c))
    return out


def make(name):
    sheet = Image.open(os.path.join(ROOT, name + ".png")).convert("RGBA")
    out = Image.new("RGBA", (64, 96))
    for row in range(3):
        still = sheet.crop((0, 32 * row, 16, 32 * row + 32))
        down = breathe(still, WAIST[name])
        edits = BLINK[name].get(row, [])
        for col, f in enumerate([still, down, blink(still, edits), blink(down, edits, 1)]):
            out.paste(f, (16 * col, 32 * row))
    path = os.path.join(ROOT, name + "_idle.png")
    out.save(path)
    print("wrote", path)


if __name__ == "__main__":
    for n in sys.argv[1:] or ["rin", "bao", "vy"]:
        make(n)
