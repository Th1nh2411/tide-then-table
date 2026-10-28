"""Portrait-led Rin mesh study. Execute in Blender, isolated from active gameplay.
Outputs editable source, GLB and four review renders. No external assets/services.
"""
import bpy
import math
import random
import shutil
from pathlib import Path
from datetime import datetime
from mathutils import Vector

ROOT = Path('/Users/nguyenthinh/WorkSpace/tide-then-table')
OUT = ROOT / 'build/characters/rin_portrait_study'
EXPORT = ROOT / 'assets/models/characters/rin_portrait_study.glb'
OUT.mkdir(parents=True, exist_ok=True)
EXPORT.parent.mkdir(parents=True, exist_ok=True)
STAMP = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
for path in [OUT/'rin_portrait_study.blend', EXPORT, OUT/'portrait.png', OUT/'front.png', OUT/'back.png', OUT/'full_body.png']:
    if path.exists():
        backup = OUT/'backups'/STAMP/path.name
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup)

scene = bpy.data.scenes.new('Rin_Portrait_Study')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
assets = bpy.data.collections.new('Rin_Portrait_Study_Asset')
scene.collection.children.link(assets)
parts = []
random.seed(21)

def linear(v):
    return v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4

def material(name, hexcolor, rough=.8, metal=0):
    rgb = tuple(linear(int(hexcolor[i:i+2],16)/255) for i in (0,2,4))
    mat = bpy.data.materials.new('Rin_'+name)
    mat.diffuse_color = (*rgb,1)
    mat.use_nodes=True
    bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value=(*rgb,1)
    bsdf.inputs['Roughness'].default_value=rough
    bsdf.inputs['Metallic'].default_value=metal
    bsdf.inputs['Specular IOR Level'].default_value=.04 if 'Hair' in name else .3
    return mat

skin=material('Skin','cf9868')
skin_shadow=material('Skin_Warm_Shadow','a76846')
skin_light=material('Skin_Highlight','dba777')
ear_inner=material('Ear_Inner','b77b53')
hair=material('Hair','171e2a',.72)
hair_mid=material('Hair_Ridge','222e3f',.75)
hair_light=material('Hair_Subtle_Blue','2c4058',.8)
frame=material('Glasses','151921',.48)
eye_white=material('Eyes_Warm_White','e2cfac')
eye_dark=material('Eyes','292523')
shirt=material('Tank_Top','e6dfcd')
shirt_shadow=material('Tank_Seams','cec5b4')
shorts=material('Shorts','29313b')
sandal=material('Sandals','343438')
silver=material('Silver','bcc3c4',.28,.65)
lip=material('Mouth','935c40')


def move_collection(obj):
    for col in list(obj.users_collection): col.objects.unlink(obj)
    assets.objects.link(obj)


def finish(obj,name,mat,bone=None,smooth=True):
    obj.name=name
    move_collection(obj)
    if mat: obj.data.materials.append(mat)
    if obj.type=='MESH':
        for poly in obj.data.polygons: poly.use_smooth=smooth
    parts.append((obj,bone))
    return obj


def mesh(name,verts,faces,mat,bone=None,smooth=True):
    data=bpy.data.meshes.new(name+'_Mesh')
    data.from_pydata(verts,[],faces)
    data.update()
    obj=bpy.data.objects.new(name,data)
    assets.objects.link(obj)
    if mat: data.materials.append(mat)
    for poly in data.polygons: poly.use_smooth=smooth
    parts.append((obj,bone))
    return obj


def ellipsoid(name,pos,scale,mat,bone=None,seg=20,rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=pos)
    obj=bpy.context.object
    obj.scale=scale
    return finish(obj,name,mat,bone)


