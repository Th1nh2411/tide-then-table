#!/usr/bin/env python3
"""Turn PixelLab downloads into the files the game loads (see ART_PLAN.md).

  # character: PixelLab zip (or its unzipped folder) -> 4-column sheet
  tools/pixellab_import.py character rin.zip rin --walk walking-4-frames
  # any single image (portrait, seafood, dish, prop)
  tools/pixellab_import.py image rin_face.png portraits/rin --size 64x64 --max-colors 16

character: the zip holds rotations/<dir>.png and animations/<anim>/<dir>/
*.png. Sheet rows: 1 walk down (south), 2 walk up (north), 3 walk left
(west; the game mirrors it for right), 4 busy (only with --busy). Each row is
4 frames picked evenly from the animation (a missing animation falls back to
the still rotation). One bounding box for every frame (no jitter), shrunk
into 16x32 frames with the feet on the bottom edge.

Both: colours forced to the "Xom Den" palette (tools/pixelize.py), at most
--max-colors colours, transparent background, written to
assets/sprites/<name>.png, an x8 preview in build/pixelize/.
"""
import argparse
import glob
import os
import sys
import tempfile
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixelize import (DEFAULT_PALETTE, ROOT, Image, limit_colours, load_palette,  # noqa: E402
                      pixelize, remove_background)

SPRITES = os.path.join(ROOT, "assets", "sprites")
COLUMNS = 4
ROWS = ["south", "north", "west"]


def unpack(src):
    if os.path.isdir(src):
        return src
    out = tempfile.mkdtemp(prefix="pixellab_")
    zipfile.ZipFile(src).extractall(out)
    return out


def find_dir(base, *parts):
    """Case-insensitive lookup of base/parts..., also one folder deeper (zip wrappers)."""
    for root in [base] + sorted(glob.glob(os.path.join(base, "*/"))):
        path = root
        for part in parts:
            names = {n.lower(): n for n in os.listdir(path)} if os.path.isdir(path) else {}
            if part.lower() not in names:
                path = None
                break
            path = os.path.join(path, names[part.lower()])
        if path:
            return path
    return None


def rotation(base, direction):
    folder = find_dir(base, "rotations")
    path = os.path.join(folder, direction + ".png") if folder else None
    if not path or not os.path.exists(path):
        sys.exit("missing rotations/%s.png in %s" % (direction, base))
    return Image.open(path).convert("RGBA")


def anim_frames(base, anim, direction):
    """4 frames picked evenly from animations/<anim>/<direction>/, or None."""
    folder = find_dir(base, "animations", anim, direction) if anim else None
    if not folder:
        return None
    paths = sorted(glob.glob(os.path.join(folder, "*.png")))
    if not paths:
        return None
    picks = [paths[i * len(paths) // COLUMNS] for i in range(COLUMNS)]
    return [Image.open(p).convert("RGBA") for p in picks]


def list_anims(base):
    folder = find_dir(base, "animations")
    return sorted(os.listdir(folder)) if folder else []


def union_bbox(frames):
    boxes = [f.getbbox() for f in frames if f.getbbox()]
    return (min(b[0] for b in boxes), min(b[1] for b in boxes),
            max(b[2] for b in boxes), max(b[3] for b in boxes))


def build_character(args, palette):
    base = unpack(args.src)
    rows = []
    for direction in ROWS:
        frames = anim_frames(base, args.walk, direction)
        if frames is None:
            print("no '%s' frames for %s (animations: %s), using the still pose"
                  % (args.walk, direction, ", ".join(list_anims(base)) or "none"))
            frames = [rotation(base, direction)] * COLUMNS
        rows.append(frames)
    if args.busy:
        frames = anim_frames(base, args.busy, "south")
        if frames is None:
            sys.exit("no '%s' frames for south (animations: %s)" % (args.busy, ", ".join(list_anims(base))))
        rows.append(frames)
    fw, fh = (int(v) for v in args.frame.lower().split("x"))
    box = union_bbox([f for row in rows for f in row])
    sheet = Image.new("RGBA", (fw * COLUMNS, fh * len(rows)), (0, 0, 0, 0))
    for r, row in enumerate(rows):
        for c, frame in enumerate(row):
            sheet.paste(pixelize(frame.crop(box), (fw, fh), palette), (c * fw, r * fh))
    return sheet


def build_image(args, palette):
    img = Image.open(args.src).convert("RGBA")
    if args.remove_bg:
        img = remove_background(img, 40)
    if img.getbbox():
        img = img.crop(img.getbbox())
    size = tuple(int(v) for v in args.size.lower().split("x"))
    if img.width <= size[0] and img.height <= size[1]:
        # already pixel art at the right scale: map colours 1:1, no resampling
        out = Image.new("RGBA", size, (0, 0, 0, 0))
        out.paste(pixelize(img, img.size, palette), ((size[0] - img.width) // 2, size[1] - img.height))
    else:
        out = pixelize(img, size, palette)  # bottom-centred
    box = out.getbbox()
    if args.center and box:
        centred = Image.new("RGBA", out.size, (0, 0, 0, 0))
        centred.paste(out.crop(box), (box[0], (out.height - (box[3] - box[1])) // 2))
        out = centred
    return out


def save(out, name):
    path = os.path.join(SPRITES, name + ".png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out.save(path)
    preview_dir = os.path.join(ROOT, "build", "pixelize")
    os.makedirs(preview_dir, exist_ok=True)
    open(os.path.join(ROOT, "build", ".gdignore"), "a").close()
    preview = os.path.join(preview_dir, name.replace("/", "_") + ".preview.png")
    out.resize((out.width * 8, out.height * 8), Image.NEAREST).save(preview)
    used = len({c for c in out.getdata() if c[3] > 0})
    print("-> %s (%dx%d, %d colours) + %s" % (os.path.relpath(path, ROOT), out.width, out.height, used,
                                             os.path.relpath(preview, ROOT)))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--palette", default=DEFAULT_PALETTE)
    sub = parser.add_subparsers(dest="kind", required=True)
    ch = sub.add_parser("character", help="PixelLab character zip/folder -> sheet")
    ch.add_argument("src")
    ch.add_argument("name", help="e.g. rin -> assets/sprites/characters/rin.png")
    ch.add_argument("--walk", default="", help="walk animation folder name (default: the first one)")
    ch.add_argument("--busy", default="", help="animation for the optional 4th row (south)")
    ch.add_argument("--frame", default="16x32")
    ch.add_argument("--max-colors", type=int, default=10)
    im = sub.add_parser("image", help="one PNG -> sprite")
    im.add_argument("src")
    im.add_argument("name", help="path under assets/sprites without .png, e.g. fish/muc")
    im.add_argument("--size", required=True, help="WxH")
    im.add_argument("--max-colors", type=int, default=16)
    im.add_argument("--remove-bg", action="store_true", help="also remove a flat background")
    im.add_argument("--center", action="store_true",
                    help="centre vertically (seafood, dishes) instead of sitting on the bottom edge")
    args = parser.parse_args()
    palette = load_palette(args.palette)
    if args.kind == "character":
        if not args.walk:
            anims = list_anims(unpack(args.src))
            args.walk = anims[0] if anims else ""
        out, name = build_character(args, palette), "characters/" + args.name
    else:
        out, name = build_image(args, palette), args.name
    if args.max_colors > 0:
        out = limit_colours(out, args.max_colors)
    save(out, name)


if __name__ == "__main__":
    main()
