#!/usr/bin/env python3
"""Author four grill sprites directly on their 60x32 destination pixel grid.

Imagegen concepts remain in tmp/imagegen/grill_native; these silhouettes and
clusters are intentionally redrawn, never shrunk from an oversized image.
Run without --install for a non-destructive preview. Existing runtime files
must be backed up before explicitly installing a revision.
"""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = (60, 32)
NAVY = '#172038'


def sprite():
    image = Image.new('RGBA', SIZE)
    return image, ImageDraw.Draw(image)


def mackerel():
    image, d = sprite()
    dark, back, silver, belly, light = '#394a50', '#577277', '#819796', '#c7cfcc', '#ebede9'
    # Forked tail, slender body, dorsal and ventral fins.
    d.polygon([(4,7),(10,10),(15,14),(15,18),(10,22),(4,25),(7,18),(8,16),(7,14)], fill=back, outline=NAVY)
    d.line([(5,9),(10,15),(13,16),(9,18),(5,23)], fill=dark)
    d.polygon([(24,10),(29,5),(31,10),(37,9),(39,6),(41,11)], fill=back, outline=NAVY)
    d.polygon([(29,22),(34,26),(35,22),(43,21),(46,24),(46,20)], fill=silver, outline=NAVY)
    d.polygon([(13,14),(20,11),(28,10),(41,10),(50,12),(56,15),(57,17),(53,20),(45,22),(29,23),(20,21),(13,18)], fill=silver, outline=NAVY)
    d.polygon([(15,15),(23,12),(41,11),(49,13),(53,15),(43,15),(34,14),(24,15)], fill=back)
    d.polygon([(18,18),(28,19),(43,18),(53,17),(54,18),(50,20),(43,21),(29,22),(21,20)], fill=belly)
    d.line([(26,20),(41,20),(46,19)], fill=light)
    for x in [23,29,35,41]:
        d.line([(x,12),(x+1,14),(x+3,15)], fill=dark)
    d.line([(47,13),(45,15),(45,17),(48,19)], fill=dark)
    d.polygon([(38,16),(43,17),(40,19)], fill=dark)
    d.point((51,15), fill=light)
    d.point((52,15), fill=NAVY)
    d.line([(54,17),(56,17)], fill=dark)
    return image


def shrimp():
    image, d = sprite()
    dark, blue, silver, pale, light = '#394a50', '#577277', '#819796', '#c7cfcc', '#ebede9'
    # Tail fan left, segmented abdomen arches into the head at right.
    d.polygon([(9,20),(4,18),(3,21),(6,24),(3,26),(6,28),(12,25),(15,22)], fill=blue, outline=NAVY)
    d.line([(5,21),(11,23),(6,26)], fill=silver)
    segments = [([(11,15),(14,12),(19,13),(20,18),(17,23),(12,24),(9,21)], pale),
                ([(16,10),(21,8),(26,10),(26,16),(22,20),(17,19),(16,15)], silver),
                ([(23,7),(29,7),(33,10),(32,16),(27,17),(23,14)], pale),
                ([(30,8),(36,9),(39,13),(36,19),(31,18),(30,14)], silver)]
    for points, color in segments:
        d.polygon(points, fill=color, outline=NAVY)
    d.line([(13,15),(16,14),(17,16)], fill=light)
    d.line([(19,11),(22,10),(24,12)], fill=light)
    d.line([(26,9),(28,9),(30,11)], fill=light)
    d.line([(33,11),(35,12),(36,14)], fill=light)
    d.polygon([(36,11),(40,11),(44,14),(48,17),(54,18),(48,20),(44,23),(38,22),(35,18)], fill=pale, outline=NAVY)
    d.polygon([(39,13),(43,14),(46,17),(40,17),(38,19)], fill=silver)
    d.point((45,17), fill=NAVY)
    d.line([(48,18),(51,15),(55,13),(57,13)], fill=NAVY)
    d.line([(48,19),(52,21),(56,21),(57,23)], fill=NAVY)
    for x, y in [(22,20),(28,18),(34,20),(39,23),(44,23)]:
        d.line([(x,y),(x-1,y+3),(x+2,y+5)], fill=dark)
    return image