def tube(name,points,radius,mat,bone=None,sides=8):
    points=[Vector(p) for p in points]
    verts=[]
    for i,point in enumerate(points):
        tangent=(points[min(i+1,len(points)-1)]-points[max(i-1,0)]).normalized()
        side=tangent.cross(Vector((0,0,1)))
        if side.length < .01: side=tangent.cross(Vector((0,1,0)))
        side.normalize()
        up=tangent.cross(side).normalized()
        for k in range(sides):
            angle=math.tau*k/sides
            verts.append(point+radius*(math.cos(angle)*side+math.sin(angle)*up))
    faces=[]
    for i in range(len(points)-1):
        for k in range(sides):
            a=i*sides+k; b=i*sides+(k+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))), tuple(range((len(points)-1)*sides,len(points)*sides))]
    return mesh(name,verts,faces,mat,bone)


def rings_mesh(name,levels,mat,bone=None,sides=28):
    # z, horizontal radius, depth radius, front-back center
    verts=[]
    for z,rx,ry,cy in levels:
        for k in range(sides):
            t=math.tau*k/sides
            verts.append((rx*math.cos(t),cy+ry*math.sin(t),z))
    faces=[]
    for row in range(len(levels)-1):
        for k in range(sides):
            a=row*sides+k; b=row*sides+(k+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple(range((len(levels)-1)*sides,len(levels)*sides))]
    return mesh(name,verts,faces,mat,bone)

# Human proportions, narrow chin and relaxed shoulders, not the block demo's head.
rings_mesh('Rin_Head',[(1.445,.035,.043,-.012),(1.462,.058,.062,-.005),
 (1.492,.079,.078,.002),(1.535,.096,.090,.003),(1.585,.104,.094,.002),
 (1.635,.107,.092,.005),(1.685,.108,.094,.009),(1.735,.103,.094,.013),
 (1.775,.084,.079,.016),(1.795,.045,.048,.018)],skin,'Head')
ellipsoid('Rin_Neck',(0,.018,1.405),(.059,.061,.12),skin,'Neck')
rings_mesh('Rin_Torso',[(.84,.112,.069,0),(.94,.113,.072,0),(1.06,.125,.077,0),
 (1.18,.148,.086,0),(1.28,.171,.083,0),(1.34,.185,.065,.012),
 (1.38,.142,.050,.018)],skin,'Chest')
# Collarbone accents follow the top of the chest.
for side in [-1,1]:
    tube('Rin_Clavicle',[(side*.033,-.058,1.342),(side*.083,-.061,1.333),(side*.13,-.052,1.34)],.0022,skin_shadow,'Chest',6)

# Fitted singlet with a U-neck and shaped shoulder straps.
def body_section(z):
    levels=[(.84,.112,.069),(.94,.113,.072),(1.06,.125,.077),(1.18,.148,.086),(1.28,.171,.083),(1.34,.185,.065),(1.40,.14,.05)]
    for (z0,w0,d0),(z1,w1,d1) in zip(levels,levels[1:]):
        if z <= z1:
            t=max(0,min(1,(z-z0)/(z1-z0)))
            return w0+(w1-w0)*t+.005,d0+(d1-d0)*t+.006
    return .15,.06
shirt_tops={}

for back in [False,True]:
    verts=[]; faces=[]
    count=32; rows=14
    for row in range(rows):
        t=row/(rows-1)
        for k in range(count+1):
            u=-1+2*k/count; x=u*.178
            a=abs(u)
            if not back:
                top=1.279+.082*math.exp(-((a-.82)/.24)**2)
            else:
                top=1.337+.024*math.exp(-((a-.82)/.25)**2)
            z=.855+t*(top-.855)
            width,depth=body_section(z)
            x=u*width
            # Depth tracks the underlying skin surface.
            y=math.sqrt(max(0,1-u*u))*depth
            y=(y if back else -y)+max(0,min(.018,(z-1.28)*.2))
            # Restrained draped fold shape without a noisy texture.
            y += (.0018*math.sin(t*28+a*5)+.001*math.sin(t*47-u*6))*(1-a)*(-1 if not back else 1)
            verts.append((x,y,z))
    for row in range(rows-1):
        for k in range(count):
            a=row*(count+1)+k
            faces.append((a+count+1,a+count+2,a+1,a) if back else (a,a+1,a+count+2,a+count+1))
    mesh('Rin_Tank_Back' if back else 'Rin_Tank_Front',verts,faces,shirt,'Chest')
    edge=verts[(rows-1)*(count+1):]
    tube('Rin_Tank_Neck_Binding',edge,.0018,shirt_shadow,'Chest',6)
    shirt_tops[back]=edge
