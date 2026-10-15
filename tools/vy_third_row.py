#!/usr/bin/env python3
"""Put the owner's thirdrow.aseprite (4 standing views, a ~5x upscaled
reference on white) into row 3 of Vy's sheet, recoloured to Vy.

Each figure is sampled back to its own 5 px grid (the figures sit on
different phases), recoloured by body region (head / top / arms + skirt /
legs / shoes) to the colours already in vy.png, then fitted to her 16x32
frame: skirt hem on row 22 like rows 1-2, shins stretched to rows 23-29,
sneakers on 30-31. The head starts on row 2 (hair is redrawn by hand).
Usage: python3 tools/vy_third_row.py <thirdrow.aseprite> <vy.png> [row=2]
"""
import struct
import sys
import zlib
from PIL import Image

PX = 5
WHITE = (255, 255, 255, 255)
HEM = 22  # skirt hem row of Vy's frames

# Source colours by role.
OUTLINE = {"600a37", "490833", "4e1c35", "4f1c35", "4d1d2e", "3b1628"}
HAIR = {"8e4a3e": "202e37", "6d3a42": "202e37", "6c3b3b": "202e37", "903c3c": "202e37",
        "b9834e": "394a50", "bc734b": "394a50", "d5b671": "394a50", "d3b16f": "394a50"}
EYES = {"e2ecff": "ebede9", "aab2c1": "ebede9", "004149": "151d28", "102d39": "151d28",
        "008891": "202e37", "205e72": "202e37"}
SKIN, SHADE = "e7d5b3", "d7b594"
# Per region: source colour -> Vy colour (rows of the source figure, hem = last row).
FACE = {"f8c49e": SKIN, "d36358": SHADE, "f799a5": SHADE, "7f2837": SHADE, "ad4d2f": SHADE}
TOP = {"f7be4f": "c65197", "f6b536": "c65197", "f99e48": "752438", "e14211": "752438",
       "e26124": "752438", "7f2837": "752438", "d36358": "752438", "f8c49e": SKIN, "ad4d2f": SHADE}
SKIRT = {"d36358": "ebede9", "ad4d2f": "c7cfcc", "7f2837": "151d28", "f8c49e": SKIN}
LEGS = {"f8c49e": SKIN, "ad4d2f": SHADE, "d36358": SHADE, "7f2837": "564432", "aab2c1": "ebede9"}


def read_aseprite(path):
    """First frame, first cel of an RGBA .aseprite (enough for this file)."""
    d = open(path, "rb").read()
    w, h, depth = struct.unpack("<HHH", d[8:14])
    assert depth == 32, "RGBA only"
    pos = 128 + 16
    out = Image.new("RGBA", (w, h))
    while pos < len(d):
        size, kind = struct.unpack("<IH", d[pos:pos + 6])
        if kind == 0x2005:
            x, y = struct.unpack("<hh", d[pos + 8:pos + 12])
            ctype = struct.unpack("<H", d[pos + 13:pos + 15])[0]
            cw, ch = struct.unpack("<HH", d[pos + 22:pos + 26])
            assert ctype == 2, "compressed image cel only"
            cel = Image.frombytes("RGBA", (cw, ch), zlib.decompress(d[pos + 26:pos + size]))
            out.paste(cel, (x, y))
            break
        pos += size
    return out


def figures(im):
    blank = [all(im.getpixel((x, y)) == WHITE for y in range(im.height)) for x in range(im.width)]
    spans, x = [], 0
    while x < im.width:
        if not blank[x]:
            s = x
            while x < im.width and not blank[x]:
                x += 1
            spans.append((s, x))
        x += 1
    return [sample(im.crop((a, 0, b, im.height))) for a, b in spans]


def phase(im, axis):
    counts = [0] * PX
    for y in range(im.height):
        for x in range(im.width):
            if axis == 0 and x and im.getpixel((x, y)) != im.getpixel((x - 1, y)):
                counts[x % PX] += 1
            if axis == 1 and y and im.getpixel((x, y)) != im.getpixel((x, y - 1)):
                counts[y % PX] += 1
    return counts.index(max(counts))


def sample(im):
    px, py = phase(im, 0), phase(im, 1)
    xs = range(px - PX if px else 0, im.width, PX)
    ys = range(py - PX if py else 0, im.height, PX)
    out = Image.new("RGBA", (len(xs), len(ys)))
    for j, y in enumerate(ys):
        for i, x in enumerate(xs):
            p = im.getpixel((min(max(x + 2, 0), im.width - 1), min(max(y + 2, 0), im.height - 1)))
            if p != WHITE:
                out.putpixel((i, j), p)
    return out.crop(out.getbbox())


def hexof(p):
    return "%02x%02x%02x" % p[:3]


def recolour(key, y, hem):
    """Vy colour for source colour `key` on source row y (hem = skirt hem row)."""
    if key in OUTLINE:
        return "151d28"
    if y <= hem - 9:  # head
        return HAIR.get(key) or EYES.get(key) or FACE.get(key, "202e37")
    table = TOP if y <= hem - 5 else SKIRT if y <= hem else LEGS
    # hair falling over the shoulders keeps hair colours
    return table.get(key) or HAIR.get(key) or EYES.get(key, "151d28")


def fit(fig):
    """Source figure -> 16x32 frame: hem on HEM, shins stretched, shoes 30-31."""
    rows = [fig.crop((0, y, fig.width, y + 1)) for y in range(fig.height)]
    hem = max(y for y in range(fig.height)
              if sum(fig.getpixel((x, y))[3] > 0 and hexof(fig.getpixel((x, y))) in OUTLINE
                     for x in range(fig.width)) >= fig.width // 2 and y < fig.height - 3)
    recoloured = []
    for y, r in enumerate(rows):
        line = Image.new("RGBA", r.size)
        for x in range(r.width):
            p = r.getpixel((x, 0))
            if p[3]:
                c = recolour(hexof(p), y, hem)
                line.putpixel((x, 0), tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,))
        recoloured.append(line)
    legs = recoloured[hem + 1:]
    shin, shoes = legs[:-2], legs[-2:]
    # rows HEM+1..29 are shins: repeat the plain skin row under the knee
    shin = shin[:2] + [shin[1]] * (29 - HEM - len(shin)) + shin[2:]
    sole = Image.new("RGBA", shoes[1].size)
    for x in range(sole.width):
        if shoes[1].getpixel((x, 0))[3]:
            sole.putpixel((x, 0), (0x15, 0x1d, 0x28, 255))
    stack = recoloured[:hem + 1] + shin + [shoes[0], sole]
    out = Image.new("RGBA", (16, 32))
    top = 32 - len(stack)
    left = (16 - fig.width) // 2
    for i, line in enumerate(stack):
        out.paste(line, (left, top + i))
    return out


def main(src, sheet_path, row="2"):
    frames = [fit(f) for f in figures(read_aseprite(src))]
    sheet = Image.open(sheet_path).convert("RGBA")
    r = int(row)
    if sheet.height < 32 * (r + 1):
        bigger = Image.new("RGBA", (64, 32 * (r + 1)))
        bigger.paste(sheet, (0, 0))
        sheet = bigger
    sheet.paste(Image.new("RGBA", (64, 32)), (0, 32 * r))
    for i, f in enumerate(frames[:4]):
        sheet.paste(f, (16 * i, 32 * r))
    sheet.save(sheet_path)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(*sys.argv[1:])
