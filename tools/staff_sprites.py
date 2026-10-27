#!/usr/bin/env python3
"""Original shared helper, authored on a 16x32 grid (no source resizing).

Four columns: idle / step / passing / opposite step. Rows: down / up /
left / busy hands at apron. Right is mirrored by Art.draw_person. PNGs
already installed are protected; default output is a draft under tmp/.
"""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
COLORS = {
    'outline':'#172038', 'hair':'#090a14', 'shine':'#2c4058',
    'skin_dark':'#c09473', 'skin':'#d7b594', 'shirt':'#468232',
    'shirt_dark':'#25562e', 'apron':'#e7d5b3', 'pants':'#394a50',
    'shoe':'#ad7757',
}


def frame(direction, step=0, busy=False, phase=0):
    im=Image.new('RGBA',(16,32))
    d=ImageDraw.Draw(im)
    c=COLORS
    # Legs and sandals anchor each frame to the bottom of its cell.
    if direction == 'left':
        if step == 1:
            d.polygon([(6,23),(9,23),(9,26),(12,28),(12,30),(9,30),(7,27),(5,29),(3,29),(3,27)], fill=c['outline'])
            d.line([(7,24),(7,26),(10,28)],fill=c['pants'],width=2)
            d.line([(6,26),(4,28)],fill=c['pants'],width=2)
            d.line([(2,29),(5,29)],fill=c['shoe'])
            d.line([(10,30),(13,30)],fill=c['shoe'])
        elif step == -1:
            d.polygon([(6,23),(10,23),(9,26),(11,28),(11,31),(8,31),(8,28),(5,27),(3,28),(2,27),(4,25)],fill=c['outline'])
            d.line([(8,24),(6,26),(4,26)],fill=c['pants'],width=2)
            d.line([(8,25),(9,28),(9,30)],fill=c['pants'],width=2)
            d.line([(2,28),(4,28)],fill=c['shoe'])
            d.line([(8,30),(11,30)],fill=c['shoe'])
        else:
            d.rectangle((6,23,10,29),fill=c['outline'])
            d.rectangle((7,24,9,28),fill=c['pants'])
            d.line([(5,30),(10,30)],fill=c['outline'],width=2)
            d.line([(5,30),(8,30)],fill=c['shoe'])
    else:
        for x, moving in [(5,step),(9,-step)]:
            end=30 if moving >= 0 else 28
            d.rectangle((x,23,x+2,end),fill=c['outline'])
            d.rectangle((x+1,24,x+1,end-2),fill=c['pants'])
            d.line([(x,end),(x+2,end)],fill=c['shoe'])
            d.line([(x,end+1),(x+2,end+1)],fill=c['outline'])
    upper=Image.new('RGBA',(16,25))
    u=ImageDraw.Draw(upper)
    # Neck and torso: narrow body, cream apron with a single olive pocket.
    u.rectangle((6,12,9,15),fill=c['skin_dark'])
    if direction == 'left':
        u.polygon([(6,14),(10,14),(11,17),(10,23),(5,23),(4,18)],fill=c['outline'])
        u.rectangle((5,15,9,21),fill=c['shirt_dark'])
        u.rectangle((5,17,6,23),fill=c['apron'])
        # Foreground arm swings opposite the forward foot.
        arm_x=5 + (2 if step==1 else -1 if step==-1 else 0)
        u.rectangle((arm_x,17,arm_x+2,21),fill=c['outline'])
        u.rectangle((arm_x,17,arm_x+1,19),fill=c['shirt'])
        u.rectangle((arm_x,20,arm_x+1,21),fill=c['skin'])
    else:
        u.polygon([(4,14),(11,14),(13,17),(12,22),(10,24),(5,24),(3,21),(3,17)],fill=c['outline'])
        u.rectangle((4,15,11,21),fill=c['shirt'])
        u.line([(4,16),(4,21)],fill=c['shirt_dark'])
        u.line([(11,16),(11,21)],fill=c['shirt_dark'])
        if direction == 'up':
            u.line([(6,15),(9,19),(6,19),(9,15)],fill=c['apron'])
            u.line([(5,21),(10,21)],fill=c['apron'])
        else:
            u.rectangle((6,16,9,17),fill=c['apron'])
            u.rectangle((5,18,10,23),fill=c['apron'])
            u.line([(7,19),(8,19)],fill=c['shirt_dark'])
            u.line([(7,20),(8,20)],fill=c['shirt'])
        for x, swing in [(3,step),(11,-step)]:
            y=18+swing
            u.rectangle((x,y-2,x+1,y+3),fill=c['outline'])
            u.rectangle((x,y-2,x+1,y),fill=c['shirt_dark'])
            u.rectangle((x,y+1,x+1,y+2),fill=c['skin'])
        if busy:
            # Empty palms leave space for StreetProps.draw_plate at y=19.
            u.line([(3,18),(4,21),(6,20+phase)],fill=c['outline'],width=3)
            u.line([(12,18),(11,21),(9,20+phase)],fill=c['outline'],width=3)
            u.line([(4,20),(6,20+phase)],fill=c['skin'],width=2)
            u.line([(11,20),(9,20+phase)],fill=c['skin'],width=2)
    # Head landmark: hair at y0, chin y13, maximum width12 pixels.
    if direction == 'up':
        u.polygon([(5,0),(10,0),(12,2),(13,6),(12,11),(10,13),(5,13),(3,11),(2,6),(3,2)],fill=c['outline'])
        u.polygon([(5,1),(10,1),(12,4),(12,9),(10,12),(5,12),(3,9),(3,4)],fill=c['hair'])
        u.line([(5,2),(9,2),(11,4)],fill=c['shine'])
        u.point((2,9),fill=c['skin'])
        u.point((13,9),fill=c['skin'])
        u.line([(6,12),(9,12)],fill=c['shine'])
    elif direction == 'left':
        u.polygon([(5,0),(10,0),(12,2),(13,5),(12,10),(10,13),(5,13),(3,11),(3,9),(1,8),(2,6),(2,3)],fill=c['outline'])
        u.polygon([(4,5),(9,4),(11,7),(10,11),(8,13),(5,12),(3,10),(3,8),(2,8)],fill=c['skin_dark'])
        u.polygon([(3,6),(7,5),(9,7),(8,10),(5,11),(3,9)],fill=c['skin'])
        u.polygon([(5,1),(10,1),(12,3),(12,8),(10,11),(9,8),(7,7),(7,4),(5,5),(3,6),(2,5),(3,2)],fill=c['hair'])
        u.line([(5,2),(9,2)],fill=c['shine'])
        u.point((3,7),fill=c['outline'])
        u.line([(8,8),(9,8)],fill=c['skin'])
    else:
        u.polygon([(5,0),(10,0),(12,2),(13,5),(13,9),(11,12),(9,14),(6,14),(3,11),(2,9),(2,4),(3,2)],fill=c['outline'])
        u.rectangle((3,6,12,9),fill=c['skin_dark'])
        u.polygon([(4,4),(11,4),(11,10),(9,13),(6,13),(4,10)],fill=c['skin'])
        u.line([(5,11),(6,12),(9,12),(10,11)],fill=c['skin_dark'])
        u.polygon([(5,1),(10,1),(12,3),(12,7),(10,6),(9,4),(7,5),(6,4),(4,6),(3,8),(3,4)],fill=c['hair'])
        u.line([(5,2),(9,2)],fill=c['shine'])
        u.point((5,8),fill=c['outline'])
        u.point((10,8),fill=c['outline'])
        u.point((8,11),fill=c['skin_dark'])
    im.alpha_composite(upper,(0,1 if step else 0))
    return im


