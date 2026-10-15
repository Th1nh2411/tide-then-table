#!/usr/bin/env python3
"""Turn PixelLab walk frames into one 64x32 row of a person sheet (16x32 frames).

PixelLab animates a standing frame that was padded to 32x32 (sprite at x=8),
or x2 on 64x64 (sprite at x=16, pass --x2: blocks are sampled back by
majority). Each frame is recoloured to the standing frame's own colours (so
the row stays in the Xóm Đèn palette and the sheet's colour count), cropped
back to 16 px, feet put on the bottom row. --keep-head pastes the hand-made
head (rows 0..10, --head N for another height) of the standing frame over
the AI's, at the offset that matches it best, so faces / glasses stay the
same in every frame. --cut-rows R,R drops those rows of each AI frame (the body above moves
down), for a still whose head grew (tools/rin_hair.py).
Column 0 of the row is the standing frame, columns 1-3 the given frames
(the game plays 1-2-3-2, so give step / pass / other step).

Usage:
  pixellab_walk.py row <still16x32.png> <out_row.png> <f1> <f2> <f3> [--x2] [--keep-head] [--head N] [--cut-rows R,R]
  pixellab_walk.py stack <out_sheet.png> <row.png | sheet.png:N> ...
  pixellab_walk.py preview <sheet.png> <out_x8.png>
"""
import sys
from collections import Counter
from PIL import Image

HEAD_ROWS = 11


def load_frame(path, x2):
    im = Image.open(path).convert("RGBA")
    if x2:
        small = Image.new("RGBA", (im.width // 2, im.height // 2))
        for y in range(small.height):
            for x in range(small.width):
                px = [im.getpixel((2 * x + dx, 2 * y + dy)) for dx in (0, 1) for dy in (0, 1)]
                solid = [p for p in px if p[3] > 127]
                if len(solid) >= 2:
                    small.putpixel((x, y), Counter(solid).most_common(1)[0][0])
        im = small
    return im


def palette_of(im):
    return sorted({p[:3] for p in im.getdata() if p[3] > 0})


def snap(im, pal):
    out = Image.new("RGBA", im.size)
    for y in range(im.height):
        for x in range(im.width):
            p = im.getpixel((x, y))
            if p[3] > 127:
                c = min(pal, key=lambda q: sum((a - b) ** 2 for a, b in zip(p[:3], q)))
                out.putpixel((x, y), c + (255,))
    return out


def to_cell(im):
    """Crop the 16 px column the sprite was padded into, feet on row 31."""
    off = (im.width - 16) // 2
    cell = Image.new("RGBA", (16, 32))
    box = im.getbbox()
    shift = 31 - (box[3] - 1) if box else 0
    cell.paste(im.crop((off, 0, off + 16, im.height)), (0, shift))
    return cell


def cut_rows(cell, cut):
    """Drop the given rows; everything above them moves down."""
    keep = [y for y in range(32) if y not in cut]
    out = Image.new("RGBA", (16, 32))
    for i, y in enumerate(keep):
        out.paste(cell.crop((0, y, 16, y + 1)), (0, 32 - len(keep) + i))
    return out


def paste_head(cell, still, head_rows=HEAD_ROWS):
    head = still.crop((0, 0, 16, head_rows))
    best, best_off = None, (0, 0)
    for dy in range(0, 3):
        for dx in range(-2, 3):
            score = 0
            for y in range(head_rows):
                for x in range(16):
                    a = head.getpixel((x, y))
                    tx, ty = x + dx, y + dy
                    b = cell.getpixel((tx, ty)) if 0 <= tx < 16 and ty < 32 else (0, 0, 0, 0)
                    score += (a[3] > 0) != (b[3] > 0)
                    if a[3] and b[3] and a[:3] != b[:3]:
                        score += 0.3
            if best is None or score < best:
                best, best_off = score, (dx, dy)
    dx, dy = best_off
    out = cell.copy()
    for y in range(dy + head_rows):  # clear the AI head, keep its body
        for x in range(16):
            out.putpixel((x, y), (0, 0, 0, 0))
    if dx >= 0:
        out.alpha_composite(head.crop((0, 0, 16 - dx, head_rows)), (dx, dy))
    else:
        out.alpha_composite(head.crop((-dx, 0, 16, head_rows)), (0, dy))
    return out


def make_row(args):
    opts = {a: args[i + 1] for i, a in enumerate(args) if a in ("--head", "--cut-rows")}
    values = set(opts.values())
    still_path, out_path = args[0], args[1]
    frames = [a for a in args[2:] if not a.startswith("--") and a not in values]
    x2, keep_head = "--x2" in args, "--keep-head" in args
    head_rows = int(opts.get("--head", HEAD_ROWS))
    still = Image.open(still_path).convert("RGBA")
    pal = palette_of(still)
    row = Image.new("RGBA", (64, 32))
    row.paste(still, (0, 0))
    for i, f in enumerate(frames[:3]):
        cell = to_cell(snap(load_frame(f, x2), pal))
        if "--cut-rows" in opts:
            cell = cut_rows(cell, {int(r) for r in opts["--cut-rows"].split(",")})
        if keep_head:
            cell = paste_head(cell, still, head_rows)
        row.paste(cell, (16 * (i + 1), 0))
    row.save(out_path)


def stack(args):
    rows = []
    for a in args[1:]:
        if ":" in a:
            path, n = a.rsplit(":", 1)
            rows.append(Image.open(path).convert("RGBA").crop((0, 32 * int(n), 64, 32 * int(n) + 32)))
        else:
            rows.append(Image.open(a).convert("RGBA"))
    sheet = Image.new("RGBA", (64, 32 * len(rows)))
    for i, r in enumerate(rows):
        sheet.paste(r, (0, 32 * i))
    sheet.save(args[0])


def preview(args):
    im = Image.open(args[0]).convert("RGBA")
    bg = Image.new("RGBA", im.size, (120, 140, 120, 255))
    bg.alpha_composite(im)
    bg.resize((im.width * 8, im.height * 8), Image.NEAREST).save(args[1])


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    {"row": make_row, "stack": stack, "preview": preview}.get(cmd, lambda a: sys.exit(__doc__))(sys.argv[2:])
