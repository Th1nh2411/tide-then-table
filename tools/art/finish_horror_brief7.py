"""Brief 7: complete surface coverage, dense Terminalia and working cart glass.
Run with uv --with trimesh --with pillow --with scipy --with fast-simplification.
Original inference/concepts are immutable; all inputs are backed up first.
"""
from pathlib import Path
import argparse,json,hashlib,tempfile
import numpy as np
import trimesh
from PIL import Image,ImageDraw,ImageFont
from scipy.ndimage import binary_erosion
from glb_common import load_mesh
from prepare_horror_models import with_normals
from finish_horror_brief6 import material,painted_part,textured,cylinder,box,join,vessel,BUDGETS
ROOT=Path(__file__).resolve().parents[2]
READY=ROOT/'assets/models/ready'; BACKUP=ROOT/'.art_backups/brief7_20261105'
IDS='charcoal_stove_clay boat_upturned boat_pulled_up coconut_palm fish_cua fish_tom fish_muc fish_oc_huong fish_ca_mu fish_glowing fishing_bobber hat_hook stone_steps wooden_bed ice_box_styrofoam motorbike_cub water_jar fish_basket wooden_wardrobe shed_tin banana_clump buoy_pile altar_ong_tu beer_tower beer_glass_ice dish_bowl_soup dish_plate_fish food_cart_glass roadside_shrine power_pole planter_tree_street'.split()

def source(name):
 v,f=load_mesh(BACKUP/f'assets/models/ready/{name}/{name}_reduced.glb')
 return trimesh.Trimesh(v,f,process=False)

def save(name,parts,note,rebuilt=False):
 count=sum(len(p.faces) for p in parts.values());assert count<=BUDGETS[name],(name,count)
 scene=trimesh.Scene()
 for label,mesh in parts.items():
  if len(mesh.faces):scene.add_geometry(mesh,geom_name=label,node_name=label)
 with tempfile.TemporaryDirectory() as folder:
  path=Path(folder)/'asset.glb';scene.export(path);payload,_=with_normals(path)
 path=READY/name/f'{name}_reduced.glb';path.write_bytes(payload)
 old=BACKUP/f'assets/models/ready/{name}/hunyuan_provenance.json';r=json.loads(old.read_text())
 r['reduced_sha256']=hashlib.sha256(payload).hexdigest()
 r['brief7']={'date':'2026-11-05','tool':'tools/art/finish_horror_brief7.py','input_reduced_sha256':hashlib.sha256((old.parent/f'{name}_reduced.glb').read_bytes()).hexdigest(),'triangles':count,'budget':BUDGETS[name],'true_uv':True,'rebuilt_geometry':rebuilt,'blend_source':f'art_source/horror/brief7/{name}.blend','note':note}
 r.setdefault('integration',{})['runtime_faces']=count;r['integration']['geometry_unchanged']=not rebuilt
 (path.parent/'hunyuan_provenance.json').write_text(json.dumps(r,indent=2)+'\n')
 if rebuilt:
  p=READY/'horror_models.json';c=json.loads(p.read_text());v=np.vstack([p.vertices for p in parts.values()]);lo=v.min(0);hi=v.max(0);center=(lo+hi)/2
  _,axes=np.linalg.eigh(np.cov(v.T));axis=axes[:,-1]
  if axis[np.argmax(abs(axis))]<0:axis=-axis
  along=(v-center)@axis;c[name].update(size=(hi-lo).tolist(),axis=axis.tolist(),anchor=(center+axis*along.min()).tolist(),length=float(np.ptp(along)))
  p.write_text(json.dumps(c,indent=2)+'\n');write_catalog(c)
 print(name,count,flush=True)

def write_catalog(c):
 (READY/'horror_models.gd').write_text('extends RefCounted\n# Generated from horror_models.json.\nconst DATA := {\n'+'\n'.join('\t'+json.dumps(k)+': '+json.dumps(v,separators=(',',':'))+',' for k,v in c.items())+'\n}\n')