def squid():
    image, d = sprite()
    dark, silver, pale, light, warm = '#394a50', '#819796', '#c7cfcc', '#ebede9', '#d7b594'
    # Mantle left, two fins, eye and sparse non-overlapping tentacles right.
    d.polygon([(6,14),(7,7),(15,10),(18,16),(14,22),(7,25),(6,18)], fill=silver, outline=NAVY)
    d.polygon([(5,15),(11,11),(23,10),(31,12),(35,16),(32,21),(22,23),(12,21),(5,18)], fill=pale, outline=NAVY)
    d.polygon([(9,15),(14,12),(25,12),(30,14),(15,14)], fill=light)
    d.line([(10,19),(19,21),(27,20),(31,18)], fill=silver)
    d.polygon([(32,14),(37,13),(41,15),(42,19),(39,22),(34,21),(31,18)], fill=pale, outline=NAVY)
    d.rectangle((36,15,38,18), fill=dark)
    d.point((37,15), fill=light)
    tentacles = [[(40,15),(46,12),(51,12),(53,10),(54,8)],
                 [(41,17),(47,16),(52,17),(55,15),(56,12)],
                 [(41,19),(46,21),(50,22),(54,21),(56,19)],
                 [(39,21),(43,25),(48,26),(52,25),(53,24)]]
    for line in tentacles:
        d.line(line, fill=NAVY, width=3)
        d.line(line, fill=pale, width=1)
    d.line([(42,19),(46,19),(49,20)], fill=warm)
    return image


def snails():
    image, d = sprite()
    brown, mid, tan, cream, light = '#7a4841', '#ad7757', '#d7b594', '#e7d5b3', '#ebede9'
    # Three separate shells, a shared recipe portion rather than a sprite sheet.
    for ox, oy in [(2,12),(21,5),(40,12)]:
        p = lambda points: [(ox+x,oy+y) for x,y in points]
        d.polygon(p([(1,8),(5,5),(8,1),(10,0),(13,3),(15,7),(16,11),(14,15),(9,17),(4,15),(1,12)]), fill=cream, outline=NAVY)
        d.polygon(p([(2,10),(6,12),(11,12),(15,9),(15,13),(12,16),(7,16),(3,14)]), fill=tan)
        d.polygon(p([(11,11),(14,11),(14,14),(12,15),(10,14)]), fill=NAVY)
        d.rectangle((ox+4,oy+8,ox+6,oy+10), fill=brown)
        d.rectangle((ox+8,oy+10,ox+9,oy+12), fill=mid)
        d.rectangle((ox+10,oy+7,ox+12,oy+8), fill=brown)
        d.rectangle((ox+9,oy+2,ox+10,oy+3), fill=mid)
        d.rectangle((ox+5,oy+5,ox+6,oy+6), fill=brown)
        d.rectangle((ox+12,oy+5,ox+13,oy+7), fill=mid)
        d.rectangle((ox+3,oy+11,ox+4,oy+12), fill=brown)
        d.line(p([(6,3),(8,2)]), fill=light)
        d.point((ox+3,oy+8), fill=light)
    return image


def check(name, image):
    assert image.size == SIZE
    colors = {pixel[:3] for pixel in image.getdata() if pixel[3]}
    assert len(colors) <= 6, (name, len(colors))
    assert {pixel[3] for pixel in image.getdata()} == {0,255}
    assert all(image.getpixel(pos)[3] == 0 for pos in [(0,0),(59,0),(0,31),(59,31)])
    palette = {line.strip().lower() for line in (ROOT/'assets/palette/xom_den.hex').read_text().splitlines()}
    assert all(''.join(f'{c:02x}' for c in color) in palette for color in colors)
    print(f'{name}: {image.size}, {len(colors)} colors, binary alpha, transparent corners, Xom Den palette')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--install', action='store_true')
    args = parser.parse_args()
    dest = ROOT / ('assets/sprites/grill' if args.install else 'tmp/imagegen/grill_native/native')
    dest.mkdir(parents=True, exist_ok=True)
    images = {'ca_thu':mackerel(), 'tom':shrimp(), 'muc':squid(), 'oc_huong':snails()}
    for index, (name,image) in enumerate(images.items()):
        check(name,image)
        path = dest / f'{name}.png'
        if args.install and path.exists():
            raise SystemExit(f'Refusing overwrite: back up {path} before installing a revision')
        image.save(path)
    sheet = Image.new('RGBA',(480,256),'#253a5e')
    draw = ImageDraw.Draw(sheet)
    for index,(name,image) in enumerate(images.items()):
        x,y=(index%2)*240,(index//2)*128
        sheet.alpha_composite(image.resize((240,128),Image.Resampling.NEAREST),(x,y))
        draw.text((x+4,y+4),name,fill='#ebede9')
    sheet.save(ROOT/'tmp/imagegen/grill_native/preview_4x.png')

if __name__ == '__main__':
    main()
