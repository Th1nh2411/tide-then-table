"""Finish the existing Hunyuan restaurant batch with metre scale and flat palette.
No inferred geometry is replaced. Raw/reduced inputs stay byte-identical.
"""
from pathlib import Path
import json, math, shutil
import numpy as np
from glb_common import ROOT, load_mesh, normalize, material, write_mesh, backup, sha256

SPECS={
 'food_cart_0':('props',(2.8,1.60,1.25),'cart'),
 'food_cart_1':('props',(2.8,1.60,1.25),'cart'),
 'food_cart_2':('props',(3.0,1.60,1.4),'cart'),
 'charcoal_grill':('props',(.9,.72,.48),'grill'),
 'beer_keg':('props',(.60,1.45,.60),'keg'),
 'plate_bench':('props',(1.1,.89,.75),'wood'),
 'fridge_0':('props',(.9,.65,.8),'fridge_white'),
 'fridge_1':('props',(.9,.85,.8),'fridge_blue'),
 'fridge_2':('props',(.9,1.90,.8),'fridge_glass'),
 'menu_board':('props',(1.5,1.45,.18),'board'),
 'grocery_counter':('props',(3.8,1.36,1.0),'counter'),
 'motorbike':('props',(.70,1.0,1.85),'bike'),
 'sidewalk_tree':('props',(1.7,4.0,1.6),'tree'),
 'bin':('small',(.45,.60,.45),'bin'),
 'plant_pot':('small',(.75,.95,.75),'plant'),
 'beer_tower':('small',(.18,.52,.18),'tower'),
 'grocery_crate':('small',(.65,.45,.44),'grocery'),
 'plastic_bag':('small',(.28,.38,.18),'bag'),
 'crate':('small',(.60,.45,.45),'wood'),
 'bottle':('small',(.075,.29,.075),'bottle'),
}
PALETTES={
 'cart':{'Steel':'9ca9a8','Worktop':'c7cfcc','Glass':'a9c4ca','Dark':'39434a','Clay':'a86447','Gas':'3c6c8b'},
 'grill':{'Steel':'343d45','Charcoal':'a94b32','Ember':'d28b45'},
 'keg':{'Steel':'9daead','Band':'697c7d','Tap':'c7cfcc','Handle':'303b43'},
 'wood':{'Wood':'a57e52','Frame':'795c42'},
 'fridge_white':{'Body':'d4d7ce','Lid':'e8e5d8','Base':'899b9d'},
 'fridge_blue':{'Body':'3c5e8b','Lid':'e8e5d8','Base':'263e67'},
 'fridge_glass':{'Body':'c7cfcc','Lid':'a9c4ca','Base':'577277'},
 'board':{'Frame':'4c5b66','Display':'202a33'},
 'counter':{'Wood':'a47b54','Frame':'795842','Leaf':'668047','Tomato':'a7513a','Potato':'c5a172','Register':'394a50'},
 'bike':{'Body':'a9473e','Tire':'283038','Seat':'35414a','Metal':'879b9e','Lamp':'e8dfca'},
 'tree':{'Foliage':'5d7746','LightLeaf':'7d8c59','Trunk':'795f46','Planter':'8e9688'},
 'bin':{'Body':'3c5e8b','Lid':'526f9b'},
 'plant':{'Pot':'aa6343','Foliage':'567b45','LightLeaf':'7c9252'},
 'tower':{'Beer':'c99942','Foam':'e8dfca','Base':'303b43'},
 'grocery':{'Crate':'4b7c5d','Leaf':'728444','Tomato':'b96543'},
 'bag':{'Plastic':'b86a89','Tie':'d48aa2'},
 'bottle':{'Glass':'719c89','Paper':'d5c8a7','Cork':'a07a50'},
}

def align(points,kind):
 p=points.copy();p-=((p.min(0)+p.max(0))*.5)
 if kind=='bottle':
  axis=int(np.argmax(np.ptp(p,axis=0)))
  if axis==0:p=p[:,[1,0,2]]*[-1,1,1]
  elif axis==2:p=p[:,[0,2,1]]*[1,1,-1]
  return p,0.0
 if kind in ('tree','plant','keg','bin','tower','bag'):return p,0.0
 best=None
 for degree in np.arange(0,90,.5):
  a=math.radians(degree);r=np.array([[math.cos(a),0,math.sin(a)],[0,1,0],[-math.sin(a),0,math.cos(a)]])
  q=p@r.T;bounds=np.ptp(q,axis=0);area=bounds[0]*bounds[2]
  if best is None or area<best[0]:best=(area,a,q)
 _,angle,p=best
 # Rectangular furniture is long-X; bikes travel along +Z.
 if (np.ptp(p[:,0])<np.ptp(p[:,2])) != (kind=='bike'):
  p=p[:,[2,1,0]]*[1,1,-1];angle+=math.pi/2
 return p,angle

