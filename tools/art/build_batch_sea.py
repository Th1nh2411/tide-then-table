"""Finish the inferred sea batch: affine fitting, deliberate palette, flat normals.
No Blender, reconstructed replacement hull or new gameplay geometry.
"""
from pathlib import Path
import json, math, shutil
import numpy as np
from glb_common import ROOT, load_mesh, normalize, write_mesh, sha256, material

CONFIG = {
 'ghe_cheo': ('props', (1.72,.72,3.05), {'Hull':'426b72','Stripe':'9b5044','Deck':'a57b50','DarkWood':'685244'}),
 'ghe_may': ('props', (1.72,1.65,3.05), {'Hull':'355c78','Stripe':'985043','Deck':'a57b50','Cabin':'d8d1b8','Window':'35434d','Roof':'71473b'}),
 'lighthouse': ('props',(2.9,3.18,2.4),{'Rock':'59696c','Tower':'d9d3bd','Bands':'9b5044','Window':'d4b66d','Roof':'674d42'}),
 'whale_shrine': ('props',(2.8,1.7,2.2),{'Stone':'85908a','Pillars':'9b5145','Roof':'9d6648','Altar':'b99b6c'}),
 'old_man_hut': ('props',(2.7,2.0,2.3),{'Stilts':'655244','Bamboo':'b1986b','Roof':'b49a5b','Porch':'97744e'}),
 'lobster_raft': ('props',(5.0,2.5,3.0),{'Float':'426c87','Deck':'9a7c57','Cabin':'b7a486','Roof':'7c6750','Lamp':'d5ba75'}),
 'dock': ('props',(3.5,2.6,7.7),{'Wood':'947b60','Posts':'675447','Rail':'b49b74','Lamp':'e3c77c'}),
 'rock_1': ('props',(2.5,1.2,2.2),{'Base':'44565e','Top':'708184','Side':'5a7077'}),
 'rock_2': ('props',(1.8,1.5,1.6),{'Base':'44565e','Top':'708184','Side':'5a7077'}),
 'dolphin': ('props',(.55,.62,2.2),{'Back':'587789','Belly':'aabfbe','Fin':'496a7d'}),
 'non_la': ('small',(.60,.28,.60),{'Straw':'d4bd83','Inside':'b09562','Strap':'6b5448'}),
 'net_buoy': ('small',(.38,.70,.38),{'Float':'c37c47','Lamp':'e3c77c','Pole':'6c6d60','Rope':'746249'}),
 'jellyfish': ('small',(.42,.72,.42),{'Bell':'96cec7','Tentacles':'65b6b5','Rim':'b7dfd1'}),
}

def align_long(points, bow=False):
    p=points.copy();xz=p[:,[0,2]];xz-=xz.mean(0)
    vals, axes=np.linalg.eigh(np.cov(xz.T));axis=axes[:,np.argmax(vals)]
    angle=math.atan2(axis[0],axis[1]);c,s=math.cos(angle),math.sin(angle)
    # Rotation that maps the principal horizontal direction onto +Z.
    x,z=p[:,0].copy(),p[:,2].copy();p[:,0]=c*x-s*z;p[:,2]=s*x+c*z
    if bow:
        span=np.ptp(p[:,2]);lo,hi=p[:,2].min(),p[:,2].max()
        low=p[p[:,2]<lo+.17*span,0];high=p[p[:,2]>hi-.17*span,0]
        # The narrower pointed tip is the bow; runtime forward is -Z.
        if np.ptp(high)<np.ptp(low):p[:,[0,2]]*=-1;angle+=math.pi
    return p,angle

