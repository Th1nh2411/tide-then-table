class_name ReelTuning
extends Resource
## Numbers of the first-person rod (Fishing3D + ReelLogic): cast reach, bite
## timing, line tension while reeling.

@export_group("Cast")
## Horizontal metres from the boat the bobber can land.
@export var cast_min := 6.0
@export var cast_max := 12.0
@export var cast_seconds := 0.7
## Height of the bobber's arc (m).
@export var cast_arc := 2.2
## No bites this close to the dock (pier water).
@export var dock_quiet_radius := 12.0

@export_group("Bite")
@export var bite_min := 3.0
@export var bite_max := 8.0
## Bites come this much sooner with the bobber at a bubble shoal.
@export var shoal_bite_scale := 0.45
@export var shoal_radius := 4.8
## Seconds the "!" stays up: click inside it to hook.
@export var bite_window := 1.2

@export_group("Reel")
## Metres of line won per second while reeling (less while the fish runs).
@export var reel_speed := 2.0
@export var reel_speed_in_run := 0.3
## Tension per second while reeling: base + more for a strong fish.
@export var rise := 0.42
@export var rise_by_strength := 0.25
## Tension lost per second with the button released.
@export var fall := 0.75
## Fish runs: gaps and lengths (s); extra tension per second at full
## strength while reeling (a fraction of it while released); metres of line
## the fish takes per second at full strength while released.
@export var run_gap_min := 1.0
@export var run_gap_max := 2.6
@export var run_min := 0.5
@export var run_max := 1.1
@export var run_tension := 0.9
@export var run_tension_released := 0.25
@export var run_line := 0.6
## Line out never grows past the cast plus this.
@export var extra_line := 3.0
## Seconds at full tension before the line snaps.
@export var snap_seconds := 0.6
