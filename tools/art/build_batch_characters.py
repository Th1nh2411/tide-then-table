"""Finish inferred batch people: preserve geometry, add palette and weighted motion without Blender."""
from pathlib import Path
from datetime import datetime
import json, math, struct, shutil, hashlib
import numpy as np
from glb_common import load_mesh, backup
ROOT=Path(__file__).resolve().parents[2]
CONFIG={
 'bao':dict(height=1.72,Shirt='d27b47'),
 'vy':dict(height=1.60,Skin='dfb391',Shirt='d99eac',Shoes='e7dfce'),
 'vy_sau':dict(height=1.60,Skin='dfb391',Shirt='d99eac',Shoes='e7dfce'),
 'co_nam':dict(height=1.58,Shirt='648247',Bottom='493e39'),
 'ong_tam':dict(height=1.62,Skin='b98b67',Shirt='87684f',Hair='b5b7b1'),
 'guest_1':dict(height=1.70,Shirt='4c7662',Bottom='3c506c',Shoes='d7d1c5'),
 'guest_2':dict(height=1.58,Shirt='e4ddcf',Bottom='40536e',Shoes='ddd8ca'),
 'guest_3':dict(height=1.68,Shirt='858a86'),
 'guest_rich':dict(height=1.72,Shirt='d6a349',Tie='983e3a'),
 'guest_regular':dict(height=1.68,Shirt='657a54',Bottom='8f8669',Hair='72766f'),
 'staff':dict(height=1.68,Apron='48685b')}
