"""Refine non-Rin eye details and palette without rebuilding body mesh or animations.
Base positions, normals, weights, joint transforms and animations retain their binary data.
Only listed characters are accepted. Rin is deliberately excluded.
"""
from pathlib import Path
import copy, hashlib, json, math
import numpy as np
from glb_common import ROOT, load_glb, read_accessor, write_document, backup, material

PROFILES={
 'bao':dict(height=1.72,palette=dict(Skin='f3b578',Shirt='f5a23e',Apron='ede4d5',Hair='151d28'),reference='assets/sprites/portraits/bao/base.png'),
 'vy':dict(height=1.60,palette=dict(Skin='f1cda1',Shirt='f676ac',Apron='eee5d5',Hair='151d28',Shoes='f0e6d8'),female=True,reference='assets/sprites/portraits/vy/base.png'),
 'vy_sau':dict(height=1.60,palette=dict(Skin='f1cda1',Shirt='f676ac',Apron='eee5d5',Hair='151d28',Shoes='33363c'),female=True,reference='assets/sprites/portraits/vy/base.png'),
 'co_nam':dict(height=1.58,palette=dict(Skin='eaaa72',Shirt='697a4f',Hair='24242c',Bottom='493e39'),female=True,reference='assets/sprites/portraits/co_nam/base.png'),
 'ong_tam':dict(height=1.62,palette=dict(Skin='c09473',Shirt='7a4841',Hair='819796',Bottom='172038',Shoes='202e37'),reference='assets/sprites/portraits/ong_tam/base.png'),
 'guest_1':dict(height=1.70,palette=dict(Skin='d79c6b',Shirt='4c7662',Bottom='3c506c',Hair='151d28'),reference='assets/concepts/3d_queue/characters/guest_1.png'),
 'guest_2':dict(height=1.58,palette=dict(Skin='f1cda1',Shirt='e4ddcf',Bottom='40536e',Hair='151d28'),female=True,reference='assets/concepts/3d_queue/characters/guest_2.png'),
 'guest_3':dict(height=1.68,palette=dict(Skin='d79c6b',Shirt='858a86',Hair='151d28'),glasses=True,reference='assets/concepts/3d_queue/characters/guest_3.png'),
 'guest_rich':dict(height=1.72,palette=dict(Skin='d79c6b',Shirt='d6a349',Tie='983e3a',Hair='151d28'),glasses=True,reference='assets/concepts/3d_queue/characters/guest_rich.png'),
 'guest_regular':dict(height=1.68,palette=dict(Skin='c09473',Shirt='468232',Hair='577277',Bottom='172038'),reference='assets/sprites/portraits/khach_quen/base.png'),
 'staff':dict(height=1.68,palette=dict(Skin='d79c6b',Shirt='eee5d5',Apron='48685b',Hair='151d28'),glasses=True,reference='assets/concepts/3d_queue/characters/staff.png'),
 'cat':dict(height=.58,palette=dict(Orange='e9a05b',Cream='eed9b5',Eyes='e9a05b'),cat=True,reference='assets/concepts/3d_queue/props/cat.png'),
}


# Socket anchors fitted individually in the neutral head pose (1.84m canonical for people).
EYE_ANCHORS={'bao': [[-0.072355, 1.692587], [0.072355, 1.692587]], 'vy': [[-0.058315, 1.692587], [0.058315, 1.692587]], 'vy_sau': [[-0.062057, 1.692587], [0.062057, 1.692587]], 'co_nam': [[-0.073784, 1.692587], [0.073784, 1.692587]], 'ong_tam': [[-0.064378, 1.692588], [0.064378, 1.692587]], 'guest_1': [[-0.057993, 1.692588], [0.057993, 1.692588]], 'guest_2': [[-0.068562, 1.692587], [0.068562, 1.692587]], 'guest_3': [[-0.057862, 1.692587], [0.057862, 1.692587]], 'guest_rich': [[-0.050778, 1.692587], [0.050778, 1.692587]], 'guest_regular': [[-0.057447, 1.692587], [0.057447, 1.692587]], 'staff': [[-0.067546, 1.692587], [0.067546, 1.692587]], 'cat': [[-0.073, 0.464], [0.035, 0.464]]}


