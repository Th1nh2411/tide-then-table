class_name Whirlpool
extends Area2D
## Glowing whirlpool in the fog. The boat touching it triggers the ending.

signal boat_entered(boat: Boat)

@export var radius: float = 26.0
@export var glow_color: Color = Color(0.4, 1.0, 0.9)
@export var spin_speed: float = 2.0

var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body is Boat:
			boat_entered.emit(body))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	# Soft glow: stacked translucent circles.
	for i in 4:
		var glow := glow_color
		glow.a = 0.08 + 0.04 * pulse
		draw_circle(Vector2.ZERO, radius * (1.6 - i * 0.25), glow)
	# Spiral arms turning inward.
	for arm in 3:
		var points := PackedVector2Array()
		for step in 24:
			var t := step / 23.0
			var angle := _time * spin_speed + arm * TAU / 3.0 + t * TAU * 1.2
			points.append(Vector2.RIGHT.rotated(angle) * radius * (1.0 - t * 0.85))
		draw_polyline(points, glow_color, 2.0)
	draw_circle(Vector2.ZERO, 4 + 2 * pulse, Color.WHITE)