# Continuous arch straps cross each shoulder and meet the front/back panels.
for side in [-1,1]:
    verts=[]
    for k in range(13):
        t=k/12
        y=-.050+.10*t
        z=1.332+.052*math.sin(math.pi*t)
        for across in [-1,1]:
            verts.append((side*.148+across*.018,y,z))
    faces=[(k*2,k*2+1,k*2+3,k*2+2) for k in range(12)]
    strap=mesh('Rin_Tank_Continuous_Strap',verts,faces,shirt,'Chest')
    solid=strap.modifiers.new('Strap_Thickness','SOLIDIFY'); solid.thickness=.0015
# Side seams and a clean bottom hem.
for side in [-1,1]:
    pass
tube('Rin_Tank_Hem',[(.118*math.cos(t),.077*math.sin(t),.858) for t in [math.tau*k/48 for k in range(49)]],.0015,shirt_shadow,'Chest')

# Subtle short creases rather than raised decorative seams.
for i in range(4):
    z=.98+i*.055
    pts=[]
    for k in range(9):
        x=-.075+k*.01875
        width,depth=body_section(z)
        y=-depth*math.sqrt(1-(x/width)**2)-.001
        pts.append((x,y,z+.006*math.sin(k/8*math.pi)))
    tube('Rin_Tank_Fold',pts,.0008,shirt_shadow,'Chest',6)
# Arms/legs and understated fingers: separated at natural joints for the rig.
for side,tag in [(-1,'L'),(1,'R')]:
    levels=[(1.37,.17,.02,.025),(1.335,.191,.012,.054),(1.27,.215,.012,.053),
      (1.17,.24,.009,.045),(1.065,.25,.005,.032),(1.02,.254,.001,.033),
      (.96,.264,-.004,.035),(.88,.274,-.01,.025),(.84,.275,-.01,.022)]
    verts=[]; faces=[]; sides=20
    for z,cx,cy,radius in levels:
        for k in range(sides):
            a=math.tau*k/sides
            verts.append((side*cx+radius*math.cos(a),cy+radius*.95*math.sin(a),z))
    for row in range(len(levels)-1):
        for k in range(sides):
            a=row*sides+k;b=row*sides+(k+1)%sides
            faces.append((a,a+sides,b+sides,b))
    faces.extend([tuple(range(sides)),tuple(reversed(range((len(levels)-1)*sides,len(levels)*sides)))])
    arm=mesh('Rin_Arm_'+tag,verts,faces,skin,'UpperArm.'+tag)
    arm['arm_side']=tag
    ellipsoid('Rin_Palm_'+tag,(side*.275,-.010,.818),(.035,.023,.054),skin,'Hand.'+tag)
    for f in range(4):
        x=side*(.254+f*.013)
        tube('Rin_Finger_'+tag+str(f),[(x,-.009,.802),(x,-.014,.764-(.009 if f in [1,2] else 0))],.0065,skin,'Hand.'+tag,6)
    tube('Rin_Thumb_'+tag,[(side*.25,-.014,.83),(side*.235,-.026,.797)],.009,skin,'Hand.'+tag)
    ellipsoid('Rin_Thigh_'+tag,(side*.078,.004,.66),(.071,.070,.19),skin,'Thigh.'+tag)
    ellipsoid('Rin_Calf_'+tag,(side*.079,.014,.275),(.046,.047,.195),skin,'Shin.'+tag)
    ellipsoid('Rin_Knee_'+tag,(side*.079,-.005,.445),(.043,.045,.047),skin,'Shin.'+tag)
    ellipsoid('Rin_Foot_'+tag,(side*.08,-.043,.070),(.045,.099,.040),skin,'Foot.'+tag)
    ellipsoid('Rin_Sandal_Sole_'+tag,(side*.08,-.044,.031),(.050,.111,.014),sandal,'Foot.'+tag)
    tube('Rin_Sandal_Strap_'+tag,[(side*.045,-.073,.08),(side*.08,-.04,.11),(side*.118,-.075,.08)],.009,sandal,'Foot.'+tag)
    # Separate tailored shorts legs, with hem and pocket seams.
    obj=rings_mesh('Rin_Shorts_'+tag,[(.49,.067,.073,0),(.51,.070,.076,0),(.68,.083,.077,0),(.84,.078,.078,0)],shorts,'Thigh.'+tag,20)
    obj.location.x=side*.078
    tube('Rin_Shorts_Hem_'+tag,[(side*.078+.069*math.cos(t),.076*math.sin(t),.505) for t in [math.tau*k/24 for k in range(25)]],.003,frame,'Thigh.'+tag,6)

