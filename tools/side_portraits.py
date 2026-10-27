#!/usr/bin/env python3
"""Draw two new side-character bases directly on the 128x128 pixel grid.

Imagegen concepts in tmp/imagegen/side_portraits are visual references only;
no generated image is sampled, resized, traced or quantized into these masters.
The protected approved portraits are read only in the comparison preview.
Faces point right; hands/lower torso remain below the upper-abdomen crop.
Re-running backs up active PNG bytes before replacing them.
"""
from datetime import datetime
from pathlib import Path
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTLINE = "#172038"


def portrait(elder):
    image = Image.new("RGBA", (128, 128))
    d = ImageDraw.Draw(image)
    skin, shade, light, deep = "#c09473", "#ad7757", "#d7b594", "#7a4841"
    hair = "#819796" if elder else "#202e37"
    hair_dark = "#577277" if elder else "#394a50"
    hair_light = "#c7cfcc" if elder else "#819796"
    shirt = "#7a4841" if elder else "#468232"
    shirt_dark = "#4d2b32" if elder else "#25562e"
    shirt_light = "#ad7757" if elder else "#577277"
    stage = "body"

    def coordinates(points):
        result = []
        for x, y in points:
            if stage == "body" and y > 55:
                # Shoulder start matches Rin's row 65; keep the abdomen crop.
                y -= round(7 * min((y - 55) / 20, (128 - y) / 53))
            elif stage == "face" and y > 43:
                y = 43 + round((y - 43) * 0.75)
            result.append((x, y))
        return result

    def p(points, fill, outline=None):
        d.polygon(coordinates(points), fill=fill, outline=outline)

    def line(points, color=OUTLINE, width=1):
        d.line(coordinates(points), fill=color, width=width)

    # Body crop reaches upper abdomen, with hanging upper arms at the sides.
    p([(51, 65), (68, 64), (88, 70), (99, 79), (106, 94), (110, 127),
       (19, 127), (22, 94), (24, 82), (33, 73)], shirt, OUTLINE)
    p([(33, 75), (25, 85), (22, 99), (23, 124), (28, 127), (40, 127),
       (38, 99), (40, 81)], shade, OUTLINE)
    p([(27, 87), (25, 101), (27, 116), (31, 127), (38, 127), (35, 107),
       (37, 91)], skin)
    p([(93, 79), (101, 87), (106, 107), (107, 127), (96, 127), (91, 105)], shade, OUTLINE)
    p([(98, 92), (103, 111), (104, 127), (98, 127), (95, 105)], skin)
    # Shirt sleeve silhouettes overlap upper arms, no cut-off hands.
    p([(33, 73), (45, 72), (44, 85), (40, 99), (24, 94), (25, 83)], shirt, OUTLINE)
    p([(87, 72), (96, 77), (103, 90), (103, 97), (92, 100), (86, 87)], shirt, OUTLINE)
    p([(35, 75), (40, 76), (36, 90), (28, 89)], shirt_light)
    p([(88, 77), (94, 81), (100, 92), (94, 94)], shirt_light)
    p([(45, 74), (55, 76), (69, 77), (85, 73), (89, 94), (94, 127),
       (40, 127), (42, 102)], shirt)
    p([(43, 99), (47, 104), (45, 127), (39, 127)], shirt_dark)
    p([(83, 88), (87, 95), (87, 114), (92, 127), (86, 127), (81, 109)], shirt_dark)
    # A few folds rather than a textured surface.
    line([(50, 109), (58, 111), (65, 110)], shirt_dark)
    line([(76, 119), (82, 117)], shirt_dark)
    line([(46, 122), (52, 121)], shirt_light)
    # Large connected cloth planes retain the reference's pixel illustration
    # treatment without introducing microtexture or a smooth gradient.
    p([(49, 87), (55, 91), (61, 90), (60, 94), (52, 96), (47, 94)], shirt_light)
    p([(71, 105), (79, 104), (83, 108), (79, 110), (72, 109)], shirt_dark)
    line([(47, 116), (57, 117), (62, 115)], shirt_dark)
    line([(73, 89), (81, 89), (82, 99), (73, 100), (73, 89)], shirt_dark)

    # Neck and simple open collar.
    p([(54, 55), (72, 53), (72, 64), (79, 70), (68, 82), (52, 73)], shade, OUTLINE)
    p([(60, 61), (69, 59), (68, 68), (74, 72), (66, 77), (56, 71)], skin)
    p([(49, 67), (55, 71), (65, 79), (59, 86), (45, 73)], shirt_dark, OUTLINE)
    p([(73, 65), (79, 69), (86, 73), (73, 83), (66, 79)], shirt_dark, OUTLINE)
    line([(74, 69), (80, 73), (73, 79)], shirt_light)
    line([(65, 82), (66, 100), (66, 127)], shirt_dark)
    for y in (94, 110, 125):
        d.point(coordinates([(69, y)])[0], fill=shirt_light)

    # Head is intentionally a different silhouette for the older fisherman.
    stage = "face"
    if elder:
        face = [(53, 19), (72, 15), (83, 20), (86, 30), (86, 38), (89, 43),
                (89, 45), (87, 47), (88, 53), (84, 60), (76, 64), (68, 63),
                (61, 59), (54, 47), (50, 32)]
    else:
        face = [(52, 19), (72, 14), (84, 20), (87, 30), (87, 38), (89, 42),
                (89, 44), (88, 46), (90, 52), (90, 57), (86, 62), (79, 65),
                (70, 65), (62, 61), (56, 53), (52, 43), (50, 32)]
    p(face, skin, OUTLINE)
    p([(77, 24), (82, 26), (83, 38), (88, 43), (85, 46), (86, 52),
       (82, 57), (76, 59), (71, 56), (72, 47), (69, 32)], skin)
    p([(79, 28), (82, 30), (82, 36), (80, 35)], light)
    p([(82, 41), (85, 42), (86, 46), (82, 47)], light)
    p([(55, 30), (62, 28), (61, 42), (65, 52), (74, 60), (81, 63),
       (73, 65), (62, 59), (55, 47)], shade)
    p([(53, 37), (58, 35), (62, 39), (62, 47), (57, 48), (52, 43)], skin, OUTLINE)
    line([(56, 39), (59, 39), (59, 44)], deep)

    # Hair: short combed gray hair / simple dark salt-and-pepper part.
    stage = "hair"
    p([(43, 28), (44, 20), (48, 13), (56, 9), (68, 8), (79, 10),
       (85, 14), (88, 23), (86, 30), (82, 29), (80, 22), (74, 20),
       (66, 24), (58, 26), (56, 34), (54, 39), (50, 37), (47, 33)], hair, OUTLINE)
    p([(45, 26), (48, 20), (56, 15), (68, 13), (79, 14), (83, 18),
       (74, 17), (67, 20), (57, 22), (53, 32), (50, 35)], hair_dark)
    p([(50, 16), (57, 12), (68, 11), (73, 12), (62, 13), (56, 16)], hair_light)
    if elder:
        line([(52, 21), (59, 18), (66, 17)], hair_light)
        line([(75, 13), (81, 16), (84, 20)], hair_light)
        p([(49, 29), (52, 26), (51, 35), (53, 38), (52, 40), (49, 37)], hair_dark)
    else:
        # Sparse temple gray communicates middle age without old-man wrinkles.
        line([(49, 27), (51, 24), (54, 23)], hair_light)
        line([(50, 30), (50, 34)], hair_light)

    # Far eye and near eye both look right; one warm closed-mouth smile.
    stage = "face"
    if elder:
        line([(64, 32), (68, 31), (71, 32)], "#394a50")
        line([(78, 31), (82, 31), (85, 33)], "#394a50")
    else:
        line([(63, 32), (67, 30), (71, 31)], "#394a50", 2)
        line([(78, 30), (82, 30), (85, 32)], "#394a50", 2)
    p([(64, 36), (67, 34), (71, 35), (71, 38), (66, 39)], "#e7d5b3")
    p([(78, 36), (81, 34), (85, 35), (85, 38), (80, 39)], "#e7d5b3")
    line([(64, 35), (67, 34), (70, 35)])
    line([(78, 35), (81, 34), (84, 35)])
    d.rectangle((68, 35, 69, 38), fill=OUTLINE)
    d.rectangle((82, 35, 83, 38), fill=OUTLINE)
    d.point((69, 35), fill="#e7d5b3")
    d.point((83, 35), fill="#e7d5b3")
    line([(78, 40), (78, 44), (81, 45)], shade)
    line([(85, 46), (87, 45)], deep)
    line([(78, 54), (82, 55), (87, 53)], deep)
    d.point(coordinates([(86, 52)])[0], fill=OUTLINE)
    if elder:
        # Weathered, kind: just two crow's-feet and a small gray moustache.
        line([(72, 27), (80, 27)], shade)
        line([(72, 29), (78, 29)], shade)
        line([(63, 40), (65, 41)], deep)
        line([(63, 43), (66, 44)], shade)
        line([(84, 41), (86, 42)], shade)
        p([(79, 50), (83, 48), (87, 49), (88, 51), (84, 50), (79, 52)], hair)
        line([(77, 58), (82, 59)], shade)
    else:
        line([(79, 57), (84, 58)], light)
    return image


def install(name, image):
    path = ROOT / "assets/sprites/portraits" / name / "base.png"
    if path.exists():
        backup = ROOT / "build/portraits/backups" / datetime.now().strftime("%Y%m%d_%H%M%S_%f") / name
        backup.mkdir(parents=True)
        shutil.copy2(path, backup / path.name)
        print("backup", backup / path.name)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print("wrote", path)


def main():
    out = ROOT / "build/side_portraits"
    out.mkdir(parents=True, exist_ok=True)
    reference = Image.open(ROOT / "assets/sprites/portraits/rin/base.png").convert("RGBA")
    preview = Image.new("RGBA", (384, 128))
    preview.paste(reference, (0, 0))
    for index, (name, elder) in enumerate((("ong_tam", True), ("khach_quen", False)), 1):
        image = portrait(elder)
        install(name, image)
        preview.paste(image, (128 * index, 0))
        image.resize((512, 512), Image.Resampling.NEAREST).save(out / (name + "_x4.png"))
    preview.save(out / "comparison_native.png")
    preview.resize((1536, 512), Image.Resampling.NEAREST).save(out / "comparison_x4.png")


if __name__ == "__main__":
    main()