def build(asset):
 config=CONFIG[asset]
 SOURCE=ROOT/f'assets/models/batch/characters/{asset}/{asset}_reduced.glb'
 OUT=ROOT/f'assets/models/ready/{asset}'
 OUT.mkdir(parents=True,exist_ok=True)
 for path in OUT.glob('*'):backup(path)
 r=SOURCE.read_bytes()
 points,faces=load_mesh(SOURCE)
 mn,mx=points.min(0),points.max(0)
 points-=[(mn[0]+mx[0])/2,mn[1],(mn[2]+mx[2])/2]
 points*=1.84/(mx[1]-mn[1])
 PALETTE=dict(Skin='cc9b76',Shirt='e4dcc9',Apron='e6ddc7',Bottom='343e4b',Hair='252d3b',Shoes='33363c')
 PALETTE.update({k:v for k,v in config.items() if k!='height'})
 colors={n:np.array([int(c[i:i+2],16) for i in (0,2,4)],float) for n,c in PALETTE.items()}
 def linear(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
 materials=[{'name':asset+'_'+name,'pbrMetallicRoughness':{'baseColorFactor':[linear(float(c)/255) for c in color]+[1],'metallicFactor':0,'roughnessFactor':.88}} for name,color in colors.items()]
 mat_ids={n:i for i,n in enumerate(colors)}
 def region(p,n):
  x,y,z=p;ax=abs(x)
  female=asset in ('vy','vy_sau','guest_2')
  if y>1.56:
   if y>1.72 or (z<-.025 and y>1.59) or (female and ax>.13 and z<.025):return 'Hair'
   return 'Skin'
  if female and z<-.055 and y>1.02 and ax<.25:return 'Hair'
  if y>1.48 and ax<.14:return 'Skin'
  arm=.64<y<1.51 and ax>(.23 if y>1.27 else .23+(1.27-y)*.29)
  if arm:return 'Shirt' if y>(1.02 if asset in ('ong_tam','guest_rich') else 1.27) else 'Skin'
  if y<.10:return 'Shoes'
  if asset in ('vy','vy_sau'):
   hem=.85 if asset=='vy' else .51
   if y<hem:return 'Skin'
   if y<1.08:return 'Apron'
   if y>1.37 and ax<.06 and z>0:return 'Skin'
   return 'Shirt'
  if asset=='bao':
   if y<.56:return 'Bottom'
   if z>-.015 and ax<(.235 if y<1.1 else .185) and y<1.40:return 'Apron'
   return 'Shirt' if y>.97 else 'Bottom'
  if asset=='staff' and .61<y<1.04 and ax<.24:return 'Apron'
  if asset=='guest_rich' and 1.03<y<1.45 and ax<.035 and z>0:return 'Tie'
  if asset=='ong_tam' and y<.21:return 'Skin'
  if y<.98:return 'Bottom'
  if y>1.39 and ax<.045 and z>0:return 'Skin'
  return 'Shirt'
 bones=[];ids={}
 def bone(name,p,parent=None):ids[name]=len(bones);bones.append((name,np.array(p,float),parent))
 bone('Root',(0,0,0));bone('Hips',(0,.92,-.03),'Root');bone('Spine',(0,1.10,-.035),'Hips');bone('Chest',(0,1.32,-.03),'Spine');bone('Neck',(0,1.50,-.02),'Chest');bone('Head',(0,1.62,-.01),'Neck')
 for sign,tag in [(-1,'R'),(1,'L')]:
  bone('Clavicle.'+tag,(sign*.10,1.415,-.03),'Chest')
  bone('UpperArm.'+tag,(sign*.205,1.405,-.03),'Clavicle.'+tag)
  bone('Forearm.'+tag,(sign*.345,1.10,-.025),'UpperArm.'+tag)
  bone('Hand.'+tag,(sign*.438,.79,-.025),'Forearm.'+tag)
  bone('Thigh.'+tag,(sign*.14,.91,-.03),'Hips')
  bone('Shin.'+tag,(sign*.177,.48,-.045),'Thigh.'+tag)
  bone('Foot.'+tag,(sign*.193,.11,-.025),'Shin.'+tag)
 def smooth(a,b,x):
  t=float(np.clip((x-a)/(b-a),0,1));return t*t*(3-2*t)
 def segment_dist(p,a,b):
  d=b-a;t=float(np.clip(np.dot(p-a,d)/np.dot(d,d),0,1));return float(np.linalg.norm(p-(a+t*d)))
 def segment_weights(p,segments):
  result={name:(segment_dist(p,np.array(a),np.array(b))+.035)**-4 for name,a,b in segments}
  total=sum(result.values());return {n:w/total for n,w in result.items()}
 def combine(a,b,t):
  out={n:v*(1-t) for n,v in a.items()}
  for n,v in b.items():out[n]=out.get(n,0)+v*t
  return out
 def torso_weights(y):
  if y<1.05:return {'Hips':1}
  if y<1.23:
   t=smooth(1.05,1.23,y);return {'Spine':1-t,'Chest':t}
  if y<1.43:return {'Chest':1}
  t=smooth(1.43,1.54,y);return {'Chest':1-t,'Neck':t}
 def vertex_weights(p):
  x,y,z=p;sign=1 if x>=0 else -1;tag='L' if sign==1 else 'R';ax=abs(x)
  if y<.10:return {'Foot.'+tag:1}
  if y>=1.56:return {'Head':1}
  if y>=1.48 and ax<.14:
   t=smooth(1.48,1.56,y);return {'Neck':1-t,'Head':t}
  if y<1.0 and ax<.30:
   hip=bones[ids['Thigh.'+tag]][1];knee=bones[ids['Shin.'+tag]][1];ankle=bones[ids['Foot.'+tag]][1]
   leg=segment_weights(p,[('Thigh.'+tag,hip,knee),('Shin.'+tag,knee,ankle),('Foot.'+tag,ankle,(sign*.20,.04,.10))])
   if y<.10:return {'Foot.'+tag:1}
   t=1-smooth(.74,.95,y)
   if ax<.055:t*=smooth(.015,.055,ax)
   return combine({'Hips':1},leg,t)
  base=torso_weights(y)
  if .64<y<1.51:
   clav=bones[ids['Clavicle.'+tag]][1];shoulder=bones[ids['UpperArm.'+tag]][1];elbow=bones[ids['Forearm.'+tag]][1];wrist=bones[ids['Hand.'+tag]][1]
   arm=segment_weights(p,[('Clavicle.'+tag,clav,shoulder),('UpperArm.'+tag,shoulder,elbow),('Forearm.'+tag,elbow,wrist),('Hand.'+tag,wrist,(sign*.435,.69,-.02))])
   width=.215+.03*smooth(1.28,1.46,y)
   t=smooth(width-.005,width+.045,ax)
   base=combine(base,arm,t)
  return base
 skin_weights=[]
 for p in points:
  w=sorted(((ids[n],v) for n,v in vertex_weights(p).items() if v>1e-8),key=lambda x:-x[1])[:4]
  total=sum(v for _,v in w);skin_weights.append(([n for n,_ in w]+[0]*(4-len(w)),[v/total for _,v in w]+[0]*(4-len(w))))

 def unit(p):return p/max(np.linalg.norm(p),1e-12)
 def quat(axis=(1,0,0),angle=0):return np.r_[unit(np.array(axis,float))*math.sin(angle/2),math.cos(angle/2)]
 def mul(a,b):return np.r_[a[3]*b[:3]+b[3]*a[:3]+np.cross(a[:3],b[:3]),a[3]*b[3]-np.dot(a[:3],b[:3])]
 def inv(q):return np.r_[-q[:3],q[3]]
 def fromto(a,b):
  a=unit(np.array(a,float));b=unit(np.array(b,float));d=np.dot(a,b)
  if d<-.9999:
   axis=np.cross(a,np.array((0,0,1)))
   if np.linalg.norm(axis)<.01:axis=np.cross(a,np.array((0,1,0)))
   return quat(axis,math.pi)
  return unit(np.r_[np.cross(a,b),1+d])
 def arm_ik(tag,target,raised=False):
  sign=1 if tag=='L' else -1;start=bones[ids['UpperArm.'+tag]][1];elbow=bones[ids['Forearm.'+tag]][1];wrist=bones[ids['Hand.'+tag]][1]
  target=np.array(target,float)*body_scale;d=np.linalg.norm(target-start);axis=unit(target-start);l1=np.linalg.norm(elbow-start);l2=np.linalg.norm(wrist-elbow);d=min(d,l1+l2-.001)
  along=(l1*l1-l2*l2+d*d)/(2*d);h=math.sqrt(max(0,l1*l1-along*along))
  pole=np.array((sign*.5,-1,-.4));pole=unit(pole-axis*np.dot(pole,axis));joint=start+axis*along+pole*h
  upper=fromto(elbow-start,joint-start);lower=fromto(wrist-elbow,target-joint)
  hand=fromto((0,-1,0),(0,1,0) if raised else (0,0,1))
  return upper,mul(inv(upper),lower),mul(inv(lower),hand)
 def pose(clip,phase):
  q={n:quat() for n,_,_ in bones}
  q['Chest']=quat((1,0,0),math.sin(phase)*.006)
  for sign,tag in [(-1,'R'),(1,'L')]:
   base=quat((0,0,1),-sign*.20);q['UpperArm.'+tag]=base
   if clip=='Walk':
    swing=sign*math.sin(phase)
    q['Thigh.'+tag]=quat((1,0,0),-.28*swing)
    q['Shin.'+tag]=quat((1,0,0),max(0,-swing)*.48)
    q['Foot.'+tag]=quat((1,0,0),-max(0,-swing)*.20)
    q['UpperArm.'+tag]=mul(quat((1,0,0),.19*swing),base)
   if clip=='Carry':
    target=(sign*.18,1.055,.37)
    q['UpperArm.'+tag],q['Forearm.'+tag],q['Hand.'+tag]=arm_ik(tag,target,False)
  return q

 binary=bytearray();views=[];accessors=[]
 def acc(data,component,kind,bounds=False,target=None):
  dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[component];array=np.asarray(data,dtype=dtype)
  while len(binary)%4:binary.append(0)
  offset=len(binary);raw=array.tobytes();binary.extend(raw)
  view={'buffer':0,'byteOffset':offset,'byteLength':len(raw)}
  if target:view['target']=target
  views.append(view);a={'bufferView':len(views)-1,'componentType':component,'count':len(array),'type':kind}
  if bounds:a.update(min=np.atleast_1d(array.min(0)).tolist(),max=np.atleast_1d(array.max(0)).tolist())
  accessors.append(a);return len(accessors)-1
 primitives=[];face_labels=[region(points[f].mean(0),None) for f in faces]
 body_scale=config['height']/1.84
 points*=body_scale
 bones=[(n,p*body_scale,parent) for n,p,parent in bones]
 for material in colors:
  positions=[];normals=[];joints=[];weights=[]
  for face,label in zip(faces,face_labels):
   if label!=material:continue
   p=points[face];normal=unit(np.cross(p[1]-p[0],p[2]-p[0]))
   for index,position in zip(face,p):
    positions.append(position);normals.append(normal);jj,ww=skin_weights[index];joints.append(jj);weights.append(ww)
  if not positions:continue
  primitives.append({'attributes':{'POSITION':acc(positions,5126,'VEC3',True,34962),'NORMAL':acc(normals,5126,'VEC3',False,34962),'JOINTS_0':acc(joints,5123,'VEC4',False,34962),'WEIGHTS_0':acc(weights,5126,'VEC4',False,34962)},'indices':acc(np.arange(len(positions)),5125,'SCALAR',False,34963),'material':mat_ids[material]})
 nodes=[]
 for name,p,parent in bones:
  relative=p-bones[ids[parent]][1] if parent else p
  node={'name':name,'translation':relative.tolist()};children=[i for i,(_,_,p_) in enumerate(bones) if p_==name]
  if children:node['children']=children
  nodes.append(node)
 inverse=[]
 for _,p,_ in bones:
  matrix=np.eye(4);matrix[:3,3]=-p;inverse.append(matrix.T.flatten())
 skin={'name':f'Batch_{asset}Skin','joints':list(range(len(bones))),'skeleton':0,'inverseBindMatrices':acc(inverse,5126,'MAT4')}
 nodes.append({'name':f'Batch_{asset}Mesh','mesh':0,'skin':0})
 animations=[]
 for clip,duration in [('Idle',2),('Walk',1.0),('Carry',2)]:
  times=np.linspace(0,duration,61 if clip!='Walk' else 31);a_time=acc(times,5126,'SCALAR',True);poses=[pose(clip,float(t/duration*math.tau)) for t in times];samplers=[];channels=[]
  for name,_,_ in bones:
   data=[];previous=None
   for p in poses:
    q=p[name]
    if previous is not None and np.dot(previous,q)<0:q=-q
    data.append(q);previous=q
   output=acc(data,5126,'VEC4');samplers.append({'input':a_time,'output':output,'interpolation':'LINEAR'});channels.append({'sampler':len(samplers)-1,'target':{'node':ids[name],'path':'rotation'}})
  animations.append({'name':clip,'samplers':samplers,'channels':channels})
 result={'asset':{'version':'2.0','generator':'Hunyuan3D-2mini-turbo inferred shape; Batch_{asset} material/rig processor (Python/NumPy)'},'scene':0,'scenes':[{'name':f'Batch_{asset}','nodes':[0,len(bones)]}],'nodes':nodes,'meshes':[{'name':f'Batch_{asset}Mesh','primitives':primitives}],'materials':materials,'skins':[skin],'animations':animations,'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(binary)}]}
 j=json.dumps(result,separators=(',',':')).encode();j+=b' '*((-len(j))%4);binary.extend(b'\0'*((-len(binary))%4));length=12+8+len(j)+8+len(binary)
 data=struct.pack('<III',0x46546c67,2,length)+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(binary),0x004e4942)+binary
 (OUT/(asset+'.glb')).write_bytes(data)
 metrics={'triangles':len(faces),'source_vertices':len(points),'mesh_count':1,'surfaces':len(primitives),'bones':len(bones),'animations':[a['name'] for a in animations],'height_m':config['height'],'material_faces':{m:face_labels.count(m) for m in colors}}
 (OUT/'metrics.json').write_text(json.dumps(metrics,indent=2)+'\n')
 provenance={'date':'2026-10-29','source_mesh':SOURCE.relative_to(ROOT).as_posix(),'source_sha256':hashlib.sha256(r).hexdigest(),'source_method':'Hunyuan3D-2mini-turbo local inference; see original source provenance','image_reference':f'assets/concepts/3d_queue/characters/{asset}.png','processing':'Uniform normalization; anatomical flat palette; weighted 20-bone skin and authored Idle/Walk/Carry animation. Source triangles preserved.','blender_used':False,'external_base_geometry_used':False,'output_sha256':hashlib.sha256(data).hexdigest()}
 (OUT/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
 notice=SOURCE.parent/'LICENSE-HUNYUAN.txt'
 if notice.exists():shutil.copy2(notice,OUT/notice.name)
 print(asset,json.dumps(metrics))
 # Reapply reviewed eyes/palette and X-only Walk when regenerating a character.
 from narrow_character_walk import patch
 patch(asset,use_current_source=True)
if __name__=='__main__':
 import sys
 for asset in sys.argv[1:] or CONFIG:build(asset)
