#!/usr/bin/env python3
"""Author cutscene-only native pixels from CutsceneActor's code fallback.

No image resampling or protected Rin-sheet changes. Glow intentionally uses
four stepped translucent rings: the luminous effect is this asset's purpose.
"""
from datetime import datetime
from pathlib import Path
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/sprites/characters'
C = {'n':'#172038','hair':'#090a14','hairlight':'#2c4058','skin':'#c09473',
     'light':'#d7b594','wood':'#ad7757','wooddark':'#7a4841','cream':'#ebede9',
     'blue':'#3c5e8b','bluelight':'#73bed3','red':'#cf573c','teal':'#5ff2e0',
     'white':'#e6f6ff','aqua':'#a4dddb'}

def blank(size):
    im = Image.new('RGBA',size)
    return im,ImageDraw.Draw(im)

def rect(d,xy,color):
    d.rectangle(xy,fill=C[color])

def line(d,xy,color):
    d.line(xy,fill=C[color],width=1)

def head(d,x,y):
    # Prone pose, head to the left. Hair and glasses retain Rin's identity.
    d.polygon([(x+2,y),(x+6,y),(x+8,y+2),(x+8,y+5),(x+6,y+7),
               (x+2,y+7),(x,y+5),(x,y+2)],fill=C['n'])
    rect(d,(x+1,y+2,x+7,y+5),'skin')
    rect(d,(x+2,y+6,x+5,y+6),'skin')
    d.polygon([(x+1,y+1),(x+2,y),(x+6,y),(x+7,y+1),(x+5,y+2),
               (x+4,y+1),(x+3,y+2),(x+1,y+2)],fill=C['hair'])
    line(d,[(x+2,y+1),(x+3,y+1)],'hairlight')
    rect(d,(x+1,y+3,x+3,y+4),'n')
    rect(d,(x+5,y+3,x+7,y+4),'n')
    line(d,[(x+4,y+3),(x+4,y+3)],'n')
    line(d,[(x+3,y+6),(x+4,y+6)],'wooddark')

def crate():
    im,d=blank((20,14))
    # Fish are visibly above the rim, like the scene's original fallback.
    for x,c in [(3,'bluelight'),(8,'red'),(13,'cream')]:
        d.polygon([(x,3),(x+1,1),(x+3,1),(x+4,3),(x+3,5),(x+1,5)],fill=C['n'])
        rect(d,(x+1,2,x+2,4),c)
        line(d,[(x+2,2),(x+2,2)],'n')
    rect(d,(1,5,18,12),'n')
    rect(d,(2,6,17,11),'wooddark')
    rect(d,(2,6,17,7),'wood')
    line(d,[(3,6),(16,6)],'light')
    line(d,[(2,10),(17,10)],'wood')
    for x in (5,13):
        line(d,[(x,8),(x,11)],'n')
    return im

def bed():
    im,d=blank((32,16))
    # Pillow, face, then a simple cool blanket; a lit phone above the chest.
    rect(d,(1,6,11,14),'n');rect(d,(2,7,10,13),'cream')
    head(d,2,5)
    rect(d,(11,8,29,14),'n')
    rect(d,(12,9,28,13),'blue')
    line(d,[(12,9),(27,9)],'bluelight')
    line(d,[(26,10),(26,13)],'n')
    rect(d,(10,5,14,8),'n');rect(d,(11,6,13,7),'skin')
    rect(d,(9,1,12,5),'n');rect(d,(10,2,11,4),'white')
    return im

def faint():
    im,d=blank((32,10))
    head(d,1,1)
    # White tank top and separate shorts/legs: no blanket in the faint pose.
    d.polygon([(10,2),(19,2),(21,4),(20,7),(10,7),(8,5)],fill=C['n'])
    rect(d,(10,3,18,5),'cream');rect(d,(11,6,18,6),'cream')
    rect(d,(20,3,24,7),'n');rect(d,(21,4,23,6),'hairlight')
    rect(d,(25,4,29,5),'skin');rect(d,(25,7,29,8),'skin')
    rect(d,(29,3,30,5),'n');rect(d,(29,7,30,8),'n')
    line(d,[(11,7),(14,8)],'skin')
    rect(d,(14,7,16,8),'teal');line(d,[(15,7),(15,7)],'white')
    return im

def glow():
    sheet=Image.new('RGBA',(320,80))
    # Four deliberate native frames, not a scaled image or a blurred gradient.
    for frame,radius in enumerate((30,34,37,34)):
        im,d=blank((80,80));x=y=39
        for r,key,alpha in [(radius,'teal',32),(radius-6,'teal',55),
                            (radius-13,'aqua',90),(radius-20,'teal',145),
                            (max(radius-26,3),'white',230)]:
            rgb=tuple(bytes.fromhex(C[key][1:]))
            d.ellipse((x-r,y-r,x+r,y+r),fill=rgb+(alpha,))
        sheet.alpha_composite(im,(frame*80,0))
    return sheet

def main():
    backup=ROOT/'build/cutscene_sprites/backups'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    OUT.mkdir(parents=True,exist_ok=True)
    for name,im in [('crate',crate()),('rin_bed',bed()),('rin_faint',faint()),('glow',glow())]:
        path=OUT/f'{name}.png'
        if path.exists():
            backup.mkdir(parents=True,exist_ok=True)
            shutil.copy2(path,backup/path.name)
        im.save(path)
        print(path.relative_to(ROOT),im.size)

if __name__=='__main__':
    main()
