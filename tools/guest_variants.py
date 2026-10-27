#!/usr/bin/env python3
"""Two original customer identities authored directly on native16x32 cells.

No approved guest PNG pixels are modified or copied. Four walk columns use
idle/step/passing/opposite-step; rows down/up/left/seated. Separate wait/eat
strips match Customer.busy_sprite_name. Install refuses existing PNGs.
"""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
PALETTES={
    'rich':dict(outline='#172038',hair='#090a14',shine='#2c4058',skin='#d7b594',shade='#c09473',shirt='#e8c170',shirt_dark='#be772b',detail='#752438',pants='#394a50',shoe='#ad7757'),
    'regular':dict(outline='#172038',hair='#394a50',shine='#819796',skin='#d7b594',shade='#c09473',shirt='#468232',shirt_dark='#25562e',detail='#819796',pants='#7a4841',shoe='#884b2b'),
}


def head(kind,direction,blink=False):
    c=PALETTES[kind]
    im=Image.new('RGBA',(16,15))
    d=ImageDraw.Draw(im)
    if direction=='up':
        d.polygon([(5,0),(10,0),(12,2),(13,5),(12,10),(10,13),(5,13),(3,11),(2,7),(3,2)],fill=c['outline'])
        d.polygon([(5,1),(10,1),(12,4),(12,9),(10,12),(5,12),(3,9),(3,4)],fill=c['hair'])
        d.line([(5,2),(9,2),(11,4)],fill=c['shine'])
        d.point((2,9),fill=c['skin'])
        d.point((13,9),fill=c['skin'])
        if kind=='regular':
            d.line([(3,6),(4,10),(6,11)],fill=c['shine'])
            d.line([(11,6),(11,10),(9,11)],fill=c['shine'])
    elif direction=='left':
        d.polygon([(5,0),(10,0),(12,2),(13,6),(11,11),(9,13),(4,13),(3,10),(1,8),(2,6),(2,3)],fill=c['outline'])
        d.polygon([(3,5),(9,4),(11,7),(10,11),(8,13),(4,12),(3,9),(2,8)],fill=c['shade'])
        d.polygon([(3,6),(7,5),(9,7),(8,10),(4,11),(3,9)],fill=c['skin'])
        d.polygon([(5,1),(10,1),(12,3),(12,7),(10,10),(8,8),(8,4),(5,4),(3,5),(2,4),(3,2)],fill=c['hair'])
        d.line([(5,2),(9,2)],fill=c['shine'])
        if kind=='regular':
            d.line([(9,5),(10,8)],fill=c['shine'])
            d.point((8,10),fill=c['shine'])
        else:
            d.line([(5,3),(8,3),(10,5)],fill=c['shine'])
        d.point((3,7),fill=c['outline'] if not blink else c['shade'])
        d.point((3,10),fill=c['shade'])
    else:
        d.polygon([(5,0),(10,0),(12,2),(13,5),(13,9),(11,12),(9,14),(6,14),(3,11),(2,8),(2,4),(3,2)],fill=c['outline'])
        d.rectangle((3,6,12,9),fill=c['shade'])
        d.polygon([(4,4),(11,4),(11,10),(9,13),(6,13),(4,10)],fill=c['skin'])
        d.line([(5,11),(6,12),(9,12),(10,11)],fill=c['shade'])
        if kind=='rich':
            d.polygon([(5,1),(10,1),(12,3),(12,7),(10,6),(10,4),(8,3),(5,5),(3,7),(3,3)],fill=c['hair'])
            d.line([(5,2),(8,2),(10,3)],fill=c['shine'])
            d.point((11,5),fill=c['shine'])
        else:
            d.polygon([(5,1),(10,1),(12,3),(12,7),(10,6),(10,4),(6,3),(4,5),(3,8),(3,3)],fill=c['hair'])
            d.line([(5,2),(9,2)],fill=c['shine'])
            d.line([(3,5),(3,8)],fill=c['shine'])
            d.line([(11,4),(12,6)],fill=c['shine'])
            d.point((5,5),fill=c['shade'])
        for x in (5,10):
            d.point((x,8),fill=c['outline'] if not blink else c['shade'])
        d.line([(7,11),(8,11)],fill=c['shade'])
    return im