def surface(name,p,n,bounds):
 """Material coordinates are model-space, never the concept's grey backdrop."""
 q=(p-bounds[0])/np.maximum(bounds[1]-bounds[0],1e-8);x,y,z=np.moveaxis(q,-1,0)
 grain=np.sin(x*111+np.sin(y*31)*2+z*13)*.025
 noise=(np.sin(x*57+y*103+z*73)*np.sin(x*139-y*61+z*37))*.035
 base=np.broadcast_to(np.array([.33,.27,.18]),p.shape).copy()
 def color(c):base[:]=c
 if name=='charcoal_stove_clay':
  color([.43,.25,.15]);base[y>.70]=[.19,.15,.12];base[y<.12]=[.24,.23,.17]
 elif name.startswith('boat_'):
  color([.32,.27,.17]);base[y<.38]=[.23,.29,.22];grain+=np.sin(y*85+x*3)*.04
 elif name in ['coconut_palm','banana_clump']:
  if name=='coconut_palm':color([.36,.31,.22]);base[y>.62]=[.23,.31,.14];grain+=np.sin(y*170+x*7)*.04
  else:color([.32,.37,.17]);base[y>.42]=[.22,.31,.13]
 elif name.startswith('fish_') and name!='fish_basket':
  colors={'fish_cua':[.30,.30,.16],'fish_tom':[.37,.37,.27],'fish_muc':[.56,.39,.33],'fish_oc_huong':[.63,.49,.29],'fish_ca_mu':[.40,.33,.22],'fish_glowing':[.19,.30,.30]}
  color(colors[name]);base+=(np.sin(x*105+z*25)*np.cos(y*80-z*20))[...,None]*.035
  if name in ['fish_ca_mu','fish_oc_huong']:base[(np.sin(x*65+y*27)*np.sin(z*47-y*19))>.50]*=.50
  if name=='fish_tom':base[(np.sin(x*90+z*11))>.8]*=.65
  if name=='fish_glowing':base+=((np.sin(x*60+y*19)>0.88)&(y>.3)&(y<.65))[...,None]*np.array([.03,.22,.14])
 elif name=='fishing_bobber':
  color([.45,.34,.18]);base[(y>.30)&(y<.67)]=[.51,.20,.14];base[(y>.35)&(y<.48)]=[.56,.49,.31]
 elif name=='hat_hook':
  color([.48,.39,.22]);grain+=np.sin(x*150+z*70)*np.sin(y*140-z*50)*.045
 elif name=='stone_steps':
  color([.35,.34,.26]);base+=(np.sin(x*21+z*17)*np.sin(y*31-z*13))[...,None]*.045;base[y<.14]*=[.65,.78,.56]
 elif name=='motorbike_cub':
  color([.21,.26,.23]);base[y<.3]=[.16,.18,.17];base[(y>.3)&(y<.60)]=[.36,.36,.29]
 elif name=='water_jar':color([.27,.19,.14]);grain+=np.sin(y*180)*.02
 elif name=='fish_basket':color([.29,.25,.16]);grain+=np.sin(x*160)*np.sin(y*160)*.04
 elif name=='wooden_wardrobe':color([.28,.23,.17]);grain+=np.sin(x*120+np.sin(y*20))* .035
 elif name=='buoy_pile':
  color([.41,.37,.23]);base[x>.65]=[.35,.40,.33];grain+=np.sin(x*83+y*43)*.02
 elif name=='altar_ong_tu':
  color([.31,.21,.14]);base[y>.65]=[.61,.52,.34]
 elif name in ['beer_tower','beer_glass_ice']:
  color([.49,.35,.15]);base[y<.18]=[.37,.19,.14];base[y>.78]=[.43,.46,.41]
 elif name in ['dish_bowl_soup','dish_plate_fish']:
  color([.46,.51,.45]);grain+=np.sin(x*120+z*130)*.02
 elif name=='food_cart_glass':
  color([.27,.28,.22]);base[y<.17]=[.13,.16,.14]
 elif name=='roadside_shrine':
  color([.38,.35,.25]);base[y>.69]=[.36,.21,.15]
 elif name=='power_pole':color([.38,.38,.31]);base[y<.2]*=.7
 return np.clip(base+(noise+grain)[...,None],.07,.72)

