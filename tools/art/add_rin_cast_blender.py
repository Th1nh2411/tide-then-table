"""Add a 1.5-second Cast clip to the opened Rin source, retaining mesh and existing clips.
Run with Blender --background <rin.blend> --python <this script> after backing up source.
"""
import bpy, math
from mathutils import Vector, Matrix
rig=bpy.data.objects['RinPilotSkin']
ad=rig.animation_data
old_action,old_slot=ad.action,ad.action_slot
mutes=[(track,track.mute) for track in ad.nla_tracks]
for track in ad.nla_tracks:track.mute=True
cast=bpy.data.actions.new('Rin_Cast')
ad.action=cast
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
heads={b.name:b.head_local.copy() for b in rig.data.bones}
# Coordinates are Blender Z-up; front is -Y after glTF import.
keys=[(0.0,(.24,1.12,.30)),(.30,(.24,1.62,-.16)),(.50,(.21,1.32,.58)),(.80,(.24,1.15,.46)),(1.,(.24,1.15,.46))]
scene=bpy.context.scene
old_frame=scene.frame_current
for frame in range(37):
    scene.frame_set(frame)
    for p in rig.pose.bones:
        p.rotation_mode='QUATERNION'
        p.matrix_basis=Matrix.Identity(4)
    t=frame/36
    for i in range(len(keys)-1):
        if keys[i][0]<=t<=keys[i+1][0]:
            a,b=keys[i],keys[i+1];u=(t-a[0])/(b[0]-a[0]);u=u*u*(3-2*u)
            lead=Vector(a[1]).lerp(Vector(b[1]),u);break
    for sign,tag in [(-1,'R'),(1,'L')]:
        h0=heads['UpperArm.'+tag];e0=heads['Forearm.'+tag];w0=heads['Hand.'+tag]
        # Supporting hand stays close to the reel rather than floating at the side.
        target=Vector((lead.x,-lead.z,lead.y)) if tag=='L' else Vector((-.10,-.27,1.12))
        axis=(target-h0).normalized();l1=(e0-h0).length;l2=(w0-e0).length
        distance=min((target-h0).length,l1+l2-.001)
        target=h0+axis*distance
        along=(l1*l1-l2*l2+distance*distance)/(2*distance)
        height=math.sqrt(max(0,l1*l1-along*along))
        pole=Vector((sign*.7,.4,-1));pole=(pole-axis*pole.dot(axis)).normalized()
        elbow=h0+axis*along+pole*height
        upper=(e0-h0).rotation_difference(elbow-h0)
        lower=(w0-e0).rotation_difference(target-elbow)
        # Orient the grip along the cast, easing into the follow-through.
        rod_keys=[Vector((0,-.60,.80)),Vector((0,.65,.76)),Vector((0,-.96,.28)),Vector((0,-.85,.53)),Vector((0,-.85,.53))]
        desired=rod_keys[i].lerp(rod_keys[i+1],u).normalized()
        rest_rod=Vector((0,-math.cos(1.2),math.sin(1.2)))
        hand=rest_rod.rotation_difference(desired)
        for name,head,rotation in [('UpperArm.'+tag,h0,upper),('Forearm.'+tag,elbow,lower),('Hand.'+tag,target,hand)]:
            p=rig.pose.bones[name]
            p.matrix=Matrix.Translation(head) @ rotation.to_matrix().to_4x4() @ rest[name].to_3x3().to_4x4()
            bpy.context.view_layer.update()
            p.keyframe_insert('rotation_quaternion',frame=frame,group=name)
for layer in cast.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for curve in bag.fcurves:
                for key in curve.keyframe_points:key.interpolation='LINEAR'
slot=ad.action_slot
track=next((t for t in ad.nla_tracks if t.name=='Cast'),None)
if track is not None:ad.nla_tracks.remove(track)
track=ad.nla_tracks.new();track.name='Cast'
strip=track.strips.new('Cast',0,cast);strip.action_slot=slot
for track,mute in mutes:track.mute=mute
ad.action=old_action;ad.action_slot=old_slot
scene.frame_set(old_frame)
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
# Save back to the user source only when explicitly invoked by the caller.
import os
source=bpy.data.filepath
if os.environ.get('RIN_SAVE_CAST')=='1':bpy.ops.wm.save_as_mainfile(filepath=source)
for obj in bpy.context.view_layer.objects:obj.select_set(False)
rig.select_set(True);bpy.data.objects['RinPilotMesh'].select_set(True)
bpy.context.view_layer.objects.active=rig
out=os.environ['RIN_CAST_EXPORT']
bpy.ops.export_scene.gltf(filepath=out,export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_rest_position_armature=True)
print('Exported Rin with Cast; existing mesh, materials and Walk preserved')
