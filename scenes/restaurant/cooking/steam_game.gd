class_name SteamGame
extends CookingGameBase
## Steam: hold `cast` to steam, the time bar fills. Release when it is in the
## green zone. Holding until the bar is full overcooks the dish.

@export var bar_size: Vector2 = Vector2(240, 16)
## Seconds of holding to fill the bar completely.
@export var fill_seconds: float = 2.5
@export var ok_zone: Vector2 = Vector2(0.6, 0.88)
@export var perfect_zone: Vector2 = Vector2(0.7, 0.78)

var _progress: float = 0.0
var _holding: bool = false


func setup(p_dish: DishData) -> void:
	super(p_dish)
	custom_minimum_size = bar_size + Vector2(20, 40)


func get_hint() -> String:
	return "Giữ Space / chuột trái để hấp, thả ra khi thanh vào vùng xanh"


func get_status_text() -> String:
	return "Đang hấp..." if _holding else "Giữ để bắt đầu hấp"


func _update(delta: float) -> void:
	if not _accepts_input():
		return
	var pressed := Input.is_action_pressed("cast")
	if pressed:
		_holding = true
		_progress += delta / fill_seconds
		if _progress >= 1.0:
			_finish(Result.BURNT)
	elif _holding:
		_finish(CookingGameBase.judge(_progress, ok_zone, perfect_zone))


func _draw() -> void:
	var origin := _centered_origin(bar_size)
	_draw_zone_bar(origin, bar_size, ok_zone, perfect_zone)
	var fill := Rect2(origin, Vector2(clampf(_progress, 0.0, 1.0) * bar_size.x, bar_size.y))
	draw_rect(fill, Color(1, 1, 1, 0.45))
	var x := origin.x + clampf(_progress, 0.0, 1.0) * bar_size.x
	draw_rect(Rect2(x - 1, origin.y - 5, 2, bar_size.y + 10), Color.WHITE)