def frame(kind,direction='down',step=0,seated=False,eating=False,phase=0):
    c=PALETTES[kind]
    im=Image.new('RGBA',(16,32))
    d=ImageDraw.Draw(im)
    if seated:
        d.polygon([(4,23),(7,23),(7,26),(5,28),(5,30),(2,30),(2,27)],fill=c['outline'])
        d.polygon([(9,23),(12,23),(14,27),(14,30),(11,30),(11,28),(9,26)],fill=c['outline'])
        d.rectangle((3,25,5,28),fill=c['pants'])
        d.rectangle((11,25,13,28),fill=c['pants'])
        d.line([(2,30),(5,30)],fill=c['shoe'])
        d.line([(11,30),(14,30)],fill=c['shoe'])
    elif direction=='left':
        if step:
            if step==1:
                legs=[(6,23),(9,23),(9,26),(12,28),(12,30),(9,30),(7,27),(5,29),(3,29),(3,27)]
                paths=[[(7,24),(7,26),(10,28)],[(6,26),(4,28)]]
                feet=[[(2,29),(5,29)],[(10,30),(13,30)]]
            else:
                legs=[(6,23),(10,23),(9,26),(11,28),(11,31),(8,31),(8,28),(5,27),(3,28),(2,27),(4,25)]
                paths=[[(8,24),(6,26),(4,26)],[(8,25),(9,28),(9,30)]]
                feet=[[(2,28),(4,28)],[(8,30),(11,30)]]
            d.polygon(legs,fill=c['outline'])
            for path in paths:d.line(path,fill=c['pants'],width=2)
            for path in feet:d.line(path,fill=c['shoe'])
        else:
            d.rectangle((6,23,10,30),fill=c['outline'])
            d.rectangle((7,24,9,28),fill=c['pants'])
            d.line([(5,30),(10,30)],fill=c['outline'],width=2)
            d.line([(5,30),(8,30)],fill=c['shoe'])
    else:
        for x,moving in [(5,step),(9,-step)]:
            end=30 if moving>=0 else 28
            d.rectangle((x,23,x+2,end+1),fill=c['outline'])
            d.rectangle((x+1,24,x+1,end-1),fill=c['pants'])
            d.line([(x,end),(x+2,end)],fill=c['shoe'])
    upper=Image.new('RGBA',(16,25))
    u=ImageDraw.Draw(upper)
    u.rectangle((6,12,9,15),fill=c['shade'])
    if direction=='left':
        u.polygon([(6,14),(10,14),(11,18),(10,23),(5,23),(4,18)],fill=c['outline'])
        u.rectangle((5,15,9,22),fill=c['shirt_dark'])
        u.line([(5,15),(5,20)],fill=c['shirt'])
        arm_x=5+(2 if step==1 else -1 if step==-1 else 0)
        u.rectangle((arm_x,17,arm_x+2,21),fill=c['outline'])
        u.rectangle((arm_x,17,arm_x+1,19),fill=c['shirt'])
        u.rectangle((arm_x,20,arm_x+1,21),fill=c['skin'])
        if kind=='rich':u.line([(5,16),(5,18)],fill=c['detail'])
    else:
        u.polygon([(4,14),(11,14),(13,17),(12,22),(10,24),(5,24),(3,21),(3,17)],fill=c['outline'])
        u.rectangle((4,15,11,22),fill=c['shirt'])
        u.line([(4,16),(4,22)],fill=c['shirt_dark'])
        u.line([(11,16),(11,22)],fill=c['shirt_dark'])
        u.line([(5,23),(10,23)],fill=c['shirt_dark'])
        if direction=='down':
            u.line([(5,15),(6,17),(7,16)],fill=c['shirt_dark'])
            u.line([(10,15),(9,17),(8,16)],fill=c['shirt_dark'])
            if kind=='rich':
                u.polygon([(7,16),(8,16),(9,20),(8,22),(7,21)],fill=c['detail'])
            else:
                u.line([(8,17),(8,21)],fill=c['shirt_dark'])
                u.line([(5,18),(6,18)],fill=c['shirt_dark'])
        for x,swing in [(3,step),(11,-step)]:
            y=18+swing
            u.rectangle((x,y-2,x+1,y+3),fill=c['outline'])
            u.rectangle((x,y-2,x+1,y),fill=c['shirt_dark'])
            u.rectangle((x,y+1,x+1,y+2),fill=c['skin'])
        if seated:
            u.line([(3,18),(4,21),(6,21)],fill=c['outline'],width=3)
            u.line([(4,20),(6,20)],fill=c['skin'],width=2)
            if eating:
                lift=[0,3,5,2][phase]
                u.line([(12,19),(11,22),(8,20-lift)],fill=c['outline'],width=3)
                u.line([(11,21),(8,20-lift)],fill=c['skin'],width=2)
                u.line([(8,19-lift),(6,16-lift)],fill=c['shoe'])
                u.line([(9,19-lift),(7,16-lift)],fill=c['shoe'])
            else:
                u.line([(12,18),(11,21),(9,21)],fill=c['outline'],width=3)
                u.line([(11,20),(9,20)],fill=c['skin'],width=2)
    upper.alpha_composite(head(kind,direction,blink=seated and phase==3))
    im.alpha_composite(upper,(0,1 if step else 0))
    return im


