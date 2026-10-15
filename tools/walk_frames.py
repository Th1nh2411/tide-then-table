#!/usr/bin/env python3
"""Rebuild the front / back walk frames of a 16x32 person sheet from its idle
frame (column 0), Stardew ping-pong style (the game plays 1-2-3-2):
  column 1 = step: body down 1 px, left foot lifted, left arm back, right arm forward
  column 2 = passing: the idle pose
  column 3 = step: the other side
Body plan (see tools/reproportion.py): head rows 0-10, torso 11-18, legs 19-31.
Usage: python3 tools/walk_frames.py assets/sprites/characters/rin.png [out.png] [rows]
Rows 0 (down) and 1 (up) are rebuilt (or only the listed ones, e.g. "1");
side and busy rows are kept.
"""
import sys
from PIL import Image

LEG_TOP = 22          # a mid-leg row: the body sinks into it, the foot lifts below it
ARM_TOP = 15          # arms move from this row down (after the body sank)
ARM_BOTTOM = 20       # lowest row a hand may reach
LEFT_ARM = range(0, 3)
RIGHT_ARM = range(12, 16)
LEFT_LEG = range(0, 8)
RIGHT_LEG = range(8, 16)
EMPTY = (0, 0, 0, 0)


def frame_rows(im, row):
    return [[im.getpixel((x, row * 32 + y)) for x in range(16)] for y in range(32)]


def put(im, rows, column, row):
    for y in range(32):
        for x in range(16):
            im.putpixel((column * 16 + x, row * 32 + y), rows[y][x])


def step(idle, lift_leg, back_arm, front_arm):
    sunk = [r[:] for r in idle]  # body down 1 px, one leg row swallowed
    sunk[0] = [EMPTY] * 16
    for y in range(1, LEG_TOP + 1):
        sunk[y] = idle[y - 1][:]
    rows = [r[:] for r in sunk]
    for x in lift_leg:  # foot up one pixel
        for y in range(LEG_TOP + 1, 32):
            rows[y][x] = sunk[y + 1][x] if y + 1 < 32 else EMPTY
    for x in back_arm:  # hand up one pixel
        for y in range(ARM_TOP, ARM_BOTTOM + 1):
            rows[y][x] = sunk[y + 1][x] if y < ARM_BOTTOM else EMPTY
    for x in front_arm:  # hand down one pixel
        for y in range(ARM_TOP, ARM_BOTTOM + 1):
            rows[y][x] = sunk[y - 1][x]
    return rows


def main():
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) > 2 else src
    rows = [int(r) for r in sys.argv[3].split(",")] if len(sys.argv) > 3 else [0, 1]
    im = Image.open(src).convert("RGBA")
    for row in rows:
        idle = frame_rows(im, row)
        put(im, step(idle, LEFT_LEG, LEFT_ARM, RIGHT_ARM), 1, row)
        put(im, idle, 2, row)
        put(im, step(idle, RIGHT_LEG, RIGHT_ARM, LEFT_ARM), 3, row)
    im.save(dst)


if __name__ == "__main__":
    main()
