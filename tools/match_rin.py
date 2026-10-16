#!/usr/bin/env python3
"""Bring Bảo's and Vy's sheets to Rin's proportions (Rin is the reference):
head 13 rows (chin / neck line on row 12), crotch on row 25, shins 25-29,
feet 30-31, face about as wide as Rin's.
Per frame: drop the shin rows CUT (what is above moves down 2), then paint
the bigger hand-made head of that facing over rows 0..12 at the frame's bob
offset (found by matching the old standing head). The body keeps its pixels.
Run once on the sheets from git 9fbf6ac (it is not idempotent), then
tools/make_idle.py (BLINK / WAIST are already set for the new heads).
Usage: python3 tools/match_rin.py [name ...]   (default: bao vy)
"""
import os
import sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "characters")
CUT = (26, 27)     # shin rows dropped
OLD_HEAD = 11      # rows of the old head used to find the bob offset
HEAD = 13

LEGEND = {
    "bao": {"A": "151d28", "B": "202e37", "C": "394a50", "S": "d7b594", "O": "4d2b32",
            "R": "7a4841", "T": "c09473", "W": "e7d5b3", "M": "ad7757", "J": "de9e41"},
    "vy": {"A": "151d28", "B": "202e37", "C": "394a50", "D": "73bed3", "E": "d7b594",
           "F": "e7d5b3", "G": "ebede9", "H": "e8c170", "I": "752438", "K": "564432"},
}

# Heads per sheet row (0 down, 1 up, 2 left; busy row 3 uses 0), 16x13.
HEADS = {
    "bao": {
        0: [
            "....AAAAAAA.....",
            "..AABBBBBBBAA...",
            "..ABBBBBBBBBA...",
            ".ABBCBBBBBCBBA..",
            ".ABBBBBBBBBBBA..",
            ".AAAABAAABAAAA..",
            ".AASSSSSSSSSAA..",
            ".OASAASSSAASAR..",
            ".OTSWRSSSRWSTR..",
            "..OSSSSSSSSSO...",
            "..OTSSSMSSSTO...",
            "...OTSSSSSTO....",
            "..OJRTSSSTRJO...",
        ],
        1: [
            ".....AAAAAA.....",
            "....AABBBBAA....",
            "...ABBBBBBBBA...",
            "..ABBBBBBBBBBA..",
            "..ABBCBBBBCBBA..",
            "..ABBBCBBCBBBA..",
            "..AAAAAAAAAAAA..",
            "..OAAAAAAAAAAO..",
            "..OMAAAAAAAAMR..",
            "...OAAAAAAAAO...",
            "...OAAAAAAAAO...",
            "....OAAAAAAO....",
            "...OSMRRRRMWO...",
        ],
        2: [
            ".....AAAAAA.....",
            "...AABBBBBBAA...",
            "..ABBBBBBBBBBA..",
            "..ABBCBBBBBCBA..",
            "..AAABAAAAAAAA..",
            "..OSSSSAAAAAAA..",
            "..RAWSSSAMSAAA..",
            ".RSSSSSSSSMAAA..",
            "..RSSSSSSSMAAA..",
            "..RSSSSSSSSAA...",
            "..OSSSSSTRRA....",
            "...OSSSSTRA.....",
            "....OORRWSO.....",
        ],
    },
    "vy": {
        0: [
            "......AAAA......",
            ".....ABCBAA.....",
            "....AABCCBBA.AA.",
            "...AAAABCCCDABA.",
            "..ABBAAABCCCCCA.",
            "..ACBAAEAAABBAA.",
            ".ACAAEFFFFEAABA.",
            ".ABAFAAFFAAFAAA.",
            ".ABAFGBFFBGFAA..",
            "..AFFFFFFFFFFA..",
            "..AAFFFEEFFFAA..",
            "..ABAEFFFFEABA..",
            "..AAHAAEEAAHA...",
        ],
        1: [
            "......AAAA......",
            ".....ABCBAA.....",
            "....AABCCBBA.AA.",
            "...ADBBCCCBBABA.",
            "..ABBBBBCCCBBBA.",
            "..ABBBBBCCCBBBA.",
            "..ABBCBBBCBBBAA.",
            "..ABBCBBBCBBBA..",
            ".ABBBCBBBCBBBA..",
            ".ABBBCBBBCBBBA..",
            ".ABBCBBBCBBBAA..",
            "..ABCBBBCBBBBA..",
            "...AHBCBBCBHA...",
        ],
        2: [
            "....BBBBBB......",
            "...BBBBBBBA.....",
            "..BBBBCCBBBB....",
            "..BBBBCCBBBB....",
            ".BBCCCBBDBBAB...",
            ".BCBBBBBCBCBA...",
            "BBBAEEEBBCBCA...",
            ".BAEAAAEBBBBA...",
            "..AFFAGAEBBBA...",
            ".KFFFBGEABBBA...",
            "..KFFFFEACBBA...",
            "..KFFFFEACBBA...",
            "..KEFFFFACCBA...",
        ],
    },
}


def rgba(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def head_image(name, row):
    rows = HEADS[name][row]
    assert len(rows) == HEAD and all(len(r) == 16 for r in rows), (name, row)
    im = Image.new("RGBA", (16, HEAD))
    for y, line in enumerate(rows):
        for x, ch in enumerate(line):
            if ch != ".":
                im.putpixel((x, y), rgba(LEGEND[name][ch]))
    return im


def bob(frame, still):
    """(dx, dy) where the still's old head sits in this frame."""
    best = None
    for dy in range(-1, 3):
        for dx in range(-2, 3):
            bad = 0
            for y in range(OLD_HEAD):
                for x in range(16):
                    a = still.getpixel((x, y))
                    xx, yy = x + dx, y + dy
                    b = frame.getpixel((xx, yy)) if 0 <= xx < 16 and 0 <= yy < 32 else (0, 0, 0, 0)
                    if (a[3] > 0) != (b[3] > 0) or (a[3] > 0 and a != b):
                        bad += 1
            if best is None or bad < best[0]:
                best = (bad, dx, dy)
    return best[1], best[2]


def convert(frame, head, dx, dy):
    keep = [y for y in range(32) if y not in CUT]
    out = Image.new("RGBA", (16, 32))
    for i, y in enumerate(keep):
        out.paste(frame.crop((0, y, 16, y + 1)), (0, 32 - len(keep) + i))
    out.paste(Image.new("RGBA", (16, HEAD + max(dy, 0))), (0, 0))  # old head gone
    out.paste(head, (dx, dy), head)
    return out


def main(name):
    path = os.path.join(ROOT, name + ".png")
    sheet = Image.open(path).convert("RGBA")
    out = Image.new("RGBA", sheet.size)
    for row in range(sheet.height // 32):
        facing = row if row < 3 else 0
        head = head_image(name, facing)
        still = sheet.crop((0, row * 32, 16, row * 32 + 32))
        for col in range(sheet.width // 16):
            frame = sheet.crop((col * 16, row * 32, col * 16 + 16, row * 32 + 32))
            dx, dy = bob(frame, still)
            out.paste(convert(frame, head, dx, dy), (col * 16, row * 32))
    out.save(path)


if __name__ == "__main__":
    for n in sys.argv[1:] or ["bao", "vy"]:
        main(n)
