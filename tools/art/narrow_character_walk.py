"""Narrow only the lateral (X) tracks of batch Walk.
Retains every original rotation, foot roll, vertical lift, forward stride and cadence.
New constant local-X translation tracks on knees/ankles change only world X because
these native leg/ancestor rotations are around X. Mesh/rest rig are not scaled.
"""
from pathlib import Path
import copy, json, hashlib
import numpy as np
from glb_common import ROOT, load_glb, read_accessor, write_document, backup
IDS=('bao','vy','vy_sau','co_nam','ong_tam','guest_1','guest_2','guest_3','guest_rich','guest_regular','staff')


def patch(asset, use_current_source=False):
    assert asset in IDS
    folder=ROOT/'assets/models/ready'/asset
    path=folder/(asset+'.glb')
    provenance_path=folder/'provenance.json'
    provenance=json.loads(provenance_path.read_text())
    if use_current_source:
        source=backup(path)
    else:
        previous=provenance.get('walk_refinement',{})
        source=ROOT/previous.get('source_snapshot',f'build/character_walk_narrow/source_before/{asset}_{asset}.glb')
        if not source.is_file():source=backup(path)
    doc,raw=load_glb(source)
    tag=doc.get('extras',{}).pop('character_face_refinement',None)
    if tag:
        for key,count in tag['counts'].items():doc[key]=doc[key][:count]
        if 'base_meshes' in tag:doc['meshes']=copy.deepcopy(tag['base_meshes'])
        for scene,count in zip(doc['scenes'],tag['scene_roots']):scene['nodes']=scene['nodes'][:count]
        length=tag['binary_length']
    else:length=doc['buffers'][0]['byteLength']
    binary=bytearray(raw[:length])
    metrics=json.loads((folder/'metrics.json').read_text());scale=metrics['height_m']/1.84
    walk=next(a for a in doc['animations'] if a['name']=='Walk')
    # Native rotations are all sagittal. Keeping their arrays unchanged is sufficient
    # to preserve the complete Y/Z motion when translation changes are X-only.
    ancestors={'Root','Hips','Thigh.L','Thigh.R','Shin.L','Shin.R','Foot.L','Foot.R'}
    for channel in walk['channels']:
        name=doc['nodes'][channel['target']['node']].get('name')
        if name in ancestors and channel['target']['path']=='rotation':
            sampler=walk['samplers'][channel['sampler']]
            values=read_accessor(doc,raw,sampler['output'])
            assert np.max(np.abs(values[:,1:3]))<1e-6, f'{asset}: non-sagittal source rotation on {name}'
    def append(values,kind):
        array=np.asarray(values,dtype='<f4')
        while len(binary)%4:binary.append(0)
        offset=len(binary);binary.extend(array.tobytes());view=len(doc['bufferViews'])
        doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':array.nbytes})
        index=len(doc['accessors']);a={'bufferView':view,'componentType':5126,'count':len(array),'type':kind}
        if kind=='SCALAR':a.update(min=[float(array.min())],max=[float(array.max())])
        doc['accessors'].append(a);return index
    duration=max(float(read_accessor(doc,raw,s['input'])[-1,0]) for s in walk['samplers'])
    time_index=append([0.,duration],'SCALAR')
    by_name={n.get('name'):i for i,n in enumerate(doc['nodes'])}
    parents={c:i for i,n in enumerate(doc['nodes']) for c in n.get('children',[])}
    rest={}
    def rest_x(i):
        if i not in rest:rest[i]=doc['nodes'][i].get('translation',[0,0,0])[0]+(rest_x(parents[i]) if i in parents else 0.)
        return rest[i]
    for sign,side in [(-1,'R'),(1,'L')]:
        for name,target,parent_target in [('Shin.'+side,.13,rest_x(by_name['Thigh.'+side])/sign/scale),('Foot.'+side,.12,.13)]:
            node=by_name[name]
            assert not any(c['target']=={'node':node,'path':'translation'} for c in walk['channels']), 'Already narrowed source; use the original snapshot'
            translation=list(doc['nodes'][node]['translation'])
            translation[0]=sign*(target-parent_target)*scale
            output=append([translation,translation],'VEC3')
            sampler=len(walk['samplers']);walk['samplers'].append({'input':time_index,'output':output,'interpolation':'LINEAR'})
            walk['channels'].append({'sampler':sampler,'target':{'node':node,'path':'translation'}})
    # Explicit rest translations on other clips prevent the Walk's X offsets from
    # persisting after AnimationPlayer transitions to Idle/Carry.
    for clip in doc['animations']:
        if clip['name']=='Walk':continue
        end=max(float(read_accessor(doc,raw,s['input'])[-1,0]) for s in clip['samplers'])
        reset_time=append([0.,end],'SCALAR')
        for side in ['R','L']:
            for bone in ['Shin.','Foot.']:
                node=by_name[bone+side]
                value=doc['nodes'][node]['translation']
                output=append([value,value],'VEC3')
                sampler=len(clip['samplers']);clip['samplers'].append({'input':reset_time,'output':output,'interpolation':'LINEAR'})
                clip['channels'].append({'sampler':sampler,'target':{'node':node,'path':'translation'}})
    write_document(path,doc,binary)
    # Reapply the reviewed face payload after adding the native Walk tracks. The base
    # layout marker now includes those tracks, so later palette edits stay safe.
    from refine_character_faces import refine
    refine(asset)
    backup(provenance_path)
    provenance=json.loads(provenance_path.read_text())
    provenance['walk_refinement']={'date':'2026-10-29','builder':'tools/art/narrow_character_walk.py','mode':'lateral_only',
        'source_snapshot':str(source.relative_to(ROOT)), 'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'half_stance_m_at_1_84m':.12,'changes':'X-only knee/ankle translation tracks; original rotations, Y/Z stride, lift, foot roll, duration and other clips retained'}
    provenance_path.write_text(json.dumps(provenance,indent=2)+'\n')
    print(asset,'lateral tracks narrowed; original forward/vertical gait restored')


if __name__=='__main__':
    import sys
    for asset in sys.argv[1:] or IDS:patch(asset)
