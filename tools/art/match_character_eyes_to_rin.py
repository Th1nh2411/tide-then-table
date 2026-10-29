"""Surface-fit Rin's actual black Eye primitive to a batch character.
Keeps approved body/hair/material assignments, rig, clips, eyebrows and glasses.
"""
import copy,hashlib,json
import numpy as np
from glb_common import ROOT,load_glb,read_accessor,write_document,backup,_matrix
IDS=('bao','vy','vy_sau','co_nam','ong_tam','guest_1','guest_2','guest_3','guest_rich','guest_regular','staff')


def surface(triangles,x,y):
    a,b,c=np.asarray(triangles).transpose(1,0,2)
    den=(b[:,1]-c[:,1])*(a[:,0]-c[:,0])+(c[:,0]-b[:,0])*(a[:,1]-c[:,1])
    valid=abs(den)>1e-12;den=np.where(valid,den,1.)
    u=((b[:,1]-c[:,1])*(x-c[:,0])+(c[:,0]-b[:,0])*(y-c[:,1]))/den
    v=((c[:,1]-a[:,1])*(x-c[:,0])+(a[:,0]-c[:,0])*(y-c[:,1]))/den
    valid &= (u>=-1e-6)&(v>=-1e-6)&(u+v<=1+1e-6)
    z=u*a[:,2]+v*b[:,2]+(1-u-v)*c[:,2]
    return float(z[valid].max()) if valid.any() else None