# Eyelids and warm small eyes sit on the curved face, behind clear open frames.
for side,tag in [(-1,'L'),(1,'R')]:
    x=side*.046
    ellipsoid('Rin_Eye_White_'+tag,(x,-.082,1.635),(.022,.008,.006),eye_white,'Head',20,8)
    ellipsoid('Rin_Iris_'+tag,(x+side*.001,-.093,1.634),(.005,.0025,.0045),eye_dark,'Head',12,8)
    tube('Rin_Upper_Lid_'+tag,[(x-.025,-.087,1.642),(x,-.094,1.643),(x+.025,-.087,1.641)],.0024,skin_shadow,'Head',6)
    tube('Rin_Brow_'+tag,[(x-.025,-.088,1.666),(x,-.096,1.670),(x+.025,-.086,1.668)],.0035,hair,'Head',6)
    # Soft rectangular lenses, not circular goggles.
    outline=[(-.032,-.014),(-.034,.012),(-.028,.016),(.028,.016),(.034,.011),(.031,-.014),(.022,-.018),(-.023,-.018),(-.032,-.014)]
    points=[(x+dx,-.105+abs(x+dx)*.10,1.637+dz) for dx,dz in outline]
    tube('Rin_Glasses_Frame_'+tag,points,.0038,frame,'Head',8)
    tube('Rin_Glasses_Temple_'+tag,[(side*.079,-.098,1.65),(side*.111,-.054,1.657),(side*.116,.018,1.65)],.0027,frame,'Head',6)
tube('Rin_Glasses_Bridge',[(-.012,-.106,1.648),(0,-.112,1.652),(.012,-.106,1.648)],.0032,frame,'Head')
# Nose with bridge, tip and subtle nostril wings (custom mesh).
mesh('Rin_Nose',[(-.012,-.087,1.665),(.012,-.087,1.665),(-.015,-.099,1.60),
 (.015,-.099,1.60),(0,-.134,1.605),(0,-.104,1.675)],[(0,1,5),(0,5,4,2),(5,1,3,4),(2,4,3),(0,2,3,1)],skin,'Head')
for side in [-1,1]:
    ellipsoid('Rin_Nostril_Wing',(side*.014,-.100,1.598),(.006,.006,.004),skin,'Head',12,8)
tube('Rin_Relaxed_Mouth',[(-.026,-.083,1.547),(-.010,-.092,1.545),(.009,-.093,1.546),(.027,-.082,1.547)],.0021,lip,'Head',6)
tube('Rin_Lower_Lip',[(-.015,-.088,1.540),(0,-.094,1.537),(.017,-.086,1.541)],.0015,skin_light,'Head',6)

# Actual ear helix, concha and earlobe with a small silver earring.
for side,tag in [(-1,'L'),(1,'R')]:
    ellipsoid('Rin_Ear_Base_'+tag,(side*.108,.005,1.622),(.018,.028,.044),skin,'Head',16,10)
    ellipsoid('Rin_Ear_Concha_'+tag,(side*.122,-.001,1.624),(.004,.018,.029),ear_inner,'Head',12,8)
    pts=[(side*(.123+.003*math.sin(t)),.004+.022*math.cos(t),1.625+.036*math.sin(t)) for t in [math.tau*k/24 for k in range(25)]]
    tube('Rin_Ear_Helix_'+tag,pts,.004,skin_light,'Head',6)
    tube('Rin_Ear_Antihelix_'+tag,[(side*.127,-.005,1.61),(side*.128,.008,1.629),(side*.126,-.002,1.644)],.003,skin,'Head',6)