def make_sheet():
    sheet=Image.new('RGBA',(64,128))
    for row,direction in enumerate(['down','up','left']):
        for col,step in enumerate([0,1,0,-1]):
            sheet.alpha_composite(frame(direction,step),(col*16,row*32))
    for col in range(4):
        sheet.alpha_composite(frame('down',busy=True,phase=col%2),(col*16,96))
    return sheet


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--install',action='store_true')
    args=parser.parse_args()
    dest=ROOT/('assets/sprites/characters/staff.png' if args.install else 'tmp/imagegen/staff_native/staff.png')
    if args.install and dest.exists():
        raise SystemExit('Refusing to replace an active file; back it up explicitly first.')
    sheet=make_sheet()
    opaque={p[:3] for p in sheet.getdata() if p[3]}
    assert len(opaque)<=10
    palette={line.strip().lower() for line in (ROOT/'assets/palette/xom_den.hex').read_text().splitlines()}
    assert all(''.join(f'{channel:02x}' for channel in color) in palette for color in opaque)
    assert {p[3] for p in sheet.getdata()} == {0,255}
    for row in range(4):
        for col in range(4):
            f=sheet.crop((col*16,row*32,col*16+16,row*32+32))
            assert f.getbbox() and all(f.getpixel(pos)[3]==0 for pos in [(0,0),(15,0),(0,31),(15,31)])
    dest.parent.mkdir(parents=True,exist_ok=True)
    sheet.save(dest)
    preview=ROOT/'tmp/imagegen/staff_native/staff_preview6x.png'
    preview.parent.mkdir(parents=True,exist_ok=True)
    sheet.resize((384,768),Image.Resampling.NEAREST).save(preview)
    print(f'{dest}: 64x128, {len(opaque)} colors, binary alpha,16 nonempty native16x32 frames')

if __name__=='__main__':
    main()
