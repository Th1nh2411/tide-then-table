#!/usr/bin/env python3
"""Re-proportion an old 16x32 person sheet (big head, 6-row legs, feet on
row 31) to the game's body plan: the figure fills all 32 rows, head 11
(rows 0-10), torso 8 (11-18), legs 13 (19-31), matched to Vy's reference
sheet: hips / shorts down to row 22, legs split from row 23, shins 3 px,
arms 3 px (body 13 wide).
Old layout read from each frame: head = top..17 (the last 7 rows are the
face, hair rows above are thinned or doubled), torso = 18..25, legs = 26..31
(shorts / trousers stretched to 4 rows, the shin row repeated, 2 rows of
foot). Bobbed frames (top 1 px higher than column 0 of their row) shift the
split. Front, back and busy rows (0, 1, 3) also get slimmer arms and shins.
Usage: python3 tools/reproportion.py old.png new.png
Then run tools/walk_frames.py on the result for the down / up rows.
"""
import sys
from PIL import Image

HEAD, TORSO, LEGS = 11, 8, 13
FACE = 7          # rows of the old head kept as they are (chin up)
OLD_NECK = 17     # last head row of an unbobbed old frame
SHORTS, FOOT = 2, 2  # old rows
SHORTS_OUT = 4      # rows of shorts / trousers in the new body
TORSO_ROWS = range(11, 19)
SHIN_ROWS = range(25, 30)
SLIM_ROWS = (0, 1, 3)  # sheet rows seen from the front / back


def pick(rows, count):
    """`count` rows spread evenly over `rows` (drops or doubles)."""
    if count == 1:
        return [rows[0]]
    return [rows[round(i * (len(rows) - 1) / (count - 1))] for i in range(count)]


def top_of(im, column, row):
    frame = im.crop((column * 16, row * 32, column * 16 + 16, row * 32 + 32))
    box = frame.getbbox()
    return box[1] if box else 0


def remap(top, delta):
    neck = OLD_NECK + delta
    hair = list(range(top, neck - FACE + 1))
    face = list(range(neck - FACE + 1, neck + 1))
    torso = list(range(neck + 1, neck + 1 + TORSO))
    legs = list(range(neck + 1 + TORSO, 32))
    middle = legs[SHORTS:-FOOT]
    shorts = [legs[0]] * (SHORTS_OUT - 1) + [legs[1]]
    return (pick(hair, HEAD - FACE) + face + torso
            + shorts + stretch(middle, LEGS - SHORTS_OUT - FOOT) + legs[-FOOT:])


def stretch(rows, count):
    """Legs: every row once, the lowest one (the shin) repeated."""
    return rows[:-1] + [rows[-1]] * (count - len(rows) + 1)


def slim(frame):
    """Front / back frame (16x32 list of rows): arms lose their middle column,
    shins lose their inner column (centred over the feet)."""
    empty = (0, 0, 0, 0)
    for y in TORSO_ROWS:
        row = frame[y]
        frame[y] = [empty, row[0]] + row[2:13] + row[14:16] + [empty]
    for y in SHIN_ROWS:
        row = frame[y]
        runs, x = [], 0
        while x < 16:
            if row[x][3]:
                start = x
                while x < 16 and row[x][3]:
                    x += 1
                runs.append((start, x - 1))
            x += 1
        for a, b in runs:
            if b - a < 3:
                continue
            if (a + b) / 2 < 7.5:  # left leg: inner outline moves out, shin over the foot
                row[b - 1], row[b] = row[b], empty
            else:  # right leg: same on its inner side
                row[a + 1], row[a] = row[a], empty
    return frame


def main():
    src = Image.open(sys.argv[1]).convert("RGBA")
    out = Image.new("RGBA", src.size)
    for row in range(src.size[1] // 32):
        base = top_of(src, 0, row)
        for column in range(src.size[0] // 16):
            top = top_of(src, column, row)
            source_rows = remap(top, min(top - base, 0))
            frame = [[src.getpixel((column * 16 + x, row * 32 + sy)) for x in range(16)] for sy in source_rows]
            if row in SLIM_ROWS:
                frame = slim(frame)
            for y in range(32):
                for x in range(16):
                    out.putpixel((column * 16 + x, row * 32 + y), frame[y][x])
    out.save(sys.argv[2])


if __name__ == "__main__":
    main()