def bake(name,mesh=None,force_material=False):
 """Triangle atlas: preserve covered concept detail, author every uncovered texel.
 Grey-background classification happens in source sRGB, before GPU linearisation.
 A padded island per face also covers undersides/ends; no guessed grey defaults.
 """
 if mesh is None:mesh=source(name)
 spec=json.loads((READY/'horror_models.json').read_text())[name];bounds=source(name).bounds;dims=bounds[1]-bounds[0]
 image=np.array(Image.open(ROOT/f'assets/concepts/horror/{name}.png').convert('RGB'))/255
 valid=~((np.ptp(image,axis=2)<.075)&(image.mean(2)>.43))
 valid=binary_erosion(valid,iterations=2)
 u=np.array([0,0,1]) if dims[2]>dims[0]*1.25 else np.array([1,0,0]);v=np.array([0,0,1]) if dims[1]<min(dims[0],dims[2])*.5 else np.array([0,1,0])
 crop=np.array(spec['crop']);side=int(np.ceil(np.sqrt(len(mesh.faces))));tile=2048//side;size=side*tile;pad=6;end=tile-pad-1
 atlas=np.zeros((size,size,3),dtype=np.uint8);uv=[]
 gy,gx=np.mgrid[:tile,:tile];a=np.clip((gx-pad)/(end-pad),0,1);b=np.clip((gy-pad)/(end-pad),0,1)
 denom=np.maximum(a+b,1);a=a/denom;b=b/denom
 for index,(tri,n) in enumerate(zip(mesh.triangles,mesh.face_normals)):
  p=tri[0]+a[...,None]*(tri[1]-tri[0])+b[...,None]*(tri[2]-tri[0]);q=(p-bounds[0])/dims
  coords=crop[:2]+np.stack([q@u,1-q@v],axis=-1)*crop[2:]
  pixels=np.clip((coords*np.array([image.shape[1]-1,image.shape[0]-1])).astype(int),0,1023)
  rgb=image[pixels[...,1],pixels[...,0]];ok=valid[pixels[...,1],pixels[...,0]]
  front=np.array([0,1,0]) if v[2] else np.cross(u,v)
  if force_material or np.dot(n,front)<-.15:ok[:]=False
  rgb=np.where(ok[...,None],rgb,surface(name,p,n,bounds))
  x=index%side*tile;y=index//side*tile;atlas[y:y+tile,x:x+tile]=(rgb*255).astype(np.uint8)
  uv += [[(x+pad+.5)/size,1-(y+pad+.5)/size],[(x+end+.5)/size,1-(y+pad+.5)/size],[(x+pad+.5)/size,1-(y+end+.5)/size]]
 part=trimesh.Trimesh(mesh.triangles.reshape(-1,3),np.arange(len(mesh.faces)*3).reshape(-1,3),process=False)
 role='HorrorBend_GlowFish' if name=='fish_glowing' else 'HorrorUV_Coverage_'+name
 mat=trimesh.visual.material.PBRMaterial(name=role,baseColorTexture=Image.fromarray(atlas),baseColorFactor=np.ones(4),roughnessFactor=.92,metallicFactor=0,doubleSided=True)
 part.visual=trimesh.visual.TextureVisuals(uv=np.array(uv),material=mat)
 return part

