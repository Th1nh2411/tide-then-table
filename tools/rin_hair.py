#!/usr/bin/env python3
"""Give Rin's standing frames their original hair back.

tools/reproportion.py cut his hair from 8 rows to 5 (a flat cap). This takes
the 8 hair rows (4..11) of the pre-reproportion sheet (git 388d11d) and puts
the current face + body under them; to stay 32 tall it drops CUT_ROWS (two
shin rows and one shorts row): head 14 rows.
Usage: python3 tools/rin_hair.py <old_sheet.png> <still16x32.png> <sheet_row> <out.png>
  (old sheet: git show 388d11d:assets/sprites/characters/rin.png)
"""
import sys
from PIL import Image

OLD_HAIR = range(4, 12)  # rows of the old sheet's frames
FACE_FROM = 5  # first row under the hair in the current still
CUT_ROWS = (21, 26, 27)  # rows of the current still to drop


def main(old_path, still_path, sheet_row, dst):
    old = Image.open(old_path).convert("RGBA")
    still = Image.open(still_path).convert("RGBA")
    top = 32 * int(sheet_row)
    rows = [old.crop((0, top + y, 16, top + y + 1)) for y in OLD_HAIR]
    rows += [still.crop((0, y, 16, y + 1)) for y in range(FACE_FROM, 32) if y not in CUT_ROWS]
    out = Image.new("RGBA", (16, 32))
    for y, r in enumerate(rows):
        out.paste(r, (0, y))
    out.save(dst)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        sys.exit(__doc__)
    main(*sys.argv[1:])
