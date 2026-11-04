class_name ProximityTuning
extends Resource
## Numbers for "too close to a phenomenon" (ProximityZone3D) and the chase
## that may follow (Chase3D, ChaseRules). Distances are flat metres from
## Rin's feet. Rin's own speeds live on RestaurantScene3D (walk 1.8 m/s, run
## 3.2 m/s for 3.5 s of stamina): a walking Rin is caught, a running one gets away.

@export_group("Warning and notice")
## The warning starts here: heartbeat, sound ducking, dark vignette + noise.
@export var warn_distance: float = 4.0
## Closer than this the phenomenon notices Rin.
@export var notice_distance: float = 1.5
## Ambience level (0..1) at the closest point of the warning band.
@export_range(0.0, 1.0) var duck_level: float = 0.15

@export_group("Chase")
## How long a chase lasts if Rin is neither caught nor safe (rolled per loop + day).
@export var chase_seconds_min: float = 10.0
@export var chase_seconds_max: float = 20.0
## It stands and stares this long after noticing, then comes.
@export var start_wait: float = 0.5
## Speed while Rin is not looking at it (frozen while he is).
@export var unseen_speed: float = 1.9
## A dash once it has been unseen this long (Rin turned away), at most every dash_cooldown s.
@export var dash_after_unseen: float = 0.25
@export var dash_cooldown: float = 3.0
@export var dash_distance: float = 1.5
@export var dash_seconds: float = 0.3
## Within this it has him.
@export var catch_distance: float = 0.7
## Further than this it loses him (the fog loop carried him off).
@export var lose_distance: float = 22.0

@export_group("Safe places")
## A lamp counts as light within this flat distance under it.
@export var light_radius: float = 2.4
@export var light_min_energy: float = 0.8
@export var light_min_range: float = 3.5
## The roadside shrine in the lane.
@export var shrine_radius: float = 2.6

@export_group("Jump scare")
@export var scare_duck_seconds: float = 0.3
@export var scare_face_seconds: float = 0.35
