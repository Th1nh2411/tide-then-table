extends Node3D
## Verify actual support-foot drift, deterministic gait, carry legs, and path clearance.
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1

func foot_drift(id: String, driven: bool, carry: bool, speed := 2.2) -> float:
	var actor := PersonRig3D.build(self,id)
	actor.set_carrying(carry)
	var visual := actor._pilot
	var bones := [visual.skeleton.find_bone("Foot.L"),visual.skeleton.find_bone("Foot.R")]
	var samples: Array[PackedVector3Array] = []
	var source_heights: Array[Vector2] = []
	for frame in 241:
		var delta := 1.0/120.0
		var displacement := Vector3(0,0,speed*delta)
		actor.position += displacement
		if driven: actor.drive_ground_motion(displacement,delta,false)
		else:
			if id == "rin" and speed > 2.25 and not carry: visual.set_motion("CharacterArmature|Run")
			else: actor.set_walking(1.0,float(frame)*delta)
			visual.animation.advance(delta)
		visual.skeleton.force_update_all_bone_transforms()
		var feet := PackedVector3Array()
		for bone: int in bones: feet.append(visual.skeleton.to_global(visual.skeleton.get_bone_global_pose(bone).origin))
		samples.append(feet)
		if driven:
			source_heights.append(Vector2(visual._foot_plant.legs[0].get("source_height",feet[0].y),visual._foot_plant.legs[1].get("source_height",feet[1].y)))
		else: source_heights.append(Vector2(feet[0].y,feet[1].y))
	var drift := 0.0
	var contacts := 0
	for foot in 2:
		var low := INF; var high := -INF
		for frame in range(30,samples.size()):
			low = minf(low,source_heights[frame][foot]); high = maxf(high,source_heights[frame][foot])
		for frame in range(31,samples.size()):
			var a := samples[frame-1][foot]; var b := samples[frame][foot]
			if maxf(source_heights[frame-1][foot],source_heights[frame][foot]) > low + minf((high-low)*.2,.04) + .00001: continue
			drift += Vector2(b.x-a.x,b.z-a.z).length()*120.0
			contacts += 1
	actor.queue_free()
	return drift / maxf(contacts,1)

func phase(fps: int) -> float:
	var actor := PersonRig3D.build(self,"rin")
	for frame in fps*2:
		var step := Vector3(0,0,2.0/float(fps))
		actor.position += step
		actor.drive_ground_motion(step,1.0/float(fps),false)
	var result := actor._pilot.animation.current_animation_position
	actor.queue_free()
	return result

