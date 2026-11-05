"""Stage the committed brief-6 GLBs for the six-direction before audit.
No active asset rollback and no editor imports: baseline_model uses GLTFDocument.
Then run review_horror_models.gd with -- --no-autosave --all-sides --baseline.
"""
from pathlib import Path
import subprocess,json
ROOT=Path(__file__).resolve().parents[2]
BASE='7b9d0f6'
OUT=ROOT/'build/brief7'
def committed(path):
    return subprocess.check_output(['git','show',f'{BASE}:{path}'],cwd=ROOT)
catalog=json.loads(committed('assets/models/ready/horror_models.json'))
for name in catalog:
    path=f'assets/models/ready/{name}/{name}_reduced.glb'
    target=OUT/'baseline_assets'/name/(name+'_reduced.glb')
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(committed(path))
for filename in ['horror_models.gd','horror_models.json']:
    (OUT/'baseline_assets'/filename).write_bytes(committed('assets/models/ready/'+filename))
script=committed('scenes/world3d/concept_model_3d.gd').decode()
script=script.replace('class_name ConceptModel3D\n','').replace('res://assets/models/ready/','res://build/brief7/baseline_assets/')
script=script.replace('var scene := load("res://build/brief7/baseline_assets/%s/%s_reduced.glb" % [id, id]) as PackedScene',
    'var document := GLTFDocument.new()\n\tvar state := GLTFState.new()\n\tvar error := document.append_from_file("res://build/brief7/baseline_assets/%s/%s_reduced.glb" % [id, id], state)')
script=script.replace('if scene == null:', 'if error != OK:').replace('var model := scene.instantiate() as Node3D','var model := document.generate_scene(state) as Node3D')
(OUT/'baseline_model.gd').write_text(script)
print('BASELINE STAGED: 50 committed models at '+BASE)