def label(asset,p,n,size):
    x,y,z=p;h=y/size[1];ax=abs(x)/(size[0]/2);az=abs(z)/(size[2]/2)
    if asset=='ghe_cheo':
        if h<.24:return 'Hull'
        if h<.36 and abs(n[1])<.6:return 'Stripe'
        return 'Deck' if n[1]>.3 or h>.75 else 'DarkWood'
    if asset=='ghe_may':
        if h<.20:return 'Hull'
        if h<.30:return 'Stripe'
        if h>.88:return 'Roof'
        if h>.47:
            if .60<h<.79 and (ax>.48 or abs(n[2])>.6):return 'Window'
            return 'Cabin'
        return 'Deck'
    if asset=='lighthouse':
        if h<.23:return 'Rock'
        if h>.96:return 'Roof'
        if h>.86:return 'Window'
        return 'Bands' if .39<h<.47 or .67<h<.75 else 'Tower'
    if asset=='whale_shrine':
        if h<.20:return 'Stone'
        if h>.66:return 'Roof'
        return 'Altar' if n[1]>.7 else 'Pillars'
    if asset=='old_man_hut':
        if h<.29:return 'Stilts'
        if h>.67:return 'Roof'
        return 'Porch' if n[1]>.65 else 'Bamboo'
    if asset=='lobster_raft':
        if h<.16:return 'Float'
        if h<.30:return 'Deck'
        if h>.95:return 'Lamp'
        return 'Roof' if n[1]>.4 else 'Cabin'
    if asset=='dock':
        if h>.94:return 'Lamp'
        if h<.36:return 'Posts'
        return 'Rail' if h>.56 else 'Wood'
    if asset.startswith('rock_'):
        return 'Top' if n[1]>.5 else 'Base' if h<.3 else 'Side'
    if asset=='dolphin':return 'Belly' if h<.42 else 'Fin' if ax>.75 else 'Back'
    if asset=='non_la':return 'Strap' if h<.18 and ax<.5 and az<.5 else 'Inside' if n[1]<-.2 else 'Straw'
    if asset=='net_buoy':return 'Rope' if h<.18 else 'Lamp' if h>.85 else 'Pole' if h>.60 else 'Float'
    if asset=='jellyfish':return 'Rim' if h>.82 else 'Bell' if h>.53 else 'Tentacles'
    raise ValueError(asset)

results=[]
for asset,(group,size,palette) in CONFIG.items():
    src=ROOT/'assets/models/batch'/group/asset/(asset+'_reduced.glb')
    points,triangles=load_mesh(src);yaw=0
    if asset in ['ghe_cheo','ghe_may','dock','dolphin']:points,yaw=align_long(points,asset.startswith('ghe_'))
    points=normalize(points,size=size)
    centroids=points[triangles].mean(1);normal=np.cross(points[triangles[:,1]]-points[triangles[:,0]],points[triangles[:,2]]-points[triangles[:,0]])
    normal/=np.maximum(np.linalg.norm(normal,axis=1,keepdims=True),1e-12)
    names=list(palette);labels=[names.index(label(asset,p,n,size)) for p,n in zip(centroids,normal)]
    mats=[material(asset+'_'+name,color,roughness=.9) for name,color in palette.items()]
    if asset=='jellyfish':
        for m in mats:m['emissiveFactor']=[.03,.12,.11]
    dest=ROOT/'assets/models/ready'/asset;dest.mkdir(parents=True,exist_ok=True)
    metrics=write_mesh(dest/(asset+'.glb'),points,triangles,mats,labels)
    meta={'source':str(src.relative_to(ROOT)),'source_sha256':sha256(src),'input':f'assets/concepts/3d_queue/{group}/{asset}.png','pipeline':'Hunyuan local batch → affine dimensions/orientation → flat palette/normals','source_triangles':len(triangles),'yaw_radians':yaw,'geometry_replaced':False,'blender_used':False,**metrics}
    (dest/'provenance.json').write_text(json.dumps(meta,indent=2)+'\n')
    license_file=src.parent/'LICENSE-HUNYUAN.txt'
    if license_file.exists() and not (dest/license_file.name).exists():shutil.copy2(license_file,dest/license_file.name)
    results.append({'id':asset,**metrics})
    print('SEA_READY',asset,metrics['triangles'],metrics['dimensions_m'])
review=ROOT/'build/batch_integration/sea';review.mkdir(parents=True,exist_ok=True)
(review/'prepared.json').write_text(json.dumps(results,indent=2)+'\n')
