#!/usr/bin/env python3
"""Clean a 128px portrait: hard alpha + at most N colours, darks from Xóm Đèn.

  tools/portrait_colors.py in.png out.png --colors 40

Portraits keep their own skin / cloth ramps (looser than the Xóm Đèn
palette), but outlines, hair and deep shadows snap to the Xóm Đèn colours so
they sit with the rest of the game.

Options:
  --colors N      colours kept in the portrait (default 40)
  --dark-luma L   colours darker than this snap to the palette (default 70)
  --sheen HEX     hair sheen on the brightest ~7% of the hair; reddish specks
                  in the hair go back to the hair colour (default 2c4058, in
                  the palette; "" skips both)
"""
import argparse
import os
import sys
from collections import Counter

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixelize import DEFAULT_PALETTE, load_palette, nearest  # noqa: E402


def luma(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def clean(img, colors=40, dark_luma=70, palette_path=DEFAULT_PALETTE, sheen=(0x2c, 0x40, 0x58)):
    img = img.convert("RGBA")
    px = img.load()
    solid = [(x, y) for y in range(img.height) for x in range(img.width) if px[x, y][3] >= 128]
    # Quantize only the opaque pixels, so the background isn't a colour.
    strip = Image.new("RGB", (len(solid), 1))
    strip.putdata([px[x, y][:3] for x, y in solid])
    q = strip.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    flat = q.getpalette()[:colors * 3]
    ramp = [tuple(flat[i:i + 3]) for i in range(0, len(flat), 3)]
    palette = load_palette(palette_path)
    cache = {}
    ramp = [palette[nearest(c, palette, cache)] if luma(c) < dark_luma else c for c in ramp]
    out = Image.new("RGBA", img.size)
    opx = out.load()
    for (x, y), i in zip(solid, q.getdata()):
        opx[x, y] = ramp[i] + (255,)
    if sheen:
        _hair_sheen(out, img, sheen, dark_luma)
    return out


def _is_dark(c, dark_luma, warm):
    return c[3] and luma(c) < dark_luma and (c[0] > c[2]) == warm


def _hair_sheen(img, src, sheen, dark_luma, hair_rows=36, share=0.07):
    # Hair = dark pixels in the top rows, away from skin and the background.
    # Reddish ones there are noise (back to the hair colour); the brightest
    # few in the source become the sheen, so every frame gets a similar one.
    px, spx = img.load(), src.load()
    top = img.getbbox()[1]
    hair, reds = [], []
    for y in range(max(top, 1), min(top + hair_rows, img.height - 1)):
        for x in range(1, img.width - 1):
            c = px[x, y]
            if not c[3] or luma(c) >= dark_luma:
                continue
            around = [px[x + dx, y + dy] for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
            if any(not a[3] or (luma(a) >= dark_luma and a[0] > a[2]) for a in around):
                continue
            if c[0] > c[2]:
                if sum(_is_dark(a, dark_luma, False) for a in around) < 3:
                    continue
                reds.append((x, y))
            hair.append((x, y))
    if not hair:
        return
    base = Counter(px[x, y] for x, y in hair if (x, y) not in reds).most_common(1)[0][0]
    for x, y in reds:
        px[x, y] = base
    hair.sort(key=lambda p: luma(spx[p]), reverse=True)
    for x, y in hair[:int(len(hair) * share)]:
        px[x, y] = sheen + (255,)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--colors", type=int, default=40)
    parser.add_argument("--dark-luma", type=float, default=70)
    parser.add_argument("--sheen", default="2c4058")
    args = parser.parse_args()
    sheen = tuple(int(args.sheen.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)) if args.sheen else None
    clean(Image.open(args.input), args.colors, args.dark_luma, sheen=sheen).save(args.output)


if __name__ == "__main__":
    main()
