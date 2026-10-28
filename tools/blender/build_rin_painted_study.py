"""A separate Rin variant: simplified skinned mesh + generated hand-painted albedos.
Run inside Blender. Original portrait and mesh study remain untouched.
"""
import bpy
import math
import json
import shutil
from pathlib import Path
from datetime import datetime
from mathutils import Vector

ROOT=Path('/Users/nguyenthinh/WorkSpace/tide-then-table')
OUT=ROOT/'build/characters/rin_painted'
ASSET=ROOT/'assets/models/characters/rin_painted'
SOURCE=ROOT/'build/characters/rin_portrait_study/rin_portrait_study.blend'
OUT.mkdir(parents=True,exist_ok=True)
STAMP=datetime.now().strftime('%Y%m%d_%H%M%S_%f')
for p in [ASSET/'rin_painted.glb',OUT/'rin_painted.blend',OUT/'portrait.png',OUT/'front.png',OUT/'back.png',OUT/'full_body.png']:
    if p.exists():
        dest=OUT/'backups'/STAMP/p.name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
with bpy.data.libraries.load(str(SOURCE),link=False) as (src,dst):
    dst.scenes=[src.scenes[0]]
scene=dst.scenes[0]
scene.name='Rin_Painted_Study'
bpy.context.window.scene=scene
rig=next(o for o in scene.objects if o.type=='ARMATURE')
rig.name='Rin_Painted_Study'
assets=rig.users_collection[0]
original_objects=[o for o in scene.objects if o.type=='MESH']
original_triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in original_objects)

# The face identity is painted, not made from tiny individual floating spheres.
remove_tokens=['Eye_White','Iris','Upper_Lid','Brow','Relaxed_Mouth','Lower_Lip','Nostril_Wing',
 'Tank_Fold','Hair_Cap','Hair_Ridge','Fringe','Parting','Side_Lock','Sideburn','Nape_Lock']
for obj in list(scene.objects):
    if obj.type=='MESH' and any(token in obj.name for token in remove_tokens):
        bpy.data.objects.remove(obj,do_unlink=True)


def color(hexcolor):
    def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    return tuple(linear(int(hexcolor[i:i+2],16)/255) for i in (0,2,4))+(1,)


def textured(name,file,base='cf9868'):
    mat=bpy.data.materials.new('Rin_Painted_'+name)
    mat.diffuse_color=color(base);mat.use_nodes=True
    shader=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    shader.inputs['Roughness'].default_value=.94
    shader.inputs['Specular IOR Level'].default_value=.03
    image=bpy.data.images.load(str(ASSET/'textures'/file),check_existing=False)
    image.scale(256,256)
    image.pack()
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest';tex.extension='EXTEND'
    if name=='Hair':
        darken=mat.node_tree.nodes.new('ShaderNodeMixRGB');darken.blend_type='MULTIPLY'
        darken.inputs[0].default_value=1;darken.inputs[2].default_value=(.46,.46,.46,1)
        mat.node_tree.links.new(tex.outputs['Color'],darken.inputs[1])
        mat.node_tree.links.new(darken.outputs[0],shader.inputs['Base Color'])
    else:
        mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    return mat
face=textured('Face','face_albedo_v2.png')
hair=textured('Hair','hair_albedo_v1.png','171e2a')
cloth=textured('Cotton','shirt_albedo_v1.png','e6dfcd')


def uvmap(obj,fn):
    uv=obj.data.uv_layers.active or obj.data.uv_layers.new(name='UVMap')
    bpy.context.view_layer.update()
    for poly in obj.data.polygons:
        for loop_index in poly.loop_indices:
            local=obj.data.vertices[obj.data.loops[loop_index].vertex_index].co
            point=obj.matrix_world@local
            uv.data[loop_index].uv=fn(point,poly)

head=next(o for o in scene.objects if o.name.startswith('Rin_Head'))
head.data.materials.clear();head.data.materials.append(face)
def face_v(z):
    v=(z-1.471)/.30
    # Compress the eye opening while keeping the eye centers and mouth fixed.
    distance=v-.56
    return v+distance*.45*math.exp(-(distance/.065)**4)