def generic():
 skip={'wooden_bed','ice_box_styrofoam','food_cart_glass','planter_tree_street','roadside_shrine','power_pole','shed_tin'}
 for name in IDS:
  if name in skip:continue
  save(name,{'CoveredSurface':bake(name)},'Padded true-UV triangle atlas preserves painted concept detail; sRGB background samples replaced with spatially varied species/material colour, including ends and undersides.')
 for name,tex in [('power_pole','wall_plaster_old'),('shed_tin','roof_tin_rusty')]:
  mesh=source(name)
  if name=='power_pole':
   y=(mesh.triangles_center[:,1]-mesh.bounds[0,1])/mesh.extents[1];body=y<.77
  else:
   y=(mesh.triangles_center[:,1]-mesh.bounds[0,1])/mesh.extents[1];body=y<.17
  parts={'PatchedDetails':bake(name,mesh.submesh([np.where(~body)[0]],append=True)), 'TiledBody':painted_part(mesh,body,material(tex,(.72,.68,.56,1)),3)}
  save(name,parts,'True UV tiled structural surfaces; covered atlas on painted detail, no projection streaks or pale feet.')
 name='roadside_shrine';mesh=source(name);y=(mesh.triangles_center[:,1]-mesh.bounds[0,1])/mesh.extents[1];pillar=y<.48
 save(name,{'TiledPillar':painted_part(mesh,pillar,material('wall_plaster_old',(.66,.67,.54,1)),4),'ShrineDetails':bake(name,mesh.submesh([np.where(~pillar)[0]],append=True))},'Real UV plaster pillar; preserve roof and altar detail with full colour coverage.')

def fabric():
 name='wooden_bed';mesh=source(name);n=mesh.face_normals;c=mesh.triangles_center;y=(c[:,1]-mesh.bounds[0,1])/mesh.extents[1]
 top=(y>.22)&(y<.62)&(abs(n[:,1])>.45)
 h,w=256,256;yy,xx=np.mgrid[:h,:w];rng=np.random.default_rng(7)
 rgb=np.empty((h,w,3));rgb[:]=[.55,.46,.29]
 weave=(np.sin(xx*np.pi/2)*.045+np.sin(yy*np.pi/2)*.025+rng.uniform(-.02,.02,(h,w)))
 rgb+=weave[...,None];rgb[:,(xx[0]%64)<4]*=.56
 im=Image.fromarray(np.uint8(np.clip(rgb,0,1)*255))
 mat=trimesh.visual.material.PBRMaterial(name='HorrorUV_WornChieu',baseColorTexture=im,baseColorFactor=np.ones(4),roughnessFactor=1,metallicFactor=0,doubleSided=True)
 save(name,{'WornRushMat':painted_part(mesh,top,mat,5,True),'BedWoodAndMosquitoNet':bake(name,mesh.submesh([np.where(~top)[0]],append=True))},'Woven yellow-brown chiếu with dark binding stripes, wood frame and covered cloth details.')
 name='ice_box_styrofoam';mesh=source(name)
 yy,xx=np.mgrid[:256,:256];rng=np.random.default_rng(71);noise=rng.random((256,256));dirt=(np.sin(xx*.08+np.sin(yy*.03))*np.sin(yy*.04)>.3)
 rgb=np.ones((256,256,3))*[.63,.60,.49];rgb-=dirt[...,None]*[.16,.15,.12];rgb+=(noise-.5)[...,None]*.07
 tape=(abs(xx-128)<13)|(abs(yy-138)<11);rgb[tape]=np.array([.43,.34,.19])+((noise[tape]-.5)*.07)[:,None]
 mat=trimesh.visual.material.PBRMaterial(name='HorrorUV_DirtyFoamAndTape',baseColorTexture=Image.fromarray(np.uint8(np.clip(rgb,0,1)*255)),baseColorFactor=np.ones(4),roughnessFactor=1,metallicFactor=0,doubleSided=True)
 save(name,{'DirtyFoamAllSides':painted_part(mesh,np.ones(len(mesh.faces),dtype=bool),mat,.55)},'Own repeating dirty foam/tape texture covers lid, back, sides and bottom; no unpainted planes.')