def match(asset,use_saved_fit=False,centers_override=None):
    assert asset in IDS
    folder=ROOT/'assets/models/ready'/asset;path=folder/(asset+'.glb')
    doc,raw=load_glb(path);meta_path=folder/'provenance.json';meta=json.loads(meta_path.read_text())
    face=next((m for m in doc['meshes'] if 'CharacterFaceDetails' in m.get('name','')),None)
    if face is None:
        # Manual exports can omit the entire eye object. Add only the missing detail;
        # retain body/materials, native animation payload and the original armature.
        skin_id=next(n['skin'] for n in doc['nodes'] if 'mesh' in n and 'skin' in n)
        face={'name':'CharacterFaceDetails','primitives':[]}
        mesh_id=len(doc['meshes']);doc['meshes'].append(face)
        node_id=len(doc['nodes']);doc['nodes'].append({'name':'CharacterFaceDetails','mesh':mesh_id,'skin':skin_id})
        doc['scenes'][doc.get('scene',0)]['nodes'].append(node_id)
    marker=doc.get('extras',{}).get('character_rin_eye_style')
    cached_fit=bool(marker)
    if marker:
        for key,count in marker['counts'].items():doc[key]=doc[key][:count]
        face['primitives']=copy.deepcopy(marker['primitives'])
        length=marker['binary_length']
    else:
        length=doc['buffers'][0]['byteLength']
        marker={'counts':{k:len(doc[k]) for k in ['materials','accessors','bufferViews']},'binary_length':length,'primitives':copy.deepcopy(face['primitives'])}
    binary=bytearray(raw[:length])
    donor_path=ROOT/'assets/models/ready/rin/rin_pilot.glb';donor,db=load_glb(donor_path)
    node=next(i for i,n in enumerate(donor['nodes']) if 'mesh' in n and any(donor['materials'][p['material']]['name']=='Eye' for p in donor['meshes'][n['mesh']]['primitives']))
    original=next(p for p in donor['meshes'][donor['nodes'][node]['mesh']]['primitives'] if donor['materials'][p['material']]['name']=='Eye')
    parents={c:i for i,n in enumerate(donor['nodes']) for c in n.get('children',[])}
    def world(i):return (world(parents[i]) if i in parents else np.eye(4))@_matrix(donor['nodes'][i])
    w=world(node);dv=read_accessor(donor,db,original['attributes']['POSITION'])
    dv=(np.c_[dv,np.ones(len(dv))]@w.T)[:,:3]
    dn=read_accessor(donor,db,original['attributes']['NORMAL'])@np.linalg.inv(w[:3,:3]);dn/=np.linalg.norm(dn,axis=1,keepdims=True)
    di=read_accessor(donor,db,original['indices']).ravel().reshape(-1,3)
    previous=meta.get('rin_eye_style',{})
    centers=centers_override if centers_override is not None else (previous.get('centers') if use_saved_fit or cached_fit else None)
    if centers is None:
        old=next((p for p in face['primitives'] if any(key in doc['materials'][p['material']]['name'] for key in ['EyeWhite','RinEye'])),None)
        if old is not None:
            positions=read_accessor(doc,raw,old['attributes']['POSITION'])
            centers=[((positions[positions[:,0]*sign>0].min(0)+positions[positions[:,0]*sign>0].max(0))*.5)[:2].tolist() for sign in [-1,1]]
        elif previous.get('centers'):
            centers=previous['centers']
        else:
            from refine_character_faces import EYE_ANCHORS
            height=json.loads((folder/'metrics.json').read_text())['height_m']
            centers=(np.array(EYE_ANCHORS[asset])*height/1.84).tolist()
    height=json.loads((folder/'metrics.json').read_text())['height_m'];scale=height/1.8776532
    skin=[]
    for mesh in doc['meshes']:
        if 'FaceDetails' in mesh.get('name',''):continue
        for p in mesh['primitives']:
            if not doc['materials'][p['material']]['name'].split('.')[0].endswith('_Skin'):continue
            v=read_accessor(doc,raw,p['attributes']['POSITION']);idx=read_accessor(doc,raw,p['indices']).ravel()
            ts=v[idx].reshape(-1,3,3);skin.extend(ts[ts[:,:,1].mean(1)>height*.80])
    skin=np.array(skin);vertices=[];normals=[];clearances=[]
    for sign,(cx,cy) in zip([-1,1],centers):
        ids=np.flatnonzero(dv[:,0]*sign>0);points=dv[ids];origin=(points.min(0)+points.max(0))*.5
        front=ids[dn[ids,2]>dn[ids,2].max()*.98]
        assert len(front)>=3
        design=np.c_[dv[front,0]-origin[0],dv[front,1]-origin[1],np.ones(len(front))]
        donor_plane=np.linalg.lstsq(design,dv[front,2],rcond=None)[0]
        low=(points.min(0)[:2]-origin[:2])*scale;high=(points.max(0)[:2]-origin[:2])*scale
        samples=[]
        for dx in np.linspace(low[0],high[0],15):
            for dy in np.linspace(low[1],high[1],15):
                z=surface(skin,cx+dx,cy+dy)
                if z is not None:samples.append([dx,dy,z])
        samples=np.array(samples);assert len(samples)>30,asset+': eye lies outside face'
        design=np.c_[samples[:,:2],np.ones(len(samples))]
        plane=np.linalg.lstsq(design,samples[:,2],rcond=None)[0]
        plane[2]+=max(0.,float((samples[:,2]-design@plane).max()))+.0015
        eye=[];front_faces=[]
        for tri in di[dv[di,0].mean(1)*sign>0]:
            output=[]
            for idx in tri:
                dx,dy=(dv[idx,:2]-origin[:2])*scale
                source_z=donor_plane[0]*(dv[idx,0]-origin[0])+donor_plane[1]*(dv[idx,1]-origin[1])+donor_plane[2]
                depth=(dv[idx,2]-source_z)*scale
                output.append([cx+dx,cy+dy,plane[0]*dx+plane[1]*dy+plane[2]+depth])
            eye.append(output)
            front_faces.append(bool(np.all(dn[tri,2]>dn[ids,2].max()*.98)))
        eye=np.array(eye);front_faces=np.array(front_faces);required=0.
        assert front_faces.any(), asset+': no front eye surface'
        for dx,dy,z in samples:
            eye_z=surface(eye[front_faces],cx+dx,cy+dy)
            if eye_z is not None:required=max(required,z+.0015-eye_z)
        if required>0:eye[:,:,2]+=required
        clearance=[]
        for dx,dy,z in samples:
            eye_z=surface(eye[front_faces],cx+dx,cy+dy)
            if eye_z is not None:clearance.append(eye_z-z)
        assert min(clearance)>.0013,(asset,'eye intersects skin')
        clearances.append({'minimum_m':min(clearance),'maximum_m':max(clearance),'samples':len(clearance)})
        for tri in eye:
            n=np.cross(tri[1]-tri[0],tri[2]-tri[0]);n/=np.linalg.norm(n)
            vertices.extend(tri);normals.extend([n]*3)
    def append(values,kind,component=5126):
        array=np.asarray(values,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[component])
        while len(binary)%4:binary.append(0)
        offset=len(binary);binary.extend(array.tobytes());view=len(doc['bufferViews'])
        doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':array.nbytes})
        a={'bufferView':view,'componentType':component,'count':len(array),'type':kind}
        if kind=='VEC3':a.update(min=array.min(0).tolist(),max=array.max(0).tolist())
        index=len(doc['accessors']);doc['accessors'].append(a);return index
    face_index=next(i for i,m in enumerate(doc['meshes']) if m is face)
    face_node=next(n for n in doc['nodes'] if n.get('mesh')==face_index)
    skin_id=face_node['skin'];head=next(i for i,n in enumerate(doc['skins'][skin_id]['joints']) if doc['nodes'][n].get('name')=='Head')
    joints=np.zeros((len(vertices),4),np.uint16);joints[:,0]=head
    weights=np.zeros((len(vertices),4));weights[:,0]=1
    attrs={'POSITION':append(vertices,'VEC3'),'NORMAL':append(normals,'VEC3'),'JOINTS_0':append(joints,'VEC4',5123),'WEIGHTS_0':append(weights,'VEC4')}
    material=copy.deepcopy(donor['materials'][original['material']]);material['name']=asset+'_RinEye'
    mi=len(doc['materials']);doc['materials'].append(material)
    face['primitives']=[p for p in face['primitives'] if any(key in doc['materials'][p['material']]['name'] for key in ['Brow','Frame'])]
    face['primitives'].append({'attributes':attrs,'indices':append(np.arange(len(vertices)),'SCALAR',5125),'material':mi})
    doc.setdefault('extras',{})['character_rin_eye_style']=marker
    write_document(path,doc,binary)
    count=sum(read_accessor(doc,bytes(binary),p['indices']).size//3 for p in face['primitives'])
    backup(meta_path);meta['output_sha256']=hashlib.sha256(path.read_bytes()).hexdigest();meta['face_detail_triangles']=count
    if 'face_refinement' in meta:
        size=min(meta['face_refinement']['base_binary_length'],length)
        meta['face_refinement'].update(base_binary_length=size,base_binary_sha256=hashlib.sha256(bytes(binary[:size])).hexdigest())
    meta['rin_eye_style']={'reference':'assets/models/ready/rin/rin_pilot.glb','reference_sha256':hashlib.sha256(donor_path.read_bytes()).hexdigest(),
                         'centers':centers,'clearance':clearances,'builder':'tools/art/match_character_eyes_to_rin.py','changes':'Actual Rin Eye geometry/material; independently fit each eye to skin, preserve XY centers/brows/glasses'}
    meta_path.write_text(json.dumps(meta,indent=2)+'\n')
    metrics_path=folder/'metrics.json';backup(metrics_path);metrics=json.loads(metrics_path.read_text())
    metrics.update(mesh_count=len(doc['meshes']),face_detail_triangles=count,triangles=metrics['body_triangles']+count,surfaces=sum(len(m['primitives']) for m in doc['meshes']))
    metrics_path.write_text(json.dumps(metrics,indent=2)+'\n')
    print(asset,'Rin eye style; minimum skin clearance',min(c['minimum_m'] for c in clearances))


if __name__=='__main__':
    import sys
    for asset in sys.argv[1:] or IDS:match(asset)
