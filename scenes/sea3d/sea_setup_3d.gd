class_name SeaSetup3D
extends RefCounted
## One-time wiring of the 3D sea: the first-person rod + basket (Fishing3D),
## the night's story nodes and the start camera.


static func build_tools(sea: SeaScene3D) -> void:
	sea.rod = Fishing3D.attach(sea)
	DarkNight3D.attach(sea)  # đêm âm: only when tonight has an omen
	NightErrand3D.attach(sea)  # calm nights: one thing to pick up out there
	RamSea3D.attach(sea)  # rằm: the tea's drowsiness, or the ghost-lights to the raft
	sea.camera.position = sea.boat.position + SeaScene3D.CAMERA_OFFSET
	sea.camera.look_at(sea.boat.position + Vector3(0, .65, -SeaScene3D.CAMERA_LOOK_AHEAD))