ellipsoid('Rin_Silver_Stud',(-.13,-.003,1.588),(.005,.006,.006),silver,'Head',12,8)

# Hair cap with a swept part and long directional locks, following the portrait.
verts=[]; faces=[]; rows=14; cols=40
for r in range(rows):
    p=.02+r/(rows-1)*1.57
    for k in range(cols):
        theta=math.tau*k/cols
        front=max(0,-math.sin(theta))
        local_p=p*(1-.22*front)
        x=.119*math.sin(local_p)*math.cos(theta)
        y=.018+.112*math.sin(local_p)*math.sin(theta)
        z=1.687+.142*math.cos(local_p)
        verts.append((x,y,z))
for r in range(rows-1):
    for k in range(cols):
        a=r*cols+k; b=r*cols+(k+1)%cols
        faces.append((a,b,b+cols,a+cols))
mesh('Rin_Hair_Cap',verts,faces,hair,'Head')


def lock(name,points,width,depth,mat):
    # A tapered ribbon volume; directional strands rather than spherical tufts.
    pts=[Vector(p) for p in points]
    verts=[]; sides=8
    for i,point in enumerate(pts):
        t=i/(len(pts)-1)
        taper=max(.025,math.sin((.12+t*.88)*math.pi)**.65)
        tangent=(pts[min(i+1,len(pts)-1)]-pts[max(i-1,0)]).normalized()
        normal=Vector((point.x,(point.y-.015)*1.1,max(.04,point.z-1.66))).normalized()
        lateral=tangent.cross(normal).normalized()
        if lateral.length < .1: lateral=Vector((1,0,0))
        normal=lateral.cross(tangent).normalized()
        for k in range(sides):
            a=math.tau*k/sides
            verts.append(point+lateral*math.cos(a)*width*taper+normal*math.sin(a)*depth*taper)
    faces=[]
    for i in range(len(pts)-1):
        for k in range(sides):
            a=i*sides+k; b=i*sides+(k+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple(range((len(pts)-1)*sides,len(pts)*sides))]
    return mesh(name,verts,faces,mat,'Head')

# Main swept fringe falls diagonally toward the left side of the forehead.
for i in range(7):
    t=i/6
    x=.075-t*.18
    points=[(.065-t*.065,-.030,1.809+math.sin(t*math.pi)*.009),
      (x+.018,-.074,1.798),(x-.008,-.111,1.745-t*.022),
      (x-.022,-.111,1.702-t*.017), (x-.039,-.099,1.674-t*.016)]
    lock('Rin_Fringe_%02d'%i,points,.027+random.random()*.004,.0035,hair)
# Short split on the other side exposes a narrow forehead triangle.
for i in range(4):
    lock('Rin_Parting_%02d'%i,[(.062,-.028,1.816),(.10+i*.005,-.065,1.787),(.118,-.07,1.735),(.113+i*.003,-.063,1.688-i*.009)],.020,.0035,hair)
# Side and back locks supply depth around the ear and nape.
for side in [-1,1]:
    for i in range(6):
        y=-.045+i*.027
        lock('Rin_Side_Lock',[(side*.063,y,1.802),(side*.109,y,1.749),(side*.121,y+.012,1.697),(side*.103,y+.012,1.647-random.random()*.025)],.022,.0035,hair)
    lock('Rin_Sideburn',[(side*.108,-.033,1.71),(side*.116,-.034,1.665),(side*.108,-.021,1.627)],.008,.004,hair)
for i in range(7):
    x=-.085+i*.028
    lock('Rin_Nape_Lock',[(x,.073,1.77),(x,.122,1.714),(x*.9,.118,1.651),(x*.8,.093,1.602)],.023,.0035,hair)
