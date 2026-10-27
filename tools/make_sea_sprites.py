#!/usr/bin/env python3
"""Draw the sea masters directly on their native grid; never resample sources.

AI concepts are retained in tmp/imagegen/sea_native. Every final cluster below
is placed explicitly at native resolution. Existing runtime files are backed up.
"""
from pathlib import Path
from datetime import datetime
from PIL import Image, ImageDraw
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/sprites/sea'
PAL = {'n': '#172038', 'd': '#4d2b32', 'b': '#7a4841', 'w': '#ad7757',
       'l': '#d7b594', 'c': '#e7d5b3', 'u': '#253a5e', 'v': '#3c5e8b',
       'a': '#4f8fba', 'h': '#f2d98a', 's': '#c09473', 'k': '#090a14',
       't': '#ebede9'}

def new(size):
    im = Image.new('RGBA', size)
    return im, ImageDraw.Draw(im)

def line(d, xy, c):
    d.line(xy, fill=PAL[c], width=1)

def rect(d, xy, c):
    d.rectangle(xy, fill=PAL[c])

def poly(d, xy, c):
    d.polygon(xy, fill=PAL[c])

def basket():
    im, d = new((32, 32))
    # Circular bamboo coracle; the broad rim surrounds an empty open deck.
    d.ellipse((1, 1, 30, 30), fill=PAL['n'])
    d.ellipse((2, 2, 29, 29), fill=PAL['b'])
    d.ellipse((3, 3, 28, 28), fill=PAL['l'])
    d.ellipse((5, 5, 26, 26), fill=PAL['b'])
    d.ellipse((6, 6, 25, 25), fill=PAL['d'])
    # Sparse rim bindings, not a noisy basket-weave texture.
    for x,y,dx,dy in [(9,3,0,2),(21,3,0,2),(3,10,2,0),(26,10,2,0),
                       (3,21,2,0),(26,21,2,0),(10,26,0,2),(21,26,0,2)]:
        line(d, [(x,y),(x+dx,y+dy)], 'w')
    rect(d,(5,14,26,17),'n')
    rect(d,(5,14,26,15),'w')
    line(d,[(6,14),(25,14)],'l')
    # Tiny forward tie cleat identifies +X on the otherwise round hull.
    rect(d,(27,14,29,17),'n')
    line(d,[(28,14),(28,16)],'l')
    return im

def rowboat():
    im,d = new((48,20))
    poly(d,[(2,3),(27,1),(37,3),(46,8),(46,11),(37,16),(27,18),(2,16),(1,14),(1,5)],'n')
    poly(d,[(3,4),(27,2),(37,4),(45,9),(45,10),(37,15),(27,17),(3,15),(2,13),(2,6)],'w')
    poly(d,[(5,6),(27,4),(36,6),(42,9),(42,10),(36,13),(27,15),(5,13)],'b')
    poly(d,[(6,7),(27,5),(35,7),(39,9),(39,10),(35,12),(27,14),(6,12)],'d')
    line(d,[(4,4),(26,2),(36,4)],'l')
    line(d,[(4,15),(27,17),(36,15)],'b')
    # Benches lie across the long axis; crew is rendered separately by Boat.
    for x in (12,28):
        rect(d,(x,4,x+2,15),'n')
        rect(d,(x,5,x+1,14),'w')
        line(d,[(x,5),(x,14)],'l')
    rect(d,(37,8,43,11),'w')
    line(d,[(38,8),(42,9)],'l')
    return im

def motorboat():
    im,d = new((60,24))
    # A compact outboard at the left stern; unmistakable upgrade silhouette.
    rect(d,(1,9,5,14),'n')
    rect(d,(2,10,5,12),'u')
    line(d,[(2,10),(4,10)],'a')
    poly(d,[(6,4),(36,1),(47,4),(58,10),(58,13),(47,19),(36,22),(6,19)],'n')
    poly(d,[(7,5),(36,2),(47,5),(57,11),(57,12),(47,18),(36,21),(7,18)],'v')
    poly(d,[(9,7),(36,4),(46,7),(53,11),(53,12),(46,16),(36,19),(9,16)],'n')
    poly(d,[(10,8),(36,5),(45,8),(50,11),(50,12),(45,15),(36,18),(10,15)],'b')
    poly(d,[(11,9),(36,6),(43,9),(47,11),(47,12),(43,14),(36,17),(11,14)],'d')
    line(d,[(8,5),(35,2),(46,5)],'a')
    line(d,[(8,18),(35,21),(46,18)],'u')
    for x in (17,35):
        rect(d,(x,6,x+3,17),'n')
        rect(d,(x,7,x+2,16),'w')
        line(d,[(x,7),(x,16)],'l')
    poly(d,[(46,8),(54,11),(54,12),(46,15)],'v')
    line(d,[(48,9),(52,11)],'a')
    return im

def rin():
    im,d = new((16,32))
    # Same relaxed tank-top identity as the protected gameplay sprite.
    rect(d,(4,19,11,24),'n')
    rect(d,(4,24,6,29),'s'); rect(d,(9,24,11,29),'s')
    rect(d,(3,29,6,30),'n'); rect(d,(9,29,12,30),'n')
    rect(d,(4,29,5,29),'b'); rect(d,(10,29,11,29),'b')
    poly(d,[(4,14),(11,14),(12,20),(11,22),(4,22),(3,20)],'n')
    poly(d,[(5,14),(10,14),(11,20),(10,21),(5,21),(4,20)],'t')
    rect(d,(3,15,4,20),'s'); rect(d,(11,15,12,20),'s')
    rect(d,(4,9,11,13),'n'); rect(d,(5,9,10,14),'s')
    rect(d,(6,14,9,15),'l')
    # A restrained face beneath the conical brim: black brows/glasses.
    rect(d,(4,10,6,12),'n'); rect(d,(9,10,11,12),'n')
    line(d,[(7,10),(8,10)],'n')
    rect(d,(5,11,5,11),'l'); rect(d,(10,11,10,11),'l')
    line(d,[(7,13),(8,13)],'b')
    # Native one-pixel stepped nón lá, no photo texture or radial stripes.
    poly(d,[(7,1),(8,1),(10,3),(10,4),(12,6),(14,8),(14,9),(1,9),(1,8),(3,6),(5,4),(5,3)],'n')
    poly(d,[(7,2),(8,2),(9,4),(11,6),(13,8),(2,8),(4,6),(6,4)],'h')
    line(d,[(3,8),(12,8)],'l')
    line(d,[(8,3),(10,6)],'l')
    return im

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    backup = ROOT / 'build/sea/backups' / datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    for name,im in [('thuyen_thung',basket()),('ghe_cheo',rowboat()),('ghe_may',motorboat()),('rin_boat',rin())]:
        path=OUT/f'{name}.png'
        if path.exists():
            backup.mkdir(parents=True,exist_ok=True)
            shutil.copy2(path,backup/path.name)
        im.save(path)
        print(path.relative_to(ROOT),im.size,'colours',len({p[:3] for p in im.getdata() if p[3]}))

if __name__ == '__main__':
    main()
