"""Run with Blender --background --factory-startup --python <this file>.
Reopens each brief-7 GLB into a fresh background scene, packs textures, saves
editable sources. Never attaches to the user's interactive Blender session.
"""
from pathlib import Path
import json,sys,hashlib
selected=set(sys.argv[sys.argv.index("--")+1:]) if "--" in sys.argv else set()
import bpy
ROOT=Path(__file__).resolve().parents[2]
manifest_path=ROOT/'art_source/horror/brief7/sources.json'
manifest=json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
for path in sorted((ROOT/'assets/models/ready').glob('*/hunyuan_provenance.json')):
    record=json.loads(path.read_text())
    if 'brief7' not in record:
        continue
    name=path.parent.name
    if selected and name not in selected:
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path.parent/f'{name}_reduced.glb'))
    collection=bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    for obj in list(bpy.context.scene.objects):
        old=list(obj.users_collection)
        collection.objects.link(obj)
        for owner in old:
            owner.objects.unlink(obj)
    bpy.context.scene["runtime_glb_sha256"]=hashlib.sha256((path.parent/f"{name}_reduced.glb").read_bytes()).hexdigest()
    bpy.context.scene["recipe"]="tools/art/finish_horror_brief7.py"
    bpy.ops.file.pack_all()
    target=ROOT/record['brief7']['blend_source']
    target.parent.mkdir(parents=True,exist_ok=True)
    if target.exists():
        raise RuntimeError(f'Back up existing source before replacing {target}')
    bpy.ops.wm.save_as_mainfile(filepath=str(target),compress=True)
    manifest[name]={'runtime_glb_sha256':bpy.context.scene['runtime_glb_sha256'],'blend_sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
print('BRIEF7 SOURCES OK')