# Front projection uses the known eye/mouth centers of the generated albedo.
# Back half samples a feature-free corner so no duplicate eyes wrap behind head.
uvmap(head,lambda p,poly:(.5+p.x/.30,face_v(p.z))
    if poly.center.y<.003 else (.03,.95))
for obj in list(scene.objects):
    if obj.type!='MESH':continue
    if obj.name.startswith('Rin_Nose'):
        bpy.context.view_layer.update()
        inv=obj.matrix_world.inverted()
        for vertex in obj.data.vertices:
            point=obj.matrix_world@vertex.co
            point.z-=.013
            if point.y<-.10:point.y=-.10+(point.y+.10)*.40
            vertex.co=inv@point
        obj.data.materials.clear();obj.data.materials.append(face)
        uvmap(obj,lambda p,poly:(.5+p.x/.30,face_v(p.z)))
    elif obj.name.startswith('Rin_Hair_Cap'):
        obj.data.materials.clear();obj.data.materials.append(hair)
        uvmap(obj,lambda p,poly:((math.atan2(p.y-.018,p.x)/math.tau)%1,
            max(0,min(1,(p.z-1.60)/.23))))
    elif obj.name.startswith('Rin_Tank_Front') or obj.name.startswith('Rin_Tank_Back'):
        obj.data.materials.clear();obj.data.materials.append(cloth)
        uvmap(obj,lambda p,poly:(.5+p.x/.36,(p.z-.855)/.55))

# Six broad swept locks and a short split at the side preserve actual 3D silhouette.
# Strand detail is painted in the albedo, not modelled as ridges.

def lock(name,points,width):
    points=[Vector((x,y,1.65+(z-1.65)*.84)) for x,y,z in points]
    sides=8;verts=[];faces=[]
    for i,point in enumerate(points):
        t=i/(len(points)-1)
        tangent=(points[min(i+1,len(points)-1)]-points[max(i-1,0)]).normalized()
        normal=Vector((point.x,point.y-.018,max(.025,point.z-1.66))).normalized()
        lateral=tangent.cross(normal).normalized();normal=lateral.cross(tangent).normalized()
        taper=max(.035,math.sin((.18+t*.82)*math.pi)**.50)
        for k in range(sides):
            a=math.tau*k/sides
            verts.append(point+lateral*math.cos(a)*width*taper+normal*math.sin(a)*.006*taper)
    for r in range(len(points)-1):
        for k in range(sides):
            a=r*sides+k;b=r*sides+(k+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))])
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);assets.objects.link(obj);obj.parent=rig
    data.materials.append(hair)
    for poly in data.polygons:poly.use_smooth=True
    uv=data.uv_layers.new()
    for loop in data.loops:
        row,k=divmod(loop.vertex_index,sides)
        uv.data[loop.index].uv=(k/(sides-1),1-row/(len(points)-1))
    group=obj.vertex_groups.new(name='Head');group.add(list(range(len(verts))),1,'REPLACE')
    mod=obj.modifiers.new('Rin_Rig','ARMATURE');mod.object=rig

# One continuous cap carries most painted strands and the asymmetric haircut.
verts=[];faces=[];rows=15;cols=40
for r in range(rows):
    t=r/(rows-1)
    for k in range(cols):
        theta=math.tau*k/cols
        front=max(0,-math.sin(theta))
        angle_distance=math.atan2(math.sin(theta+.85),math.cos(theta+.85))
        part=math.exp(-(angle_distance/.27)**2)*.28
        end=1.88+.18*max(0,math.sin(theta))-.13*front+.055*math.sin(theta*9)-part
        polar=.012+t*end
        x=.12*math.sin(polar)*math.cos(theta)-.006*front*t
        y=.018+.112*math.sin(polar)*math.sin(theta)
        z=1.65+(1.687+.142*math.cos(polar)-1.65)*.84
        verts.append((x,y,z))
for r in range(rows-1):
    for k in range(cols):
        a=r*cols+k;b=r*cols+(k+1)%cols
        faces.append((a,b,b+cols,a+cols))