def assets(kind):
    walk=Image.new('RGBA',(64,128))
    wait=Image.new('RGBA',(64,32))
    eat=Image.new('RGBA',(64,32))
    for row,direction in enumerate(['down','up','left']):
        for col,step in enumerate([0,1,0,-1]):
            walk.alpha_composite(frame(kind,direction,step),(col*16,row*32))
    for col in range(4):
        waiting=frame(kind,seated=True,phase=col)
        wait.alpha_composite(waiting,(col*16,0))
        walk.alpha_composite(waiting,(col*16,96))
        eat.alpha_composite(frame(kind,seated=True,eating=True,phase=col),(col*16,0))
    return {'guest_'+kind:walk,'guest_'+kind+'_wait':wait,'guest_'+kind+'_eat':eat}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--install',action='store_true')
    args=parser.parse_args()
    draft=ROOT/'tmp/imagegen/guest_variants'
    draft.mkdir(parents=True,exist_ok=True)
    dest=ROOT/'assets/sprites/characters' if args.install else draft
    all_assets={**assets('rich'),**assets('regular')}
    palette={line.strip().lower() for line in (ROOT/'assets/palette/xom_den.hex').read_text().splitlines()}
    for name,im in all_assets.items():
        colors={p[:3] for p in im.getdata() if p[3]}
        assert len(colors)<=10,(name,len(colors))
        assert all(''.join(f'{channel:02x}' for channel in col) in palette for col in colors)
        assert {p[3] for p in im.getdata()}=={0,255}
        for row in range(im.height//32):
            for col in range(4):
                f=im.crop((col*16,row*32,col*16+16,row*32+32))
                assert f.getbbox() and all(f.getpixel(p)[3]==0 for p in [(0,0),(15,0),(0,31),(15,31)])
        path=dest/(name+'.png')
        if args.install and path.exists():raise SystemExit('Refusing active overwrite: '+str(path))
        im.save(path)
        print(f'{name}: {im.size}, {len(colors)} colors, binary alpha, transparent cell corners')
    preview=Image.new('RGBA',(768,1152),'#253a5e')
    for index,kind in enumerate(['rich','regular']):
        for row,suffix in [(0,''),(4,'_wait'),(5,'_eat')]:
            im=all_assets['guest_'+kind+suffix]
            preview.alpha_composite(im.resize((384,im.height*6),Image.Resampling.NEAREST),(index*384,row*192))
    preview.save(draft/'preview6x.png')

if __name__=='__main__':main()