def label(kind,c,n,size):
 x,y,z=c;h=size[1];t=y/h;u=abs(x)/(size[0]/2);v=abs(z)/(size[2]/2)
 if kind=='cart':
  if t<.12:return 3
  if t>.63:
   if x<.12 and abs(n[1])<.72:return 2
   if x>.20*size[0] and t>.72:return 4 if t<.86 else 3
   return 1
  if .20<t<.48 and x>.20*size[0] and kind=='cart':return 0
  return 0 if abs(n[1])<.6 else 1
 if kind=='grill':
  if t>.72 and abs(x)<.4 and abs(z)<.20 and n[1]>.25:return 2 if (int(x*90)+int(z*80))%3 else 1
  return 0
 if kind=='keg':return 3 if t>.85 else 2 if t>.70 else 1 if t<.10 or .25<t<.30 or .58<t<.64 else 0
 if kind=='wood':return 0 if t>.75 else 1
 if kind.startswith('fridge'):return 1 if t>.82 else 2 if t<.075 else 0
 if kind=='board':return 1 if .18<t<.92 and u<.88 and abs(n[2])>.55 else 0
 if kind=='counter':
  if t>.73:
   if x>size[0]*.35:return 5
   return 2 if x<-size[0]*.15 else 3 if x<size[0]*.08 else 4
  return 1 if t<.13 or abs(n[1])<.15 else 0
 if kind=='bike':
  if t<.32:return 1
  if t>.70:return 4 if z>size[2]*.31 and n[2]>.25 else 2
  return 3 if u<.37 and t<.52 else 0
 if kind=='tree':
  if t<.18:return 3
  if t<.55 and u<.23:return 2
  return 1 if n[1]>.35 else 0
 if kind=='bin':return 1 if t>.80 else 0
 if kind=='plant':return 0 if t<.52 else 2 if n[1]>.3 else 1
 if kind=='tower':return 2 if t<.18 or t>.90 else 1 if t>.82 else 0
 if kind=='grocery':return 1 if t>.53 and (u<.75 and v<.75) else 2 if t>.55 and x>size[0]*.27 else 0
 if kind=='bag':return 1 if t>.75 else 0
 if kind=='bottle':return 2 if t>.93 else 1 if .25<t<.64 and abs(n[2])>.55 else 0
 return 0

def build(id,spec):
 group,size,kind=spec;src=ROOT/'assets/models/batch'/group/id/(id+'_reduced.glb')
 points,triangles=load_mesh(src)
 points,yaw=align(points,kind);points=normalize(points,size=size)
 normals=np.cross(points[triangles[:,1]]-points[triangles[:,0]],points[triangles[:,2]]-points[triangles[:,0]])
 normals/=np.maximum(np.linalg.norm(normals,axis=1)[:,None],1e-12)
 centers=points[triangles].mean(1)
 labels=np.array([label(kind,c,n,size) for c,n in zip(centers,normals)])
 colors=PALETTES[kind]
 mats=[material(id+'_'+name,color,metallic=.18 if name in ('Steel','Metal','Worktop','Tap') else 0,roughness=.85,double_sided=True) for name,color in colors.items()]
 folder=ROOT/'assets/models/ready'/id;folder.mkdir(parents=True,exist_ok=True)
 target=folder/(id+'.glb');metrics=write_mesh(target,points,triangles,mats,labels)
 meta={'id':id,'source':str(src.relative_to(ROOT)),'source_sha256':sha256(src),'source_provenance':str((src.parent/'hunyuan_provenance.json').relative_to(ROOT)),'concept':f'assets/concepts/3d_queue/{group}/{id}.png','builder':'tools/art/build_batch_restaurant.py','changes':['canonical metre scale','bottom-centred origin','footprint yaw normalization','flat face normals','palette materials by geometric region'],'yaw_radians':yaw,'geometry_replaced':False,**metrics}
 path=folder/'provenance.json';backup(path);path.write_text(json.dumps(meta,indent=2)+'\n')
 notice=src.parent/'LICENSE-HUNYUAN.txt'
 if notice.exists() and not (folder/notice.name).exists():shutil.copy2(notice,folder/notice.name)
 print('READY',id,metrics['triangles'],metrics['dimensions_m'])
 return meta

if __name__=='__main__':
 import argparse
 parser=argparse.ArgumentParser();parser.add_argument('ids',nargs='*');args=parser.parse_args()
 report=[build(id,SPECS[id]) for id in (args.ids or SPECS)]
 output=ROOT/'build/batch_integration/restaurant/build_report.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
