#!/usr/bin/env python3
"""Turn an AI / painted image into a game-ready pixel sprite.

  tools/pixelize.py draft.png assets/sprites/portraits/rin.png --size 64x64

Steps: remove a flat background (colour of the corners, flood-filled from
the edges), trim to the content, shrink to fit --size keeping its shape
(bottom-centred, so feet / shoulders sit on the bottom edge), every pixel
becomes the most common palette colour of its block (assets/palette/
xom_den.hex), no half-transparent pixels. Also writes build/pixelize/
<name>.preview.png (x8, git-ignored) to look at. Then fix it by hand in
Aseprite.

Options:
  --size WxH        target size (default 64x64)
  --keep-bg         don't remove the background
  --bg-tolerance N  how close to the corner colour counts as background (40)
  --no-trim         keep the original framing
  --palette PATH    another .hex palette
  --max-colors N    at most N colours in the sprite (the rarest merge into the
                    nearest kept one). Guide: character 16x32 -> 10,
                    portrait 64x64 -> 16, seafood / dish 16x16 -> 6
"""
import argparse
import os
import sys
from collections import Counter, deque

try:
    from PIL import Image
except ImportError:
    sys.exit("Needs Pillow: python3 -m pip install Pillow")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_PALETTE = os.path.join(ROOT, "assets", "palette", "xom_den.hex")


def load_palette(path):
    colours = []
    for line in open(path):
        line = line.strip().lstrip("#")
        if len(line) == 6:
            colours.append(tuple(int(line[i:i + 2], 16) for i in (0, 2, 4)))
    return colours


def distance(a, b):
    # "redmean": cheap perceptual RGB distance.
    rm = (a[0] + b[0]) / 2
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db


def nearest(colour, palette, cache):
    key = (colour[0] >> 2, colour[1] >> 2, colour[2] >> 2)
    if key not in cache:
        cache[key] = min(range(len(palette)), key=lambda i: distance(colour, palette[i]))
    return cache[key]


def remove_background(img, tolerance):
    """Flood-fill from the edges over pixels close to the corners' colour."""
    w, h = img.size
    px = img.load()
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    opaque = [c for c in corners if c[3] > 0]
    if not opaque:
        return img  # already transparent
    bg = Counter(c[:3] for c in opaque).most_common(1)[0][0]
    limit = tolerance * tolerance * 9
    seen = bytearray(w * h)
    queue = deque((x, y) for x in range(w) for y in (0, h - 1))
    queue.extend((x, y) for y in range(h) for x in (0, w - 1))
    while queue:
        x, y = queue.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        c = px[x, y]
        if c[3] > 0 and distance(c[:3], bg) > limit:
            continue
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                queue.append((nx, ny))
    return img


def pixelize(img, size, palette):
    tw, th = size
    sw, sh = img.size
    scale = min(tw / sw, th / sh)
    fw, fh = max(1, round(sw * scale)), max(1, round(sh * scale))
    ox, oy = (tw - fw) // 2, th - fh  # bottom-centred
    out = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    src = img.load()
    dst = out.load()
    cache = {}
    for ty in range(fh):
        y0, y1 = int(ty * sh / fh), max(int((ty + 1) * sh / fh), int(ty * sh / fh) + 1)
        for tx in range(fw):
            x0, x1 = int(tx * sw / fw), max(int((tx + 1) * sw / fw), int(tx * sw / fw) + 1)
            votes = Counter()
            clear = 0
            for y in range(y0, y1):
                for x in range(x0, x1):
                    c = src[x, y]
                    if c[3] < 128:
                        clear += 1
                    else:
                        votes[nearest(c, palette, cache)] += 1
            if votes and sum(votes.values()) >= clear:
                dst[ox + tx, oy + ty] = palette[votes.most_common(1)[0][0]] + (255,)
    return out


def limit_colours(img, max_colours):
    """Keep the `max_colours` most used colours; the rest take the nearest kept one."""
    px = img.load()
    w, h = img.size
    counts = Counter(px[x, y][:3] for y in range(h) for x in range(w) if px[x, y][3] > 0)
    if len(counts) <= max_colours:
        return img
    kept = [c for c, _ in counts.most_common(max_colours)]
    remap = {c: min(kept, key=lambda k: distance(c, k)) for c in counts if c not in kept}
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] > 0 and c[:3] in remap:
                px[x, y] = remap[c[:3]] + (255,)
    return img


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--size", default="64x64")
    parser.add_argument("--keep-bg", action="store_true")
    parser.add_argument("--bg-tolerance", type=int, default=40)
    parser.add_argument("--no-trim", action="store_true")
    parser.add_argument("--palette", default=DEFAULT_PALETTE)
    parser.add_argument("--max-colors", type=int, default=0)
    args = parser.parse_args()
    size = tuple(int(v) for v in args.size.lower().split("x"))
    palette = load_palette(args.palette)
    img = Image.open(args.input).convert("RGBA")
    if not args.keep_bg:
        img = remove_background(img, args.bg_tolerance)
    if not args.no_trim and img.getbbox():
        img = img.crop(img.getbbox())
    out = pixelize(img, size, palette)
    if args.max_colors > 0:
        out = limit_colours(out, args.max_colors)
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    out.save(args.output)
    preview_dir = os.path.join(ROOT, "build", "pixelize")
    os.makedirs(preview_dir, exist_ok=True)
    open(os.path.join(ROOT, "build", ".gdignore"), "a").close()  # keep Godot from importing previews
    preview = os.path.join(preview_dir, os.path.splitext(os.path.basename(args.output))[0] + ".preview.png")
    out.resize((size[0] * 8, size[1] * 8), Image.NEAREST).save(preview)
    used = len({out.getpixel((x, y)) for x in range(size[0]) for y in range(size[1])} - {(0, 0, 0, 0)})
    print("%s -> %s (%dx%d, %d colours) + %s" % (args.input, args.output, size[0], size[1], used,
                                                 os.path.basename(preview)))


if __name__ == "__main__":
    main()