def tree():
 from repair_horror_planter_tree import branch
 old=source('planter_tree_street');c=old.triangles_center
 pot=old.submesh([np.where(c[:,1]<.28)[0]],append=True).simplify_quadric_decimation(face_count=280)
 wood=[branch(np.array([0,.22,0]),np.array([0,2.3,0]),.14,.095),branch(np.array([0,2.3,0]),np.array([0,3.85,0]),.095,.025)]
 leaves=[[],[],[]];rng=np.random.default_rng(7007)
 for tier,(y,r) in enumerate([(2.35,1.02),(3.06,.97),(3.71,.81)]):
  for spoke in range(7):
   a=spoke*np.pi*2/7+tier*.27;end=np.array([np.cos(a)*r*.84,y,np.sin(a)*r*.84])
   wood.append(branch(np.array([0,y-.18,0]),end,.045,.012))
   for k in range(12):
    radius=r*(.20+.65*(k%4)/3);ang=a+(k//4-1)*.26
    center=np.array([np.cos(ang)*radius,y+rng.uniform(-.08,.08),np.sin(ang)*radius])
    length=.48;width=.35;d=np.array([np.cos(ang),0,np.sin(ang)]);s=np.array([-np.sin(ang),0,np.cos(ang)])
    verts=[center+s*np.cos(t)*width/2+d*np.sin(t)*length/2 for t in np.linspace(0,2*np.pi,6,endpoint=False)]+[center+[0,.035,0]]
    faces=[[6,i,(i+1)%6] for i in range(6)]
    leaves[(k+spoke+tier)%3].append(trimesh.Trimesh(verts,faces,process=False))
 parts={'OriginalPlanter':textured(pot,material('wall_plaster_old',(.65,.62,.49,1)),3),'ThickTrunkAndHorizontalBranches':textured(join(wood),material('floor_wood_planks',(.72,.62,.43,1)),3)}
 for i,col in enumerate([(.24,.34,.15,1),(.31,.40,.20,1),(.37,.43,.24,1)]):
  yy,xx=np.mgrid[:64,:64];rgb=np.ones((64,64,3))*col[:3];rgb+=(np.sin(xx*.7+yy*.3)*.018)[...,None];rgb[abs(xx-32)<2]*=1.12
  mat=trimesh.visual.material.PBRMaterial(name=f'HorrorUV_LeafVeins_{i}',baseColorTexture=Image.fromarray(np.uint8(np.clip(rgb,0,1)*255)),baseColorFactor=np.ones(4),roughnessFactor=1,metallicFactor=0,doubleSided=True)
  parts[f'DenseLeafTierColour_{i}']=textured(join(leaves[i]),mat,3)
 save('planter_tree_street',parts,'Thick short trunk, three broad dense horizontal crowns with 252 overlapping rounded leaves; crown wider than its vertical depth. Original planter retained.',True)

def cart():
 name='food_cart_glass'
 # Coherent replacement of the damaged inferred case/body; keep the old bounds.
 old=source(name);size=old.extents;lo=old.bounds[0];hi=old.bounds[1]
 # Build centred at origin; the old mesh bounds are restored after assembly.
 w,h,d=size;body_w=w*.78;body_d=d*.75;y0=h*.23;y1=h*.47;case_top=h*.78
 body=box([0,(y0+y1)/2,0],[body_w,y1-y0,body_d])
 top=box([0,y1,0],[body_w+.04,.035,body_d+.04]);parts={}
 parts['TinBody']=textured(body,material('roof_tin_rusty',(.63,.64,.48,1)),2)
 parts['Counter']=textured(top,material('floor_wood_planks',(.64,.58,.42,1)),3)
 wheels=[];hubs=[]
 for x in [-w*.41,w*.41]:
  for z in [-d*.26,d*.26]:
   wheels.append(cylinder([x-.045,h*.12,z],[x+.045,h*.12,z],h*.12,16))
   hubs.append(cylinder([x-.052,h*.12,z],[x+.052,h*.12,z],h*.055,12))
 parts['RubberWheels']=textured(join(wheels),material('door_wood_old',(.22,.24,.19,1)),2)
 parts['WheelHubs']=textured(join(hubs),material('roof_tin_rusty',(.45,.46,.36,1)),3)
 frame=[];shelves=[];bowls=[];food=[]
 x0,x1=-body_w*.45,body_w*.45;z0,z1=-body_d*.43,body_d*.43
 for x in [x0,x1]:
  for z in [z0,z1]:frame.append(cylinder([x,y1,z],[x,h*.94,z],.015,6))
 for y in [y1,case_top]:
  for z in [z0,z1]:frame.append(cylinder([x0,y,z],[x1,y,z],.014,6))
  for x in [x0,x1]:frame.append(cylinder([x,y,z0],[x,y,z1],.014,6))
 for y in [y1+.025,y1+(case_top-y1)*.48]:
  shelves.append(box([0,y,0],[x1-x0,.012,z1-z0]))
  for i in range(3):
   x=x0+(i+.5)*(x1-x0)/3;r=(x1-x0)*.105
   bowls.append(vessel([x,y+.008,0],r,.052,10))
   f=trimesh.creation.icosphere(subdivisions=1,radius=1);f.apply_scale([r*.75,.036,r*.75]);f.apply_translation([x,y+.061,0]);food.append(f)
 panes=[]
 for vs in [[[x0,y1,z1],[x1,y1,z1],[x1,case_top,z1],[x0,case_top,z1]],[[x0,y1,z0],[x0,y1,z1],[x0,case_top,z1],[x0,case_top,z0]],[[x1,y1,z1],[x1,y1,z0],[x1,case_top,z0],[x1,case_top,z1]]]:panes.append(trimesh.Trimesh(vs,[[0,1,2],[0,2,3]],process=False))
 glass=material(color=(.12,.22,.20,.14),role='HorrorUV_TransparentGlass');glass.alphaMode='BLEND';glass.roughnessFactor=.25;glass.metallicFactor=.25
 parts['TransparentGlass']=textured(join(panes),glass)
 parts['CaseFrame']=textured(join(frame),material('roof_tin_rusty',(.60,.57,.43,1)),3)
 parts['DisplayShelves']=textured(join(shelves),material('floor_wood_planks',(.5,.5,.38,1)),3)
 parts['CeramicBowls']=textured(join(bowls),material('wall_plaster_old',(.66,.62,.43,1)),3)
 parts['FoodInside']=textured(join(food),material('door_wood_old',(.87,.66,.35,1)),3)
 # Solid pitched roof, not a photo of a roof or a projection frame.
 roof=trimesh.Trimesh([[-w/2,h*.93,-d/2],[w/2,h*.93,-d/2],[-w/2,h,0],[w/2,h,0],[-w/2,h*.93,d/2],[w/2,h*.93,d/2]],[[0,2,3],[0,3,1],[2,4,5],[2,5,3]],process=False)
 parts['TinRoof']=textured(roof,material('roof_tin_rusty'),3)
 for x in [x0,x1]:frame.append(cylinder([x,y1,z0],[x,y1,z0-.28],.02,6))
 # This plate contains only lettering; no full model picture can be sampled.
 im=Image.new('RGB',(512,192),(151,137,87));a=np.array(im).astype(float);yy,xx=np.mgrid[:192,:512];a+=(np.sin(xx*.11+yy*.08)*np.sin(yy*.06)*12)[...,None];im=Image.fromarray(np.uint8(np.clip(a,0,255)))
 draw=ImageDraw.Draw(im);font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf',94);draw.text((256,88),'BẢO',font=font,anchor='mm',fill=(106,43,27));draw.rectangle((3,3,508,188),outline=(98,76,39),width=6)
 sy0,sy1=y0+.02,y1-.02;sw=body_w*.88;sz=body_d/2+.006
 plate=trimesh.Trimesh([[-sw/2,sy0,sz],[sw/2,sy0,sz],[sw/2,sy1,sz],[-sw/2,sy1,sz]],[[0,1,2],[0,2,3]],process=False)
 plate.visual=trimesh.visual.TextureVisuals(uv=[[0,0],[1,0],[1,1],[0,1]],material=trimesh.visual.material.PBRMaterial(name='HorrorUV_BaoLettering',baseColorTexture=im,baseColorFactor=np.ones(4),doubleSided=False,roughnessFactor=.95,metallicFactor=0))
 parts['FrontBaoSign']=plate
 # Keep original dimensions/coordinate origin for the current placement contract.
 for part in parts.values():part.apply_translation([0,lo[1],0])
 vertices=np.vstack([p.vertices for p in parts.values()]);center=(vertices.min(0)+vertices.max(0))/2
 for part in parts.values():part.apply_translation([old.bounds.mean(0)[0]-center[0],0,old.bounds.mean(0)[2]-center[2]])
 save(name,parts,'Rebuilt coherent cart at original size: single-sided BẢO sign, UV tin/wood body and roof, dark translucent case with six bowls/food, rubber wheels. No full concept image on any surface.',True)

def signs():
 # Replace the existing painted sign in tube_house_b's facade image, no new geometry.
 # Placement owners call ConceptModel3D.set_sign_variant(instance, key).
 name='tube_house_b';original=Image.open(ROOT/f'assets/concepts/horror/{name}.png').convert('RGB')
 folder=READY/name/'sign_variants';folder.mkdir(exist_ok=True)
 for key,label,col in [('tap_hoa','TẠP HOÁ CÔ SEN',(145,128,82)),('sua_xe','SỬA XE CHÚ TƯ',(94,111,99)),('thuoc_bac','THUỐC BẮC AN HOÀ',(137,116,76)),('plain','',(139,125,83))]:
  im=original.copy();sign=Image.new('RGB',(560,132),col);d=ImageDraw.Draw(sign)
  rng=np.random.default_rng(7)
  for _ in range(1000):
   x=int(rng.integers(0,560));y=int(rng.integers(0,132));d.rectangle((x,y,x+int(rng.integers(1,6)),y+3),fill=tuple(max(0,c-int(rng.integers(4,19))) for c in col))
  font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf',50)
  d.rectangle((4,4,555,127),outline=(94,58,36),width=5);d.text((280,60),label,font=font,anchor='mm',fill=(77,39,28))
  # Existing sign trapezoid: TL (307,586), TR (582,599), BL (307,650), BR (582,667).
  # Perspective map image coordinates to the canonical sign surface.
  src=np.array([[307,586],[582,599],[582,667],[307,650]],float);dst=np.array([[0,0],[559,0],[559,131],[0,131]],float);A=[];b=[]
  for (x,y),(u,v) in zip(src,dst):A += [[x,y,1,0,0,0,-u*x,-u*y],[0,0,0,x,y,1,-v*x,-v*y]];b += [u,v]
  coeff=np.linalg.solve(A,b);layer=sign.transform(im.size,Image.Transform.PERSPECTIVE,coeff,Image.Resampling.BICUBIC)
  mask=Image.new('L',im.size);ImageDraw.Draw(mask).polygon([tuple(p) for p in src],fill=255);im.paste(layer,(0,0),mask);im.save(folder/f'{key}.png')
 (folder/'README.md').write_text('Authored variants of the original concept sign; source PNG unchanged.\nHook: ConceptModel3D.set_sign_variant(instance, "tap_hoa" | "sua_xe" | "thuoc_bac" | "plain").\nSupported on tube_house_b; A/C already have sign-free facades and are left intact.\n')

def underside():
 name='tray_aluminium';mesh=source(name);bottom=mesh.face_normals[:,1]<-.25
 yy,xx=np.mgrid[:256,:256];rgb=np.ones((256,256,3))*[.43,.46,.43];rgb+=(np.sin(xx*.75+yy*.16)*.024+np.sin(xx*.08)*.017)[...,None]
 mat=trimesh.visual.material.PBRMaterial(name='HorrorUV_ScratchedMetalUnderside',baseColorTexture=Image.fromarray(np.uint8(rgb*255)),baseColorFactor=np.ones(4),roughnessFactor=.95,metallicFactor=0,doubleSided=True)
 # The top is metal too; direct UVs avoid a complete tray picture on either side.
 top=painted_part(mesh,~bottom,mat,4,True);back=painted_part(mesh,bottom,mat,4,True)
 save(name,{'RolledMetalTop':top,'PlainScratchedUnderside':back},'Six-side audit: removed complete tray/rim photo repeated on underside; real scratched metal UVs on both sides.')

def uv_part(mesh,mask,mat,scale=3):
 part=painted_part(mesh,mask,mat,scale)
 for face,normal in enumerate(part.face_normals):
  axis=int(np.argmax(abs(normal)));axes=([2,1],[0,2],[0,1])[axis]
  part.visual.uv[face*3:face*3+3]=part.vertices[face*3:face*3+3][:,axes]*scale
 return part

def structures():
 # Explicit semantic surfaces for large planes: neither side nor underside
 # may contain a reduced image of the whole object, even with bad input normals.
 for name in ['stone_steps','wooden_wardrobe','shed_tin','altar_ong_tu','dish_plate_fish','dish_bowl_soup','boat_upturned','boat_pulled_up']:
  mesh=source(name);n=mesh.face_normals;c=mesh.triangles_center;lo,hi=mesh.bounds;dims=mesh.extents;q=(c-lo)/dims
  u=np.array([0,0,1]) if dims[2]>dims[0]*1.25 else np.array([1,0,0]);front=np.cross(u,[0,1,0]);center=mesh.bounds.mean(0)
  facing=(n@front>.5)&((c-center)@front>0)
  detail=facing.copy();parts={}
  if name=='stone_steps':
   yy,xx=np.mgrid[:256,:256];grit=np.sin(xx*.19+np.sin(yy*.07))*np.sin(yy*.24+xx*.06);fine=np.sin(xx*2.1+yy*1.7)*.02
   rgb=np.ones((256,256,3))*[.37,.37,.29];rgb+=(grit*.055+fine)[...,None];moss=(np.sin(xx*.035+yy*.03)*np.sin(yy*.08)>.35);rgb[moss]*=[.70,.83,.57]
   mat=trimesh.visual.material.PBRMaterial(name='HorrorUV_MossyStone',baseColorTexture=Image.fromarray(np.uint8(rgb*255)),baseColorFactor=np.ones(4),metallicFactor=0,roughnessFactor=1,doubleSided=True)
   parts['StoneOnEveryFace']=uv_part(mesh,np.ones(len(n),bool),mat,3)
  elif name=='wooden_wardrobe':
   parts={'FrontDoorDetail':bake(name,mesh.submesh([np.where(detail)[0]],append=True)), 'WoodBackTopFeet':uv_part(mesh,~detail,material('floor_wood_planks',(.78,.66,.49,1)),3)}
  elif name=='shed_tin':
   roof=(n[:,1]>.35)&(q[:,1]>.62);detail &= ~roof
   parts={'FrontDoorAndWindow':bake(name,mesh.submesh([np.where(detail)[0]],append=True)), 'TinWallsRoofAndBase':uv_part(mesh,~detail,material('roof_tin_rusty',(.83,.77,.61,1)),3)}
  elif name=='altar_ong_tu':
   lower=(q[:,1]<.50)|(n[:,1]<-.25)
   parts={'AltarUpperDetail':bake(name,mesh.submesh([np.where(~lower)[0]],append=True)), 'WoodTableAndUnderside':uv_part(mesh,lower,material('floor_wood_planks',(.77,.59,.39,1)),3)}
  elif name in ['dish_plate_fish','dish_bowl_soup']:
   # Only the upper, upward-facing contents receive the food artwork.
   food=(n[:,1]>.22)&(q[:,1]>(.18 if name=='dish_plate_fish' else .50))
   parts={'FoodOnTopOnly':bake(name,mesh.submesh([np.where(food)[0]],append=True)), 'CeramicRimOutsideAndBottom':uv_part(mesh,~food,material('wall_plaster_old',(.67,.73,.65,1)),3)}
  else:
   # The eye/paint may remain on the exposed side; keel/deck/interior use wood.
   detail=facing&(abs(n[:,1])<.45)&(q[:,1]>.20)
   parts={'SidePaintAndEyes':bake(name,mesh.submesh([np.where(detail)[0]],append=True)), 'WoodKeelDeckAndInnerHull':uv_part(mesh,~detail,material('floor_wood_planks',(.66,.74,.50,1)),3)}
  save(name,parts,'Six-direction semantic pass: only true front/food detail keeps artwork; broad backs, lids, rims and undersides use own tiled material, never a complete concept photo.')


if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--phase',choices=['coverage','fabric','tree','cart','signs','underside','structures','all'],default='all');a=p.parse_args()
 for phase,fn in [('coverage',generic),('fabric',fabric),('tree',tree),('cart',cart),('signs',signs),('underside',underside),('structures',structures)]:
  if a.phase in [phase,'all']:fn()
