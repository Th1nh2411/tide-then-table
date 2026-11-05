"""Validate shipped geometry/provenance and the full six-direction visual audit."""
from pathlib import Path
import json,hashlib
import numpy as np
from glb_common import load_glb,read_accessor
from finish_horror_brief6 import BUDGETS
ROOT=Path(__file__).resolve().parents[2]
READY=ROOT/'assets/models/ready'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
catalog=json.loads((READY/'horror_models.json').read_text())
assert len(catalog)==50
result={'date':'2026-11-05','catalog_models':50,'total_triangles':0,'changed':{},'unchanged':[],'audit_directions':['front','back','left','right','top','bottom']}
for name in catalog:
    folder=READY/name;p=folder/f'{name}_reduced.glb';r=json.loads((folder/'hunyuan_provenance.json').read_text());d,b=load_glb(p)
    triangles=0
    for mesh in d['meshes']:
        for primitive in mesh['primitives']:
            triangles+=d['accessors'][primitive['indices']]['count']//3
            for key in ['POSITION','NORMAL']:
                values=read_accessor(d,b,primitive['attributes'][key]);assert np.isfinite(values).all(),(name,key)
            normals=read_accessor(d,b,primitive['attributes']['NORMAL']);assert np.allclose(np.linalg.norm(normals,axis=1),1,atol=.01),name
            if 'brief7' in r:
                uv=read_accessor(d,b,primitive['attributes']['TEXCOORD_0']);assert np.isfinite(uv).all(),name
    assert triangles<=BUDGETS[name],(name,triangles)
    assert sha(p)==r['reduced_sha256'],name
    assert sha(folder/f'{name}_raw.glb')==r['raw_sha256'],name
    result['total_triangles']+=triangles
    if 'brief7' in r:
        old=json.loads((ROOT/'.art_backups/brief7_20261105/assets/models/ready'/name/'hunyuan_provenance.json').read_text())
        assert old['raw_sha256']==r['raw_sha256']
        assert (ROOT/r['brief7']['blend_source']).exists(),name
        assert triangles==r['brief7']['triangles']
        result['changed'][name]={'triangles':triangles,'budget':BUDGETS[name],'raw_unchanged':True,'uv_normals_finite':True,'reduced_sha256':r['reduced_sha256']}
    else:
        result['unchanged'].append(name)
    for angle in range(6):assert (ROOT/f'build/brief7/sides_after/{name}_{angle}.png').exists(),(name,angle)
assert len(result['changed'])==32
sources=json.loads((ROOT/'art_source/horror/brief7/sources.json').read_text())
assert len(sources)==32
for name,r in sources.items():
    assert sha(READY/name/f'{name}_reduced.glb')==r['runtime_glb_sha256'],name
    assert sha(ROOT/f'art_source/horror/brief7/{name}.blend')==r['blend_sha256'],name
result['source_manifest_verified']=True
for log,marker in [('tests_final.log','ALL OK'),('bot_final.log','BOT OK'),('coverage_final.log','HORROR COVERAGE TEST PASS')]:
    assert marker in (ROOT/'build/brief7'/log).read_text(),log
result['tests']={'suite':'ALL OK','bot':'BOT OK','coverage':'PASS'}
for item in json.loads((ROOT/'.art_backups/brief7_20261105/manifest.json').read_text()):assert sha(ROOT/item['backup'])==item['sha256']
result['backup_manifest_verified']=True
out=ROOT/'docs/art_reviews/brief7_validation_20261105.json';out.write_text(json.dumps(result,indent=2)+'\n')
print(f'BRIEF7 VALIDATION OK: 50 models, {len(result["changed"])} changed, {result["total_triangles"]} triangles, 300 side captures')
