#!/usr/bin/env python3
"""Native 16x32 Cô Năm: down/up/left walk + front-facing wave.

Brief: youthful Vietnamese grocery seller, about 40, low dark bun with sparse
gray strands, green blouse, dark trousers, sandals; same head/waist landmarks
as existing characters. The imagegen concept in tmp/imagegen/co_nam_sprite/
is reference only: these pixels are drawn on the native grid, never resized
from that oversized concept. Protected Rin/Bảo/Vy sheets are never written.
Rebuild: python3 tools/make_co_nam.py; python3 tools/make_idle.py co_nam
"""
from datetime import datetime
from pathlib import Path
import shutil
from PIL import Image
from walk_frames import step, LEFT_LEG, RIGHT_LEG, LEFT_ARM, RIGHT_ARM

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/sprites/characters/co_nam.png"
PALETTE = {
    ".": (0, 0, 0, 0),
    "o": "172038", "h": "2c4058", "g": "819796",
    "s": "d7b594", "l": "e7d5b3", "d": "ad7757",
    "G": "25562e", "B": "468232", "L": "a8ca58", "f": "7a4841",
}

FRONT = [
    "................",
    ".....oooooo.....",
    "....ohhhhhho....",
    "...ohhghhhhho...",
    "...ohghhhhhho...",
    "..ohhhhhohhhoo..",
    "..ohhhlshhhhoh..",
    "..ohhlllllhhoho.",
    "..osloollolsoho.",
    "...sllllllls.ho.",
    "...oslllllsooo..",
    "....osldlso.....",
    ".....ossooo.....",
    "....oBssBBo.....",
    "...oBBlBBLBo....",
    "..oBBBGGBBBBo...",
    "..oBBBGGBBBBo...",
    "..ossBGGBBsso...",
    "..oslBGGBBlso...",
    "..oslBGGBBlso...",
    "...odBGGBBdo....",
    "....oBGGBBo.....",
    "....oBGGBBo.....",
    "....oGGGGGo.....",
    "....ohhhhoo.....",
    "....ohhohho.....",
    "....ohhohho.....",
    "....ohhohho.....",
    "....ohhohho.....",
    "....ossohso.....",
    "...offo.offo....",
    "...oooo.oooo....",
]
BACK = [
    "................",
    ".....oooooo.....",
    "....ohhhhhho....",
    "...ohhghhhhho...",
    "...ohghhhhhho...",
    "..ohhhhhhhhho...",
    "..ohhhhhhhhho...",
    "..ohhhghhhhho...",
    "..ohhhhhhhooo...",
    "...ohhhhhohho...",
    "...ohhhhhohho...",
    "....ohhhohho....",
    ".....oooooo.....",
    "....oBBBBBo.....",
    "...oBLBBBLBo....",
    "..oBBBBBBBBBo...",
    "..oBBBBBBBBBo...",
    "..ossBBBBBsso...",
    "..oslBBBBBlso...",
    "..oslBGBBBlso...",
    "...odBGBBBdo....",
    "....oBGBBBo.....",
    "....oBGBBBo.....",
    "....oGGGGGo.....",
] + FRONT[24:]
SIDE = [
    "................",
    ".....ooooo......",
    "....ohhhhho.....",
    "...ohghhhhho....",
    "...ohghhhhho....",
    "..ohhhhhhhhho...",
    "..olshhhhhhho...",
    "..ollohhhhhho...",
    ".osllohhhhhoho..",
    "..sllshhhhohho..",
    "..osldshhhohho..",
    "...ossshoooho...",
    "....osoo.ooo....",
    "....oBBBo.......",
    "...oBLBBBo......",
    "...oBBBBBo......",
    "...oBBGBBo......",
    "...oBssBBo......",
    "...oBslBBo......",
    "...oBslBBo......",
    "...oGsdBBo......",
    "....oGBBBo......",
    "....oGBBBo......",
    "....oGGGGo......",
    ".....ohho.......",
    ".....ohho.......",
    ".....ohho.......",
    ".....ohho.......",
    ".....ohho.......",
    ".....osso.......",
    "...offffo.......",
    "...oooooo.......",
]


def frame(rows):
    assert len(rows) == 32
    image = Image.new("RGBA", (16, 32))
    for y, line in enumerate(rows):
        assert len(line) == 16, (y, len(line), line)
        for x, code in enumerate(line):
            color = PALETTE[code]
            image.putpixel((x, y), tuple(bytes.fromhex(color)) + (255,) if isinstance(color, str) else color)
    return image


def side_step(other=False):
    rows = [list(row) for row in SIDE]
    # Native splayed legs: both feet remain separated through the stride.
    legs = [".....ohho.......", "....ohhoho......", "....oho.ohho....",
            "...ohho..ohho...", "...oho....oho...", "..osso....osso..",
            ".offfo....offfo.", ".ooooo....ooooo."]
    for y, row in enumerate(legs, 24):
        rows[y] = list(row)
    # Opposite arm swing reads separately from the two leg positions.
    for y in range(17, 21):
        rows[y][5] = "B"
        rows[y][7 if other else 4] = "s" if y < 20 else "d"
    if other:
        rows[30] = list("..offo.....offo.")
        rows[31] = list("................")
    return frame(rows)


def backup(path):
    if path.exists():
        folder = ROOT / "build/backups" / ("co_nam_" + datetime.now().strftime("%Y%m%d_%H%M%S_%f"))
        folder.mkdir(parents=True)
        shutil.copy2(path, folder / path.name)
        print("backup", folder / path.name)


def main():
    sheet = Image.new("RGBA", (64, 128))
    for row, pose in enumerate((FRONT, BACK)):
        idle = [[PALETTE[c] for c in line] for line in pose]
        # walk_frames operates on native color cells; encode after its shifts.
        for col, pixels in enumerate((idle, step(idle, LEFT_LEG, LEFT_ARM, RIGHT_ARM), idle,
                                     step(idle, RIGHT_LEG, RIGHT_ARM, LEFT_ARM))):
            encoded = Image.new("RGBA", (16, 32))
            for y, line in enumerate(pixels):
                for x, color in enumerate(line):
                    encoded.putpixel((x, y), tuple(bytes.fromhex(color)) + (255,) if isinstance(color, str) else color)
            sheet.paste(encoded, (col * 16, row * 32))
    for col, image in enumerate((frame(SIDE), side_step(), frame(SIDE), side_step(True))):
        sheet.paste(image, (col * 16, 64))
    for col in range(4):
        wave = frame(FRONT)
        # Right sleeve/arm is redrawn, a three-pixel palm moves up and down.
        for y in range(9, 21):
            for x in range(12, 16):
                wave.putpixel((x, y), (0, 0, 0, 0))
        dy = 0 if col % 2 == 0 else -1
        for x, y, code in [(12, 15, "B"), (12, 14, "B"), (13, 14, "s"),
                           (13, 13, "s"), (13, 12, "s"), (14, 11, "s"),
                           (13, 11, "l"), (14, 10, "s"), (13, 10, "l")]:
            wave.putpixel((x, y + dy), tuple(bytes.fromhex(PALETTE[code])) + (255,))
        sheet.paste(wave, (col * 16, 96))
    backup(DEST)
    backup(DEST.with_name("co_nam_idle.png"))
    sheet.save(DEST)
    preview = ROOT / "build/co_nam_sprite"
    preview.mkdir(parents=True, exist_ok=True)
    sheet.resize((384, 768), Image.Resampling.NEAREST).save(preview / "sheet_x6.png")
    print("wrote", DEST)


if __name__ == "__main__":
    main()