data=bpy.data.meshes.new('Rin_Painted_Hair_Volume');data.from_pydata(verts,[],faces);data.update()
cap=bpy.data.objects.new('Rin_Painted_Hair_Volume',data);assets.objects.link(cap);cap.parent=rig
data.materials.append(hair)
for poly in data.polygons:poly.use_smooth=True
uv=data.uv_layers.new()
for loop in data.loops:
    row,k=divmod(loop.vertex_index,cols)
    uv.data[loop.index].uv=(k/(cols-1),1-row/(rows-1))
group=cap.vertex_groups.new(name='Head');group.add(list(range(len(verts))),1,'REPLACE')
mod=cap.modifiers.new('Rin_Rig','ARMATURE');mod.object=rig
# Four quiet overlapping tips soften the front outline; surface detail is painted.
for i in range(4):
    t=i/3;x=.075-t*.15
    lock('Rin_Painted_Fringe_%02d'%i,[(.06-t*.055,-.027,1.812),
        (x+.01,-.075,1.78),(x-.008,-.099,1.72-t*.009),
        (x-.025,-.101,1.668-t*.009)],.027)

# Reduce body topology before joining, retaining the same weighted animation rig.
for obj in list(scene.objects):
    if obj.type!='MESH' or obj.name.startswith(('Rin_Head','Rin_Nose','Rin_Painted_','Rin_Glasses','Rin_Fishhook')):continue
    if len(obj.data.polygons)>100 and not obj.name.startswith('Rin_Tank'):
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new('Study_Reduction','DECIMATE');mod.ratio=.55
        # Put geometry reduction before skinning; never bake a pose into the mesh.
        while obj.modifiers.find(mod.name)>0:
            bpy.ops.object.modifier_move_up(modifier=mod.name)
        bpy.ops.object.modifier_apply(modifier=mod.name)

# One skinned object with material surfaces instead of dozens of draw nodes.
bpy.ops.object.select_all(action='DESELECT')
meshes=[o for o in scene.objects if o.type=='MESH']
for obj in meshes:obj.select_set(True)
bpy.context.view_layer.objects.active=head
bpy.ops.object.join()
model=bpy.context.object;model.name='Rin_Painted_Mesh'
rig.select_set(True)
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=None
for bone in rig.pose.bones:bone.rotation_euler=(0,0,0)
bpy.context.view_layer.update()

# Export a standalone GLB; it embeds all three textures for portable Godot import.
bpy.ops.export_scene.gltf(filepath=str(ASSET/'rin_painted.glb'),export_format='GLB',
 use_selection=True,use_active_scene=True,export_animations=True,
 export_animation_mode='NLA_TRACKS',export_skins=True)
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=None
for bone in rig.pose.bones:bone.rotation_euler=(0,0,0)
bpy.context.view_layer.update()

camera=scene.camera
scene.render.resolution_x=800;scene.render.resolution_y=1000
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.film_transparent=False

def render(name,location,target,scale):
    camera.location=location;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale=scale
    scene.render.filepath=str(OUT/name)
    bpy.ops.render.render(write_still=True)

render('portrait.png',(-5.3,-6,2.3),(0,0,1.35),1.04)
render('front.png',(0,-6,1.62),(0,0,1.36),1.04)
render('back.png',(3,6,2.4),(0,0,1.35),1.04)
render('full_body.png',(-3,-6,2.8),(0,0,.94),2.08)
scene.render.resolution_x=640;scene.render.resolution_y=360
render('game_scale.png',(-4.5,-12,9),(0,0,.8),14.0)
bpy.data.libraries.write(str(OUT/'rin_painted.blend'),{scene},fake_user=True)
triangles=sum(len(p.vertices)-2 for p in model.data.polygons)
metrics={'source_mesh_objects':len(original_objects),'painted_mesh_objects':1,
 'source_raw_triangles':original_triangles,'painted_raw_triangles':triangles,
 'textures':['face_albedo_v2.png','hair_albedo_v1.png','shirt_albedo_v1.png'],
 'reference':'assets/sprites/portraits/rin/base.png','status':'candidate_not_active'}
(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2))
print('RIN_PAINTED_OK',json.dumps(metrics))
