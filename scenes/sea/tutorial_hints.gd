class_name TutorialHints
extends Node
## Night-1 tips shown in the HUD, advancing with what the player does:
## start -> first catch -> lamp oil low. Does nothing on later nights.

@export var hud: SeaHud
@export var fishing: FishingController
@export var nets: NetController
@export var oil: LampOil

enum Step { DRIVE, AFTER_CATCH, GO_HOME, DONE }

var _step: Step = Step.DONE


func _ready() -> void:
	if GameState.day != 1:
		return
	_step = Step.DRIVE
	hud.show_tip("Lái bằng WASD. Tìm đám bọt trắng, dừng thuyền rồi bấm E để câu. Đèn câu tốn dầu: hết dầu là phải về.")
	fishing.fish_caught.connect(_on_catch)
	nets.fish_caught.connect(_on_catch)
	oil.oil_low.connect(_on_oil_low)


func _on_catch(_fish: FishData, _quality: float, _count: int, _size: float) -> void:
	if _step == Step.DRIVE:
		_step = Step.AFTER_CATCH
		hud.show_tip("Tab: xem khoang. Q: thả lưới ốc ở vùng nước nông. Màu bọt cho biết loài cá; càng ra xa bờ cá càng xịn và to.")


func _on_oil_low() -> void:
	if _step != Step.DONE and _step != Step.GO_HOME:
		_step = Step.GO_HOME
		hud.show_tip("Dầu sắp cạn, trời sắp sáng. Theo mũi tên \"Bến\" về cập bến (E) trước khi tắt đèn.")
