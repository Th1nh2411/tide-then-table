"""Colour and rig the real Hunyuan Rin mesh using NumPy; no Blender or base mesh.
Source positions/triangles are preserved apart from uniform unit normalization.
"""
from pathlib import Path
from datetime import datetime
import json, math, struct, shutil, hashlib
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets/models/characters/rin_hunyuan_shape/rin_hunyuan_3k_lit.glb'
IMAGE=ROOT/'assets/models/characters/rin_hunyuan_shape/input_front.png'
OUT=ROOT/'assets/models/pilots/rin'
REVIEW=ROOT/'build/art_pilots/rin'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
for p in [OUT/'rin_pilot.glb',OUT/'metrics.json',OUT/'provenance.json']:
 if p.exists():
  backup=REVIEW/'backups'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')/p.name
  backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup)
r=SOURCE.read_bytes();jn=struct.unpack_from('<I',r,12)[0];doc=json.loads(r[20:20+jn]);blob=r[28+jn:]
def read(index):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
 dt={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']]
 width={'SCALAR':1,'VEC3':3}[a['type']]
 return np.frombuffer(blob,dtype=dt,count=a['count']*width,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).copy().reshape(-1,width)
primitive=doc['meshes'][0]['primitives'][0]
points=read(primitive['attributes']['POSITION']).astype(float)
faces=read(primitive['indices']).reshape(-1,3).astype(int)
mn,mx=points.min(0),points.max(0);scale=1.84/(mx[1]-mn[1])
points[:,0]-=(mn[0]+mx[0])/2;points[:,2]-=(mn[2]+mx[2])/2;points[:,1]-=mn[1];points*=scale
pixels=np.asarray(Image.open(IMAGE).convert('RGB'),dtype=float)

PALETTE={'Skin':'ca956b','Ivory':'e8dfca','Navy':'303b4d','Hair':'202a3a','Frame':'1d2530','Sandal':'35363b','Silver':'bcc2bb'}
def rgb(hex):return np.array([int(hex[i:i+2],16) for i in (0,2,4)],float)
colors={name:rgb(color) for name,color in PALETTE.items()}
def linear(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
materials=[]
for name,color in colors.items():
 materials.append({'name':'RinPilot_'+name,'doubleSided':False,'pbrMetallicRoughness':{'baseColorFactor':[linear(float(c)/255) for c in color]+[1],'metallicFactor':.45 if name=='Silver' else 0,'roughnessFactor':.88}})
mat_ids={name:i for i,name in enumerate(colors)}
def projected(x,y):
 u=int(np.clip(31+(x/.93742776+.5)*(466-31),0,pixels.shape[1]-1));v=int(np.clip(895-y/1.84*(895-26),0,pixels.shape[0]-1))
 sample=np.median(pixels[max(0,v-1):v+2,max(0,u-1):u+2].reshape(-1,3),axis=0)
 # Saturation-less studio backdrop must not become a spurious cloth patch.
 if 60<sample.mean()<170 and max(sample)-min(sample)<25:return None
 return min(colors,key=lambda key:float(np.linalg.norm(sample-colors[key])))
def region(p):
 x,y,z=p;ax=abs(x)
 # A-pose forearms sit outside the shorts. The threshold expands downward so
 # trouser sides are never accidentally painted as skin.
 arm=.65<y<1.48 and ax>(.22 if y>1.27 else .22+(1.27-y)*.30)
 if arm:return 'Skin'
 if y<.12:
  return 'Sandal' if y<.048 or (y<.078 and (abs(z-.045)<.020 or abs(z+.055)<.017)) else 'Skin'
 if y<.53:return 'Skin'
 if y<.955:return 'Navy'
 if y<1.49:
  if ax<.024 and 1.35<y<1.38 and z>.06:return 'Silver'
  # Clean colour panels follow the existing body surface: no overlapping cloth.
  neck=1.365+3.0*x*x if z>-.015 else 1.435+1.5*x*x
  if y>neck:return 'Skin'
  return 'Ivory'
 if y<1.57:return 'Skin'
 # Geometry-guided hair and glasses avoid projecting background pixels onto
 # the inferred side/rear surfaces or creating scattered dark face triangles.
 if z<-.015 and y>1.59:return 'Hair'
 if y>1.705:
  if z>.07 and x>.015 and y<1.74:return 'Skin'
  return 'Hair'
 if z>.03 and y>max(1.665,1.69+.30*x):return 'Hair'
 if 1.645<y<1.695 and z>.123:return 'Frame'
 return 'Skin'

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
 target=np.array(target,float);d=np.linalg.norm(target-start);axis=unit(target-start);l1=np.linalg.norm(elbow-start);l2=np.linalg.norm(wrist-elbow);d=min(d,l1+l2-.001)
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
  if clip in ('Carry','Raised'):
   target=(sign*.18,1.055,.37) if clip=='Carry' else (sign*.24,1.93,.10)
   q['UpperArm.'+tag],q['Forearm.'+tag],q['Hand.'+tag]=arm_ik(tag,target,clip=='Raised')
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
primitives=[];face_labels=[]
for f in faces:face_labels.append(region(points[f].mean(0)))
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
skin={'name':'RinPilotSkin','joints':list(range(len(bones))),'skeleton':0,'inverseBindMatrices':acc(inverse,5126,'MAT4')}
nodes.append({'name':'RinPilotMesh','mesh':0,'skin':0})
animations=[]
for clip,duration in [('Idle',2),('Walk',1.0),('Carry',2),('Raised',2)]:
 times=np.linspace(0,duration,61 if clip!='Walk' else 31);a_time=acc(times,5126,'SCALAR',True);poses=[pose(clip,float(t/duration*math.tau)) for t in times];samplers=[];channels=[]
 for name,_,_ in bones:
  data=[];previous=None
  for p in poses:
   q=p[name]
   if previous is not None and np.dot(previous,q)<0:q=-q
   data.append(q);previous=q
  output=acc(data,5126,'VEC4');samplers.append({'input':a_time,'output':output,'interpolation':'LINEAR'});channels.append({'sampler':len(samplers)-1,'target':{'node':ids[name],'path':'rotation'}})
 animations.append({'name':clip,'samplers':samplers,'channels':channels})
result={'asset':{'version':'2.0','generator':'Hunyuan3D-2.1 shape; RinPilot material/rig processor (Python/NumPy)'},'scene':0,'scenes':[{'name':'RinPilot','nodes':[0,len(bones)]}],'nodes':nodes,'meshes':[{'name':'RinPilotMesh','primitives':primitives}],'materials':materials,'skins':[skin],'animations':animations,'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(binary)}]}
j=json.dumps(result,separators=(',',':')).encode();j+=b' '*((-len(j))%4);binary.extend(b'\0'*((-len(binary))%4));length=12+8+len(j)+8+len(binary)
data=struct.pack('<III',0x46546c67,2,length)+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(binary),0x004e4942)+binary
(OUT/'rin_pilot.glb').write_bytes(data)
metrics={'triangles':len(faces),'source_vertices':len(points),'mesh_count':1,'surfaces':len(primitives),'bones':len(bones),'animations':[a['name'] for a in animations],'height_m':1.84,'material_faces':{m:face_labels.count(m) for m in colors}}
(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2)+'\n')
provenance={'date':'2026-10-28','source_mesh':str(SOURCE.relative_to(ROOT)),'source_sha256':hashlib.sha256(r).hexdigest(),'source_method':'Actual Tencent Hunyuan3D-2.1 inference, reduced by official Space to 3000 triangles','image_reference':str(IMAGE.relative_to(ROOT)),'concept':'assets/concepts/rin/lowpoly_turnaround_v1.png','processing':'Uniform normalization to 1.84m; flat palette per anatomical region/front image; 20-bone weighted skin and authored Idle/Walk/Carry/Raised clips; all source triangles preserved','blender_used':False,'external_base_geometry_used':False,'license':'Tencent Hunyuan 3D 2.1 Community License; source notice preserved','output_sha256':hashlib.sha256(data).hexdigest()}
(OUT/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
shutil.copy2(ROOT/'assets/models/characters/rin_hunyuan_shape/LICENSE-HUNYUAN.txt',OUT/'LICENSE-HUNYUAN.txt')
print('RIN_PILOT_OK',json.dumps(metrics))
