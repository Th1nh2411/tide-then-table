class_name TutorialHints
extends Node
## Day-1 tips shown in the HUD, advancing with what the player does:
## start -> first catch -> late afternoon. Does nothing on later days.

@export var hud: SeaHud
@export var fishing: FishingController
@export var nets: NetController
## In-game hour from which the "go back to the dock" tip shows.
@export var return_hint_hour: int = 16

enum Step { DRIVE, AFTER_CATCH, GO_HOME, DONE }

var _step: Step = Step.DONE


func _ready() -> void:
	if GameState.day != 1:
		return
	_step = Step.DRIVE
	hud.show_tip("Lái bằng WASD. Tìm đám bọt trắng, dừng thuyền rồi bấm E để câu.")
	fishing.fish_caught.connect(_on_catch)
	nets.fish_caught.connect(_on_catch)
	DayClock.time_changed.connect(_on_time_changed)


func _on_catch(_fish: FishData, _quality: float, _count: int) -> void:
	if _step == Step.DRIVE:
		_step = Step.AFTER_CATCH
		hud.show_tip("Tab: xem khoang. Q: thả lưới ốc ở vùng nước nông, lát quay lại phao bấm E để kéo.")


func _on_time_changed(minutes: float) -> void:
	if _step != Step.DONE and _step != Step.GO_HOME and minutes >= return_hint_hour * 60:
		_step = Step.GO_HOME
		hud.show_tip("Theo mũi tên \"Bến\" về cập bến (E) trước 18:00 để mở quán đúng giờ.")