def refine(asset):
    assert asset in PROFILES and not asset.startswith('rin')
    profile=PROFILES[asset]
    folder=ROOT/'assets/models/ready'/asset
    path=folder/(asset+'.glb')
    doc,blob=load_glb(path)
    # A manual Blender export has no regeneration tag: retain all painted body data.
    if not profile.get('cat') and not doc.get('extras',{}).get('character_face_refinement') and any('CharacterFaceDetails' in m.get('name','') for m in doc['meshes']):
        from match_character_eyes_to_rin import match
        match(asset)
        return
    doc.get('extras',{}).pop('bao_rin_eye_style',None)
    doc.get('extras',{}).pop('character_rin_eye_style',None)
    tag=doc.get('extras',{}).get('character_face_refinement')
    if tag:
        # Remove this tool's previous appended payload for a repeatable, non-stacking edit.
        for key,count in tag['counts'].items():doc[key]=doc[key][:count]
        for scene,count in zip(doc['scenes'],tag['scene_roots']):scene['nodes']=scene['nodes'][:count]
        blob=blob[:tag['binary_length']]
    else:
        tag={'counts':{k:len(doc[k]) for k in ['nodes','meshes','materials','accessors','bufferViews']},
             'scene_roots':[len(s['nodes']) for s in doc['scenes']], 'binary_length':doc['buffers'][0]['byteLength']}
    if 'base_meshes' not in tag:tag['base_meshes']=copy.deepcopy(doc['meshes'])
    doc['meshes']=copy.deepcopy(tag['base_meshes'])
    binary=bytearray(blob[:tag['binary_length']])
    native_nodes=copy.deepcopy(doc['nodes'])
    native_animations=copy.deepcopy(doc.get('animations',[]))
    # Replace the old 24-triangle eye cubes; retain every actual body triangle.
    for mesh in doc['meshes']:
        mesh['primitives']=[p for p in mesh['primitives'] if doc['materials'][p['material']]['name']!='Eye']
    original_surfaces=copy.deepcopy(doc['meshes'])
    for m in doc['materials']:
        name=m['name'].removeprefix(asset+'_')
        if name in profile['palette']:
            m['pbrMetallicRoughness']['baseColorFactor']=material(name,profile['palette'][name])['pbrMetallicRoughness']['baseColorFactor']
    # Project detail onto the actual front skin surface; no eye markers on the hair or behind the face.
    triangles=[]
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            name=doc['materials'][p['material']]['name'].removeprefix(asset+'_')
            if not profile.get('cat') and name!='Skin':continue
            points=read_accessor(doc,blob,p['attributes']['POSITION'])
            indices=read_accessor(doc,blob,p['indices']).ravel()
            ts=points[indices].reshape(-1,3,3)
            triangles.extend(ts[ts[:,:,1].mean(1)>profile['height']*(.58 if profile.get('cat') else .82)])
    triangles=np.array(triangles)
    a,b,c=triangles[:,0],triangles[:,1],triangles[:,2]
    denominator=(b[:,1]-c[:,1])*(a[:,0]-c[:,0])+(c[:,0]-b[:,0])*(a[:,1]-c[:,1])
    valid=np.abs(denominator)>1e-12
    denominator=np.where(valid,denominator,1)
    def depth(x,y):
        u=((b[:,1]-c[:,1])*(x-c[:,0])+(c[:,0]-b[:,0])*(y-c[:,1]))/denominator
        v=((c[:,1]-a[:,1])*(x-c[:,0])+(a[:,0]-c[:,0])*(y-c[:,1]))/denominator
        good=valid&(u>=-1e-5)&(v>=-1e-5)&(u+v<=1+1e-5)
        z=u*a[:,2]+v*b[:,2]+(1-u-v)*c[:,2]
        if good.any():return float(z[good].max())
        centers=triangles.mean(1)
        nearest=np.argsort((centers[:,0]-x)**2+(centers[:,1]-y)**2)[:3]
        return float(centers[nearest,2].max())
    scale=profile['height']/1.84 if not profile.get('cat') else 1.
    ink='090a14';white='f0e6d8';iris='44352f'
    if profile.get('cat'):white='c3b382';iris='829b65'
    detail_palette={'EyeWhite':white,'Iris':iris,'Pupil':ink,'Highlight':'f7efdf','Brow':profile['palette'].get('Hair','34302d')}
    if profile.get('glasses'):detail_palette['Frame']=ink
    buffers={key:dict(p=[],n=[],i=[]) for key in detail_palette}
    eye_plane=None
    def face(key,xy,offset):
        def z(x,y):
            if eye_plane is not None and key!='Brow':
                cx,cy,coeff=eye_plane
                return coeff[0]*(x-cx)+coeff[1]*(y-cy)+coeff[2]
            return depth(x,y)
        points=np.array([(x,y,z(x,y)+offset) for x,y in xy])
        center=points.mean(0)
        out=buffers[key]
        for j in range(len(points)):
            tri=np.array([center,points[j],points[(j+1)%len(points)]])
            n=np.cross(tri[1]-tri[0],tri[2]-tri[0]);length=np.linalg.norm(n)
            if length<1e-12:continue
            n/=length
            if n[2]<0:tri=tri[[0,2,1]];n=-n
            first=len(out['p']);out['p'].extend(tri);out['n'].extend([n]*3);out['i'].extend([first,first+1,first+2])
    def ellipse(key,x,y,rx,ry,offset,count=10):
        face(key,[(x+rx*math.cos(j*math.tau/count),y+ry*math.sin(j*math.tau/count)) for j in range(count)],offset)
    def stroke(key,p,q,width,offset):
        p,q=np.array(p),np.array(q);d=q-p;side=np.array([-d[1],d[0]])/np.linalg.norm(d)*width/2
        face(key,[p-side,q-side,q+side,p+side],offset)
    eye_y=(1.665*scale) if not profile.get('cat') else .435
    eye_x=(.050*scale) if not profile.get('cat') else .073
    width=(.043*scale) if not profile.get('cat') else .045
    height=(.017*scale) if not profile.get('cat') else .019
    if profile.get('female'):height*=.92
    anchors=[]
    for side,anchor in zip([-1,1],EYE_ANCHORS[asset]):
        x,y=anchor if profile.get('cat') else np.array(anchor)*scale
        if profile.get('cat'):
            width=.045 if side<0 else .022
            height=.019 if side<0 else .014
        if not profile.get('cat'):y-=.008*scale
        # A shared fitted eye plane keeps iris/pupil in front of the almond white.
        xy=np.array([(x+dx*width,y+dy*height) for dx,dy in [(-.65,-1),(.65,-1),(.65,1),(-.65,1),(0,0)]])
        design=np.c_[xy[:,0]-x,xy[:,1]-y,np.ones(len(xy))]
        zs=np.array([depth(px,py) for px,py in xy])
        coeff=np.linalg.lstsq(design,zs,rcond=None)[0]
        coeff[2]+=max(0.,float((zs-design@coeff).max()))
        eye_plane=(x,y,coeff)
        anchors.append([x,y,float(coeff[2])])
        # Small restrained almond-shaped whites avoid the old solid black socket look.
        shape=[(-.5,0),(-.25,-.42),(.23,-.40),(.5,.06),(.22,.46),(-.23,.45)]
        face('EyeWhite',[(x+px*width,y+py*height) for px,py in shape],.0014*scale)
        ellipse('Iris',x,y,width*.15,height*.43,.0028*scale)
        ellipse('Pupil',x,y,width*(.037 if profile.get('cat') else .075),height*.34,.0038*scale)
        ellipse('Highlight',x-width*.035,y+height*.18,width*.025,height*.065,.0045*scale,count=6)
        if not profile.get('cat'):
            # Upper lid, plus a short brow fitted to the same face surface.
            stroke('Pupil',(x-width*.45,y+height*.15),(x+width*.40,y+height*.24),.0014*scale,.004*scale)
            stroke('Brow',(x-width*.42,y+height*1.25),(x,y+height*1.45),.0030*scale,.0018*scale)
            stroke('Brow',(x,y+height*1.45),(x+width*.40,y+height*1.22),.0030*scale,.0018*scale)
        if profile.get('glasses'):
            corners=[(x-width*.68,y-height*.91),(x+width*.68,y-height*.91),(x+width*.68,y+height*.98),(x-width*.68,y+height*.98)]
            for i in range(4):stroke('Frame',corners[i],corners[(i+1)%4],.0031*scale,.0055*scale)
    eye_plane=None
    if profile.get('glasses'):
        left,right=anchors
        stroke('Frame',(left[0]+width*.68,left[1]+height*.27),(right[0]-width*.68,right[1]+height*.27),.0028*scale,.0055*scale)
    def append(values,kind,component=5126):
        dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[component]
        array=np.asarray(values,dtype=dtype)
        while len(binary)%4:binary.append(0)
        offset=len(binary);binary.extend(array.tobytes());view=len(doc['bufferViews'])
        doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':array.nbytes})
        index=len(doc['accessors']);accessor={'bufferView':view,'componentType':component,'count':len(array),'type':kind}
        if kind=='VEC3':accessor.update(min=array.min(0).tolist(),max=array.max(0).tolist())
        doc['accessors'].append(accessor);return index
    # The old classifier left outer curls skin-coloured. Correct only their material assignment.
    if asset in ['vy','vy_sau','guest_2']:
        hair_index=next(i for i,m in enumerate(doc['materials']) if m['name']==asset+'_Hair')
        for mesh in doc['meshes']:
            parts=[]
            for primitive in mesh['primitives']:
                if doc['materials'][primitive['material']]['name']!=asset+'_Skin':
                    parts.append(primitive);continue
                points=read_accessor(doc,blob,primitive['attributes']['POSITION'])/scale
                indices=read_accessor(doc,blob,primitive['indices']).ravel().reshape(-1,3)
                center=points[indices].mean(1);x,y,z=center.T;ax=np.abs(x)
                paint=(y>1.56)&(ax>.112)&(z<.20)
                if asset in ['vy','guest_2']:
                    paint|=(y>1.24)&(y<1.61)&(ax>.075)&(ax<.20)&(z>.095)&(z<.20)
                for mask,mat in [(~paint,primitive['material']),(paint,hair_index)]:
                    if not mask.any():continue
                    part=copy.deepcopy(primitive)
                    part['indices']=append(indices[mask].ravel(),'SCALAR',5125)
                    part['material']=mat
                    parts.append(part)
            mesh['primitives']=parts
    original_surfaces=copy.deepcopy(doc['meshes'])
    primitives=[]
    joint=None
    if doc.get('skins'):
        joint=next(i for i,n in enumerate(doc['skins'][0]['joints']) if doc['nodes'][n].get('name')=='Head')
    for key,color in detail_palette.items():
        part=buffers[key]
        if not part['p']:continue
        material_id=len(doc['materials']);doc['materials'].append(material(asset+'_'+key,color,roughness=.9))
        attrs={'POSITION':append(part['p'],'VEC3'),'NORMAL':append(part['n'],'VEC3')}
        if joint is not None:
            joints=np.zeros((len(part['p']),4),dtype=np.uint16);joints[:,0]=joint
            weights=np.zeros((len(part['p']),4));weights[:,0]=1.
            attrs.update(JOINTS_0=append(joints,'VEC4',5123),WEIGHTS_0=append(weights,'VEC4'))
        primitives.append({'attributes':attrs,'indices':append(part['i'],'SCALAR',5125),'material':material_id})
    mesh_id=len(doc['meshes']);doc['meshes'].append({'name':'CharacterFaceDetails','primitives':primitives})
    node_id=len(doc['nodes']);node={'name':'CharacterFaceDetails','mesh':mesh_id}
    if joint is not None:node['skin']=0
    doc['nodes'].append(node);doc['scenes'][doc.get('scene',0)]['nodes'].append(node_id)
    doc.setdefault('extras',{})['character_face_refinement']=tag
    assert doc['nodes'][:len(native_nodes)]==native_nodes
    assert doc.get('animations',[])==native_animations
    assert doc['meshes'][:len(original_surfaces)]==original_surfaces
    assert bytes(binary[:tag['binary_length']])==blob[:tag['binary_length']]
    write_document(path,doc,binary)
    details=sum(len(v['i'])//3 for v in buffers.values())
    meta_path=folder/'provenance.json';backup(meta_path);meta=json.loads(meta_path.read_text())
    meta.update(output_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),face_detail_triangles=details)
    meta['face_refinement']={'reference':profile['reference'],'palette_srgb':profile['palette'],'eyes':anchors,'builder':'tools/art/refine_character_faces.py',
                             'base_binary_sha256':hashlib.sha256(blob[:tag['binary_length']]).hexdigest(),'base_binary_length':tag['binary_length'],
                             'changes':'Base Color correction and surface-projected eye/eyelid/brow details; original body, normals, weights, rig and clips unchanged'}
    meta_path.write_text(json.dumps(meta,indent=2)+'\n')
    metrics_path=folder/'metrics.json';backup(metrics_path);metrics=json.loads(metrics_path.read_text())
    base_count=metrics.get('body_triangles',metrics['triangles']-metrics.get('face_detail_triangles',0))
    metrics.update(body_triangles=base_count,face_detail_triangles=details,triangles=base_count+details,mesh_count=len(doc['meshes']),surfaces=sum(len(m['primitives']) for m in doc['meshes']))
    metrics_path.write_text(json.dumps(metrics,indent=2)+'\n')
    print(asset,details,'face triangles; body/rig/animation binary preserved')
    if not profile.get('cat'):
        from follow_manual_hair import IDS, follow
        if asset in IDS:follow(asset)
        from match_character_eyes_to_rin import match
        match(asset, use_saved_fit=True)

if __name__=='__main__':
    import sys
    for asset in sys.argv[1:] or PROFILES:refine(asset)
