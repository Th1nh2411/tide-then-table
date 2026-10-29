"""Finish actual inferred seated cat; rigid idle/walk sway is handled by PersonRig."""
from pathlib import Path
import json, shutil
import numpy as np
from glb_common import ROOT,load_mesh,normalize,write_mesh,sha256,backup
source=ROOT/'assets/models/batch/props/cat/cat_reduced.glb'
out=ROOT/'assets/models/ready/cat';out.mkdir(parents=True,exist_ok=True)
points,triangles=load_mesh(source);points=normalize(points,height=.58)
c=points[triangles].mean(1)
labels=np.zeros(len(c),int)
# Cream muzzle, chest and paws; orange outer body and ears.
labels[((c[:,1]<.09)&(c[:,2]>-.08))|((c[:,1]>.17)&(c[:,1]<.39)&(c[:,2]>.075)&(abs(c[:,0])<.12))]=1
labels[(c[:,1]>.40)&(c[:,1]<.45)&(c[:,2]>.13)&(abs(c[:,0])>.045)&(abs(c[:,0])<.10)]=2
metrics=write_mesh(out/'cat.glb',points,triangles,{'Orange':'cf934d','Cream':'e9d4ac','Eyes':'323132'},labels)
for name,payload in [('metrics.json',metrics),('provenance.json',dict(source_mesh=str(source.relative_to(ROOT)),source_sha256=sha256(source),source_method='Hunyuan3D-2mini-turbo local inference',processing='Uniform 0.58m height; flat orange/cream palette; original inferred geometry. Rigid seated visual, no skeletal locomotion.',blender_used=False,output_sha256=metrics['output_sha256']))]:
 backup(out/name);(out/name).write_text(json.dumps(payload,indent=2)+'\n')
notice=source.parent/'LICENSE-HUNYUAN.txt'
if notice.exists():shutil.copy2(notice,out/notice.name)
print(metrics)

# Reapply the reviewed orange palette and surface-fitted eyes after a rebuild.
from refine_character_faces import refine
refine("cat")