# A few subtle blue ridges, confined to crown rather than striped bright hair.
for i in range(4):
    lock('Rin_Hair_Ridge',[(.032-i*.027,-.02,1.824),(-.005-i*.023,-.066,1.80),(-.035-i*.021,-.093,1.758)],.0015,.0005,hair_mid)

# Relax the hair lock edges so the swept volume is not a row of hard fins.
for obj,bone in parts:
    if any(key in obj.name for key in ['Fringe','Side_Lock','Nape_Lock','Parting']):
        sub=obj.modifiers.new('Hair_Soft_Locks','SUBSURF'); sub.levels=1; sub.render_levels=1
# Black cord and silver fish-hook pendant from portrait.
cord=[(-.055,.008,1.45),(-.080,-.055,1.365),(-.050,-.084,1.32),(0,-.096,1.273),
 (.050,-.084,1.32),(.080,-.055,1.365),(.055,.008,1.45)]
tube('Rin_Necklace_Cord',cord,.0023,frame,'Chest',6)
tube('Rin_Fishhook_Pendant',[(0,-.101,1.279),(.002,-.105,1.26),(.007,-.106,1.242),(.001,-.108,1.234),(-.009,-.106,1.237),(-.011,-.104,1.249)],.0025,silver,'Chest',8)

# Compress the portrait's face vertically, preserving the chin/ear relationship.
for obj,bone in parts:
    if bone=='Head':
        world=obj.matrix_world.copy()
        # Update matrix_world after object-location/scale assignments in the same call.
        bpy.context.view_layer.update()
        world=obj.matrix_world.copy()
        inv=world.inverted()
        for vertex in obj.data.vertices:
            point=world@vertex.co
            point.z=1.65+(point.z-1.65)*.84
            vertex.co=inv@point
# Articulated skeleton and modest reusable motion clips, rigid low-poly binding.
armature=bpy.data.armatures.new('Rin_Study_Skeleton')
rig=bpy.data.objects.new('Rin_Portrait_Study',armature)
assets.objects.link(rig)
bpy.context.view_layer.objects.active=rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bones={
 'Root':((0,0,0),(0,0,.15),None),
 'Hips':((0,0,.83),(0,0,.99),'Root'),
 'Chest':((0,0,.99),(0,0,1.34),'Hips'),
 'Neck':((0,0,1.34),(0,0,1.48),'Chest'),
 'Head':((0,0,1.48),(0,0,1.78),'Neck'),
}
for side,tag in [(-1,'L'),(1,'R')]:
    bones.update({
     'UpperArm.'+tag:((side*.19,0,1.32),(side*.25,0,1.05),'Chest'),
     'Forearm.'+tag:((side*.25,0,1.05),(side*.273,-.01,.84),'UpperArm.'+tag),
     'Hand.'+tag:((side*.273,-.01,.84),(side*.273,-.01,.77),'Forearm.'+tag),
     'Thigh.'+tag:((side*.078,0,.83),(side*.078,0,.45),'Hips'),
     'Shin.'+tag:((side*.078,0,.45),(side*.078,0,.10),'Thigh.'+tag),
     'Foot.'+tag:((side*.078,0,.10),(side*.078,-.1,.05),'Shin.'+tag),
    })
for name,(a,b,parent) in bones.items():
    bone=armature.edit_bones.new(name); bone.head=a; bone.tail=b
    if parent: bone.parent=armature.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for obj,bone in parts:
    if bone:
        group=obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        if obj.get('arm_side'):
            tag=obj['arm_side']
            fore=obj.vertex_groups.new(name='Forearm.'+tag)
            for vertex in obj.data.vertices:
                w=max(0,min(1,(1.10-vertex.co.z)/.10))
                group.add([vertex.index],1-w,'REPLACE')
                fore.add([vertex.index],w,'REPLACE')
        deform=obj.modifiers.new('Rin_Rig','ARMATURE'); deform.object=rig
        obj.parent=rig