func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	for id: String in ["rin","bao","vy","vy_sau","co_nam","ong_tam","staff","guest_1","guest_2","guest_3","guest_rich","guest_regular"]:
		for carry: bool in [false,true]:
			var before := foot_drift(id,false,carry)
			var after := foot_drift(id,true,carry)
			check(after < before*.65,"%s carry=%s support-foot drift %.3f -> %.3f m/s" % [id,carry,before,after])
	var old_run := foot_drift("rin",false,false,3.0)
	var new_run := foot_drift("rin",true,false,3.0)
	check(new_run < old_run*.65,"Rin Run support-foot drift %.3f -> %.3f m/s" % [old_run,new_run])
	check(absf(phase(30)-phase(120)) < .0001,"Same distance produces the same walk phase at 30/120 fps")
	var tables: Array = RestaurantLayout3D.TABLES
	var actor := PersonRig3D.build(self,"vy")
	actor.position = RestaurantLayout3D.TABLES[0]+Vector3(0,0,-1.7)
	var target := RestaurantLayout3D.TABLES[0]+Vector3(0,0,1.7)
	var clear := true
	var turns := true
	var max_speed := 0.0
	for frame in 500:
		var previous := actor.position
		var angle := actor.rotation.y
		StaffPathing3D.move(actor,tables,target,2.2,1.0/60.0)
		clear = clear and not FloorGrid3D.get_shared(tables).blocked_at(actor.position)
		turns = turns and absf(angle_difference(angle,actor.rotation.y)) < .75
		max_speed = maxf(max_speed,actor.position.distance_to(previous)*60)
	check(clear and turns and actor.position.distance_to(target)<.01 and max_speed<=2.201,"Staff accelerates, turns smoothly, stays clear of furniture and arrives without overshoot")
	check(actor._pilot.animation.current_animation=="Idle","Arrived staff returns to Idle")
	actor.set_carrying(true)
	actor.drive_ground_motion(Vector3(0,0,.03),1.0/60.0,false)
	check(actor._pilot.animation.current_animation=="GroundCarryWalk","Carrying staff uses real walking legs")
	actor.drive_ground_motion(Vector3.ZERO,1.0/60.0,false)
	check(actor._pilot.animation.current_animation=="Carry","Stopped carrying actor returns to Carry")
	actor.queue_free()
	await get_tree().process_frame
	var fast_render := PersonRig3D.build(self,"rin")
	fast_render.drive_ground_motion(Vector3(0,0,.03),1.0/60.0,false)
	var tick := Engine.get_physics_frames()
	var stays_moving := true
	for render in 12:
		await get_tree().process_frame
		if Engine.get_physics_frames() <= tick+1:
			stays_moving = stays_moving and fast_render._pilot.animation.current_animation != "Idle"
	check(stays_moving,"Render frames between physics ticks do not force a walking character back to Idle")
	fast_render.queue_free()
	GameState.reset()
	var room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.arrival_cutscenes.clear()
	add_child(room)
	await get_tree().process_frame
	room.planning_panel.hide()
	room.player.position = Vector3(0,0,RestaurantLayout3D.BACK_Z+.4)
	var right: Vector3 = room.demo_camera.global_basis.x
	var back: Vector3 = room.demo_camera.global_basis.z
	right.y = 0; back.y = 0
	var axis := Vector2(Vector3.FORWARD.dot(right.normalized()),Vector3.FORWARD.dot(back.normalized()))
	var x_action := "turn_right" if axis.x>=0 else "turn_left"
	var z_action := "throttle_back" if axis.y>=0 else "throttle_forward"
	Input.action_press(x_action,absf(axis.x))
	Input.action_press(z_action,absf(axis.y))
	for step in 90: await get_tree().physics_frame
	var at_wall: Vector3 = room.player.position
	for step in 10: await get_tree().physics_frame
	check(room.player.position.distance_to(at_wall)<.005 and room.body._pilot.animation.current_animation=="Idle","Holding input against a wall stops the feet instead of walking in place")
	Input.action_release(x_action);Input.action_release(z_action)
	room.player.position = Vector3(0,0,2)
	room.player.velocity = Vector3.ZERO
	Input.action_press("turn_right")
	for step in 20: await get_tree().physics_frame
	Input.action_press("dash")
	for step in 2: await get_tree().physics_frame
	var dash_started: bool = room.mover.dash_left>0 and room.player.velocity.length()>3.0
	Input.action_release("dash")
	for step in ceili(room.roll_seconds * 60.0) + 6: await get_tree().physics_frame
	check(dash_started and room.mover.dash_left<=0 and room.player.velocity.length()<=3.01,"Dash finishes without a long overspeed glide")
	room.player.position = Vector3(-2,0,2)
	Input.action_press("sprint")
	for step in 30: await get_tree().physics_frame
	var ran: bool = room.player.velocity.length()>room.walk_speed+.5 and room.mover.stamina<1.0 and room.mover._bar.visible
	check(ran,"Shift runs faster, drains stamina and shows the bar")
	for step in ceili(room.stamina_seconds*60.0): await get_tree().physics_frame
	check(room.mover.winded and room.player.velocity.length()<=room.walk_speed+.01,"Empty stamina drops Rin back to walking")
	Input.action_release("sprint")
	Input.action_release("turn_right")
	for step in ceili((room.stamina_rest_delay+room.stamina_refill_seconds)*60.0)+10: await get_tree().physics_frame
	check(room.mover.stamina>=1.0 and not room.mover._bar.visible,"Stamina refills and the bar hides")
	room.queue_free()
	await get_tree().process_frame
	print("GROUND MOTION CHECK ","PASS" if failures==0 else "FAIL")
	get_tree().quit(1 if failures else 0)
