"""Follow Bảo/Vy's manually painted hair boundaries without changing geometry.
Only reassign nearby triangles to Hair; preserve individual silhouettes and colors.
Never modifies the two references, Rin, or the cat.
"""
import copy, hashlib, json
import numpy as np
from glb_common import ROOT,load_glb,read_accessor,write_document,backup
IDS=('vy_sau','co_nam','ong_tam','guest_1','guest_2','guest_3','guest_rich','guest_regular','staff')

def faces(asset):
    folder=ROOT/'assets/models/ready'/asset
    doc,blob=load_glb(folder/(asset+'.glb'))
    height=json.loads((folder/'metrics.json').read_text())['height_m']
    centers=[];labels=[]
    for mesh in doc['meshes']:
        if 'FaceDetails' in mesh.get('name',''):continue
        for p in mesh['primitives']:
            v=read_accessor(doc,blob,p['attributes']['POSITION'])/(height/1.84)
            t=read_accessor(doc,blob,p['indices']).ravel().reshape(-1,3)
            centers.extend(v[t].mean(1));labels.extend([doc['materials'][p['material']]['name'].split('.')[0].endswith('_Hair')]*len(t))
    return np.array(centers),np.array(labels)


def follow(asset):
    assert asset in IDS
    reference='vy' if asset=='guest_2' else 'bao'
    # The ponytail uses Vy's head boundary only; retain its own tied-back silhouette.
    if asset=='vy_sau':reference='vy'
    ref,label=faces(reference);ref[:,0]=abs(ref[:,0])
    folder=ROOT/'assets/models/ready'/asset;path=folder/(asset+'.glb')
    doc,blob=load_glb(path)
    assert not doc.get('extras',{}).get('character_rin_eye_style'), 'Run hair before the eye finishing pass'
    height=json.loads((folder/'metrics.json').read_text())['height_m']
    hair=next(i for i,m in enumerate(doc['materials']) if m['name'].split('.')[0]==asset+'_Hair')
    binary=bytearray(blob[:doc['buffers'][0]['byteLength']]);changed=0
    def append(indices):
        a=np.asarray(indices,dtype='<u4').ravel()
        while len(binary)%4:binary.append(0)
        view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':a.nbytes});binary.extend(a.tobytes())
        i=len(doc['accessors']);doc['accessors'].append({'bufferView':view,'componentType':5125,'count':len(a),'type':'SCALAR'});return i
    for mesh in doc['meshes']:
        if 'FaceDetails' in mesh.get('name',''):continue
        parts=[]
        for p in mesh['primitives']:
            name=doc['materials'][p['material']]['name'].split('.')[0]
            if not name.endswith(('_Skin','_Shirt','_Apron')):
                parts.append(p);continue
            points=read_accessor(doc,blob,p['attributes']['POSITION'])/(height/1.84)
            idx=read_accessor(doc,blob,p['indices']).ravel().reshape(-1,3);c=points[idx].mean(1);c[:,0]=abs(c[:,0])
            x,y,z=c.T
            candidate=(y>1.55)&(x<.24)
            # Long loose curls: include the outer locks below the ears, keep face/neck clear.
            if asset=='guest_2':candidate|=(y>1.02)&(y<1.62)&(x>.115)&(x<.245)&(z>-.16)
            if asset=='vy_sau':candidate|=(y>1.32)&(y<1.62)&(x>.13)&(z<.12)
            # Keep cheeks, central face, ears and brows out of the reference transfer.
            candidate &= ~((y<1.74)&(z>.055)&(x<.105))
            delta=(c[:,None,:]-ref[None,:,:])*np.array([1.25,.8,1.3])
            dist=(delta*delta).sum(2);nearest=np.argpartition(dist,4,axis=1)[:,:5]
            confidence=label[nearest].mean(1);near=np.sqrt(np.take_along_axis(dist,nearest,axis=1).min(1))
            paint=candidate&(confidence>=.8)&(near<.055)
            changed+=int(paint.sum())
            for mask,mat in [(~paint,p['material']),(paint,hair)]:
                if not mask.any():continue
                if mask.all():part=copy.deepcopy(p)
                else:part=copy.deepcopy(p);part['indices']=append(idx[mask])
                part['material']=mat;parts.append(part)
        mesh['primitives']=parts
    if changed:
        write_document(path,doc,binary)
        meta_path=folder/'provenance.json';backup(meta_path);meta=json.loads(meta_path.read_text())
        meta['output_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
        meta['manual_hair_follow']={'reference':reference,'reference_sha256':hashlib.sha256((ROOT/'assets/models/ready'/reference/(reference+'.glb')).read_bytes()).hexdigest(),'triangles_reassigned':changed,'builder':'tools/art/follow_manual_hair.py','changes':'Hair material boundary only; preserve geometry, colors, rest rig and clips'}
        meta_path.write_text(json.dumps(meta,indent=2)+'\n')
        metric_path=folder/'metrics.json';backup(metric_path);metrics=json.loads(metric_path.read_text());metrics['surfaces']=sum(len(m['primitives']) for m in doc['meshes']);metric_path.write_text(json.dumps(metrics,indent=2)+'\n')
    print(asset,reference,changed,'hair triangles corrected')

if __name__=='__main__':
    import sys
    for asset in sys.argv[1:] or IDS:follow(asset)