rig.animation_data_create()
for clip,end in [('Idle',48),('Walk',24),('Carry',48)]:
    rig.animation_data.action=bpy.data.actions.new(clip)
    for frame_no in range(1,end+1,4):
        phase=(frame_no-1)/end*math.tau
        for bone in rig.pose.bones: bone.rotation_mode='XYZ'; bone.rotation_euler=(0,0,0)
        rig.pose.bones['Head'].rotation_euler[1]=math.sin(phase)*.015
        rig.pose.bones['Chest'].rotation_euler[0]=math.sin(phase)*.008
        for side,tag in [(-1,'L'),(1,'R')]:
            if clip=='Walk':
                rig.pose.bones['Thigh.'+tag].rotation_euler[0]=math.sin(phase)*.30*side
                rig.pose.bones['Shin.'+tag].rotation_euler[0]=max(0,-math.sin(phase)*side)*.25
                rig.pose.bones['UpperArm.'+tag].rotation_euler[0]=-math.sin(phase)*.24*side
            elif clip=='Carry':
                rig.pose.bones['UpperArm.'+tag].rotation_euler[0]=-.55
                rig.pose.bones['Forearm.'+tag].rotation_euler[0]=-.7
            else:
                rig.pose.bones['UpperArm.'+tag].rotation_euler[0]=math.sin(phase)*.012*side
        for bone in rig.pose.bones:
            bone.keyframe_insert(data_path='rotation_euler',frame=frame_no,group=bone.name)
    action=rig.animation_data.action
    track=rig.animation_data.nla_tracks.new(); track.name=clip
    track.strips.new(clip,1,action)
    track.mute=True
rig.animation_data.action=None
for bone in rig.pose.bones: bone.rotation_euler=(0,0,0)
scene.frame_start=1; scene.frame_end=48
scene.frame_set(1)

# Neutral portrait light, warm skin and dark blue hair judged against actual PNG.
world=bpy.data.worlds.new('Rin_Studio_World'); scene.world=world
world.use_nodes=True
background=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
background.inputs['Color'].default_value=(.09,.12,.15,1)
background.inputs['Strength'].default_value=.45

def area(name,location,energy,size,target):
    data=bpy.data.lights.new(name,'AREA'); data.energy=energy; data.shape='DISK'; data.size=size
    obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj)
    obj.location=location; obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
area('Rin_Key',(-3,-4,5),380,4,(0,0,1.2))
area('Rin_Fill',(3,-1,3),160,3,(0,0,1.4))
area('Rin_Rim',(-1,3,4),450,3,(0,0,1.5))
camdata=bpy.data.cameras.new('Rin_Review_Camera'); camera=bpy.data.objects.new('Rin_Review_Camera',camdata)
scene.collection.objects.link(camera); scene.camera=camera
camdata.type='ORTHO'; camdata.lens=70
scene.render.engine='BLENDER_EEVEE_NEXT'
scene.eevee.taa_render_samples=64
scene.render.resolution_x=800; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='Standard'
scene.render.film_transparent=False

def render(name,location,target,scale):
    camera.location=location; camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    camdata.ortho_scale=scale
    scene.render.filepath=str(OUT/name)
    bpy.ops.render.render(write_still=True)

# Export only meshes/rig, excluding studio cameras, lights and prior scenes.
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
for obj,bone in parts: obj.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(EXPORT),export_format='GLB',use_selection=True,
 use_active_scene=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True)
for track in rig.animation_data.nla_tracks: track.mute=True
rig.animation_data.action=None
for bone in rig.pose.bones: bone.rotation_euler=(0,0,0)
bpy.context.view_layer.update()
render('portrait.png',(-5.3,-6,2.3),(0,0,1.35),1.04)
render('front.png',(0,-6,1.62),(0,0,1.36),1.04)
render('back.png',(3,6,2.4),(0,0,1.35),1.04)
render('full_body.png',(-3,-6,2.8),(0,0,.94),2.08)
bpy.data.libraries.write(str(OUT/'rin_portrait_study.blend'),{scene},fake_user=True)
print('RIN_STUDY_OK',len(parts),'mesh parts',str(EXPORT))
