#!/usr/bin/env python3
"""Change a person's proportions on every 16x32 frame of a sheet, feet kept
on the bottom row.
  cut: drop pixel rows; what is above moves down.
  add: repeat pixel rows (each listed row twice); what is above moves up
       (the frame's top rows must be empty).
--sheet-rows limits it to some sheet rows (0 down, 1 up, 2 left, 3 busy),
since a torso row differs per facing. Used to bring Bảo to Rin's landmarks
(chin row 12, crotch row 25, shins 25-29, feet 30-31 + a longer body):
  cut 8,26,27 ; add 17,18,19 --sheet-rows 0,3 ; add 15,16,17 --sheet-rows 1 ;
  add 16,17,18 --sheet-rows 2
Re-run tools/make_idle.py afterwards (and shift its BLINK / WAIST rows).
Usage: python3 tools/cut_rows.py <sheet.png> cut|add <row,row,...> [--sheet-rows N,N]
"""
import sys
from PIL import Image


def change(frame, mode, rows):
    if mode == "cut":
        order = [y for y in range(frame.height) if y not in rows]
    else:
        order = [y for y in range(frame.height) for _ in range(2 if y in rows else 1)]
        lost = order[:len(order) - frame.height]
        if any(frame.crop((0, y, frame.width, y + 1)).getbbox() for y in lost):
            sys.exit("add: frame has no empty rows on top")
        order = order[len(order) - frame.height:]
    out = Image.new("RGBA", frame.size)
    top = frame.height - len(order)
    for i, y in enumerate(order):
        out.paste(frame.crop((0, y, frame.width, y + 1)), (0, top + i))
    return out


def main(path, mode, rows, sheet_rows=None):
    sheet = Image.open(path).convert("RGBA")
    out = sheet.copy()
    for fy in range(0, sheet.height, 32):
        if sheet_rows is not None and fy // 32 not in sheet_rows:
            continue
        for fx in range(0, sheet.width, 16):
            out.paste(change(sheet.crop((fx, fy, fx + 16, fy + 32)), mode, rows), (fx, fy))
    out.save(path)


def ints(text):
    return {int(r) for r in text.split(",")}


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) < 3 or args[1] not in ("cut", "add"):
        sys.exit(__doc__)
    only = ints(args[args.index("--sheet-rows") + 1]) if "--sheet-rows" in args else None
    main(args[0], args[1], ints(args[2]), only)
