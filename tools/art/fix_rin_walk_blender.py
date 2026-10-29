"""Repair the user's live Rin mesh weights and author a planted-foot Walk action.
Run inside Blender after saving a recoverable copy. Does not export or save the scene.
"""
import bpy
import math
from mathutils import Vector, Matrix, Quaternion

rig = bpy.data.objects['RinPilotSkin']
mesh = bpy.data.objects['RinPilotMesh']
# The old x<.30 leg mask left the wide outside edges of the sandals on Hips.
repaired = 0
for vertex in mesh.data.vertices:
    if vertex.co.z < .10:
        tag = 'L' if vertex.co.x >= 0 else 'R'
        for group in mesh.vertex_groups:
            group.remove([vertex.index])
        mesh.vertex_groups['Foot.' + tag].add([vertex.index], 1.0, 'REPLACE')
        repaired += 1

ad = rig.animation_data
old_action, old_slot = ad.action, ad.action_slot
track = next(t for t in ad.nla_tracks if t.name == 'Walk')
old_strip = track.strips[0]
old_walk = old_strip.action
# Keep the artist's previous action recoverable in the current .blend.
old_walk.use_fake_user = True
muted = [(t, t.mute) for t in ad.nla_tracks]
for t in ad.nla_tracks:
    t.mute = True
walk = bpy.data.actions.new('Rin_Walk_Repaired')
ad.action = walk
bones = rig.data.bones
pose = rig.pose.bones
scene = bpy.context.scene
old_frame = scene.frame_current
rest = {b.name: b.matrix_local.copy() for b in bones}
heads = {b.name: b.head_local.copy() for b in bones}

for frame in range(25):
    scene.frame_set(frame)
    for p in pose:
        p.rotation_mode = 'QUATERNION'
        p.matrix_basis = Matrix.Identity(4)
    t = frame / 24.0
    phase = t * math.tau
    bob = -.024 + .005 * math.cos(2 * phase)
    hips = pose['Hips']
    hips.location = rest['Hips'].to_3x3().inverted() @ Vector((.008*math.sin(phase), 0, bob))
    hips.keyframe_insert('location', frame=frame, group='Hips')
    bpy.context.view_layer.update()
    for sign, tag in [(-1, 'R'), (1, 'L')]:
        angle = phase + (0 if tag == 'L' else math.pi)
        swing = max(0.0, -math.sin(angle))
        h0 = heads['Thigh.'+tag]
        k0 = heads['Shin.'+tag]
        a0 = heads['Foot.'+tag]
        hip = pose['Thigh.'+tag].head.copy()
        target = Vector((a0.x, a0.y - .125*math.cos(angle), a0.z + .060*swing*swing))
        axis = (target-hip).normalized()
        l1, l2 = (k0-h0).length, (a0-k0).length
        distance = min((target-hip).length, l1+l2-.0001)
        along = (l1*l1-l2*l2+distance*distance)/(2*distance)
        bend = math.sqrt(max(0, l1*l1-along*along))
        pole = Vector((0,-1,0));pole = (pole-axis*pole.dot(axis)).normalized()
        knee = hip+axis*along+pole*bend
        upper = (k0-h0).rotation_difference(knee-hip)
        lower = (a0-k0).rotation_difference(target-knee)
        for name, head, rotation in [('Thigh.'+tag, hip, upper), ('Shin.'+tag, knee, lower), ('Foot.'+tag,target,Quaternion())]:
            p=pose[name]
            p.matrix = Matrix.Translation(head) @ rotation.to_matrix().to_4x4() @ rest[name].to_3x3().to_4x4()
            bpy.context.view_layer.update()
            p.keyframe_insert('rotation_quaternion', frame=frame, group=name)
        # Opposing arm swing, with relaxed elbows; local axes follow imported rest transforms.
        for name, global_rotation in [('UpperArm.'+tag, Quaternion((1,0,0), sign*.20*math.sin(phase)) @ Quaternion((0,1,0), sign*.10)), ('Forearm.'+tag, Quaternion((1,0,0), .10))]:
            p=pose[name]
            basis=rest[name].to_quaternion()
            p.rotation_quaternion=basis.inverted() @ global_rotation @ basis
            p.keyframe_insert('rotation_quaternion',frame=frame,group=name)
    pose['Chest'].rotation_quaternion=Quaternion((0,1,0),.025*math.sin(phase))
    pose['Chest'].keyframe_insert('rotation_quaternion',frame=frame,group='Chest')

# Linear dense samples avoid overshooting the planted soles between keys.
for layer in walk.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for curve in bag.fcurves:
                for key in curve.keyframe_points:
                    key.interpolation='LINEAR'
new_slot=ad.action_slot
track.strips.remove(old_strip)
new_strip=track.strips.new('Walk',0,walk)
new_strip.action_slot=new_slot
new_strip.action_frame_start=0
new_strip.action_frame_end=24
for tr,mute in muted:
    tr.mute=mute
ad.action=old_action
ad.action_slot=old_slot
scene.frame_set(old_frame)
print('Reweighted',repaired,'foot/sandal vertices; authored 24 fps planted-foot Walk cycle')
