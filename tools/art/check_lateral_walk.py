"""Check that narrowed Walk changes only world X against its original snapshot."""
from pathlib import Path
import json, math
import numpy as np
from glb_common import ROOT, load_glb, read_accessor, _matrix
from narrow_character_walk import IDS


def sample(document,binary,time):
    nodes=[dict(n) for n in document['nodes']]
    animation=next(a for a in document['animations'] if a['name']=='Walk')
    for channel in animation['channels']:
        sampler=animation['samplers'][channel['sampler']]
        ts=read_accessor(document,binary,sampler['input']).ravel()
        values=read_accessor(document,binary,sampler['output'])
        i=max(0,min(len(ts)-2,int(np.searchsorted(ts,time)-1)))
        u=float(np.clip((time-ts[i])/max(ts[i+1]-ts[i],1e-12),0,1))
        a,b=values[i].astype(float),values[i+1].astype(float)
        if channel['target']['path']=='rotation':
            dot=float(np.dot(a,b))
            if dot<0:b=-b;dot=-dot
            if dot<.9995:
                theta=math.acos(np.clip(dot,-1,1));v=(math.sin((1-u)*theta)*a+math.sin(u*theta)*b)/math.sin(theta)
            else:v=(1-u)*a+u*b
            v/=np.linalg.norm(v)
        else:v=(1-u)*a+u*b
        nodes[channel['target']['node']][channel['target']['path']]=v.tolist()
    parents={c:i for i,n in enumerate(nodes) for c in n.get('children',[])}
    memo={}
    def world(i):
        if i not in memo:memo[i]=(world(parents[i]) if i in parents else np.eye(4))@_matrix(nodes[i])
        return memo[i]
    return {n.get('name'):world(i) for i,n in enumerate(nodes)}


def main():
    for asset in IDS:
        folder=ROOT/'assets/models/ready'/asset
        meta=json.loads((folder/'provenance.json').read_text())
        source,original_binary=load_glb(ROOT/meta['walk_refinement']['source_snapshot'])
        final,final_binary=load_glb(folder/(asset+'.glb'))
        assert final['materials']==source['materials'],asset+': palette changed'
        assert final['nodes']==source['nodes'] and final['skins']==source['skins']
        old=next(a for a in source['animations'] if a['name']=='Walk')
        new=next(a for a in final['animations'] if a['name']=='Walk')
        for channel in old['channels']:
            assert channel in new['channels']
            for kind in ['input','output']:
                a=old['samplers'][channel['sampler']][kind];b=new['samplers'][channel['sampler']][kind]
                assert np.array_equal(read_accessor(source,original_binary,a),read_accessor(final,final_binary,b)),asset+': original Walk track changed'
        end=max(float(read_accessor(source,original_binary,s['input'])[-1,0]) for s in old['samplers'])
        scale=json.loads((folder/'metrics.json').read_text())['height_m']/1.84
        max_error,max_width=0.,0.
        for time in np.linspace(0,end,65):
            original=sample(source,original_binary,float(time));current=sample(final,final_binary,float(time))
            for bone in ['Root','Hips','Thigh.L','Shin.L','Foot.L','Thigh.R','Shin.R','Foot.R','Head']:
                max_error=max(max_error,float(np.max(np.abs(original[bone][1:3,:]-current[bone][1:3,:]))))
            max_width=max(max_width,abs(float(current['Foot.L'][0,3]-current['Foot.R'][0,3]))/scale)
        assert max_error<1e-6,(asset,'Y/Z motion changed',max_error)
        assert max_width<.241,(asset,'lateral stance still wide',max_width)
        print(f'PASS {asset}: original rotations/cadence retained, max Y/Z error {max_error:.9f}m; canonical ankle width {max_width:.6f}m')
    print('ALL OK: only lateral motion changed in 11 characters')


if __name__=='__main__':main()
