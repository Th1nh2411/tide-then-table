"""Prepare a real Hunyuan basket-boat mesh for Godot; no mesh synthesis/Blender.
Keeps all generated vertices/triangles, bakes a documented scale transform and
assigns flat, lit palette materials. Raw/reduced inference files are preserved.
"""
from pathlib import Path
from datetime import datetime
import hashlib,json,struct,shutil
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/models/ready/thuyen_thung'
source=OUT/'thuyen_thung_reduced.glb'
target=OUT/'thuyen_thung.glb'
raw=source.read_bytes();size=struct.unpack_from('<I',raw,12)[0]
doc=json.loads(raw[20:20+size]);bo=20+size
binary=raw[bo+8:bo+8+doc['buffers'][0]['byteLength']]
def read(index):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
 assert 'byteStride' not in v and 'sparse' not in a
 width={'SCALAR':1,'VEC3':3}[a['type']]
 return np.frombuffer(binary,dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']],count=a['count']*width,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).copy().reshape(a['count'],width)
primitive=doc['meshes'][0]['primitives'][0]
positions=read(primitive['attributes']['POSITION']).astype(float)
indices=read(primitive['indices']).reshape(-1,3).astype(int)
minimum,maximum=positions.min(axis=0),positions.max(axis=0)
center=(minimum+maximum)/2
scale_xz=2.4/max(maximum[0]-minimum[0],maximum[2]-minimum[2])
scale_y=.535/(maximum[1]-minimum[1])
positions[:,0]=(positions[:,0]-center[0])*scale_xz
positions[:,2]=(positions[:,2]-center[2])*scale_xz
positions[:,1]=(positions[:,1]-minimum[1])*scale_y+.025
# Remove small reconstruction ripples on the low interior floor only. This
# relaxes existing inferred vertices; rim, bench, topology and face count stay.
neighbor=[set() for _ in positions]
for a,b,c in indices:
 neighbor[a].update([b,c]);neighbor[b].update([a,c]);neighbor[c].update([a,b])
floor_mask=(np.linalg.norm(positions[:,[0,2]],axis=1)<.75)&(positions[:,1]>.035)&(positions[:,1]<.14)
for step in range(6):
 previous=positions.copy();factor=.38 if step%2==0 else -.39
 for i in np.flatnonzero(floor_mask):
  if neighbor[i]:positions[i]+=factor*(previous[list(neighbor[i])].mean(axis=0)-previous[i])
# Measure the topmost surface under a grid inside the rim. This detects a lid.
def top_y(x,z):
 a,b,c=positions[indices[:,0]],positions[indices[:,1]],positions[indices[:,2]]
 denominator=(b[:,2]-c[:,2])*(a[:,0]-c[:,0])+(c[:,0]-b[:,0])*(a[:,2]-c[:,2])
 valid=np.abs(denominator)>1e-12
 den=np.where(valid,denominator,1)
 w1=((b[:,2]-c[:,2])*(x-c[:,0])+(c[:,0]-b[:,0])*(z-c[:,2]))/den
 w2=((c[:,2]-a[:,2])*(x-c[:,0])+(a[:,0]-c[:,0])*(z-c[:,2]))/den
 w3=1-w1-w2
 hit=valid&(w1>=-1e-6)&(w2>=-1e-6)&(w3>=-1e-6)
 heights=w1[hit]*a[hit,1]+w2[hit]*b[hit,1]+w3[hit]*c[hit,1]
 return float(heights.max()) if len(heights) else None
samples=[top_y(float(x),float(z)) for x in np.linspace(-.6,.6,7) for z in np.linspace(-.6,.6,7) if x*x+z*z<.60**2]
valid=[y for y in samples if y is not None]
hollow_fraction=sum(y<.34 for y in valid)/max(1,len(valid))
assert hollow_fraction>.5, f'Interior appears filled: low-floor fraction={hollow_fraction:.2f}'
# Topology is unchanged. Face normals produce deliberate low-poly planes.
PALETTE={'Tarred_Hull':'685448','Bamboo_Wall':'96754d','Bamboo_Rim':'b49260','Interior_Floor':'a48961','Bench':'c09473','Inner_Wall':'a28257'}
materials=[]
def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
for name,color in PALETTE.items():
 rgb=[linear(int(color[i:i+2],16)/255) for i in (0,2,4)]
 materials.append({'name':'Thung_'+name,'doubleSided':False,'pbrMetallicRoughness':{'baseColorFactor':rgb+[1],'roughnessFactor':.93,'metallicFactor':0}})
mat_ids={name:i for i,name in enumerate(PALETTE)}
groups={name:[] for name in PALETTE}
for triangle in indices:
 p=positions[triangle];center_face=p.mean(axis=0);normal=np.cross(p[1]-p[0],p[2]-p[0]);length=np.linalg.norm(normal)
 if length<1e-12:raise ValueError('Degenerate input face; require inference cleanup')
 normal/=length;r=np.linalg.norm(center_face[[0,2]])
 radial=np.dot(normal[[0,2]],center_face[[0,2]])/max(r,1e-6)
 if center_face[1]>.465:material='Bamboo_Rim'
 elif normal[1]>.65 and center_face[1]>.15 and r<.98:material='Bench'
 elif center_face[1]<.22 and r<.90 and normal[1]>.2:material='Interior_Floor'
 elif radial<-.15:material='Inner_Wall'
 elif center_face[1]<.23:material='Tarred_Hull'
 else:material='Bamboo_Wall'
 groups[material].append((p,normal))
blob=bytearray();views=[];accessors=[]
def accessor(data,component,kind,target):
 array=np.asarray(data,dtype={5126:'<f4',5125:'<u4'}[component])
 blob.extend(b'\0'*((-len(blob))%4));offset=len(blob);chunk=array.tobytes();blob.extend(chunk)
 views.append({'buffer':0,'byteOffset':offset,'byteLength':len(chunk),'target':target})
 a={'bufferView':len(views)-1,'componentType':component,'count':len(array),'type':kind}
 if kind=='VEC3':a.update({'min':array.min(axis=0).tolist(),'max':array.max(axis=0).tolist()})
 accessors.append(a);return len(accessors)-1
primitives=[]
for name,group in groups.items():
 if not group:continue
 vv=np.concatenate([p for p,n in group]);nn=np.concatenate([np.tile(n,(3,1)) for p,n in group])
 primitives.append({'attributes':{'POSITION':accessor(vv,5126,'VEC3',34962),'NORMAL':accessor(nn,5126,'VEC3',34962)},'indices':accessor(np.arange(len(vv)),5125,'SCALAR',34963),'material':mat_ids[name]})
outdoc={'asset':{'version':'2.0','generator':'Hunyuan image-to-shape; affine normalization and palette only, no synthesized hull'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'name':'ThuyenThung','mesh':0}],'meshes':[{'name':'ThuyenThung_Hunyuan','primitives':primitives}],'materials':materials,'buffers':[{'byteLength':len(blob)}],'bufferViews':views,'accessors':accessors}
js=json.dumps(outdoc,separators=(',',':')).encode();js+=b' '*((-len(js))%4);blob.extend(b'\0'*((-len(blob))%4))
result=struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob
if target.exists():
 backup=ROOT/'build/art_pilots/backups'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')/target.name;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,backup)
target.write_bytes(result)
meta={'source':source.name,'source_sha256':hashlib.sha256(raw).hexdigest(),'output':target.name,'output_sha256':hashlib.sha256(result).hexdigest(),'triangles':len(indices),'surfaces':len(primitives),'dimensions_m':(positions.max(axis=0)-positions.min(axis=0)).tolist(),'origin':'center X/Z; bottom Y=.025, rim Y=.560','changes':['Affine scale/centering; same 2400 generated triangles','Constrained relaxation of existing low interior-floor vertices; rim/bench unchanged','Flat face normals','Palette materials by height/normal/interior region'],'hollow_check':{'sample_count':len(valid),'top_rim_y':.56,'interior_floor_below_y':.34,'low_interior_fraction':hollow_fraction,'center_top_y':top_y(0,0),'sample_top_y_range':[min(valid),max(valid)]},'blender_used':False,'mesh_synthesis_used':False}
(OUT/'prepared_provenance.json').write_text(json.dumps(meta,indent=2)+'\n')
print('BOAT_PREPARED',json.dumps(meta))
