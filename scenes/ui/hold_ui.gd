class_name HoldUI
extends CanvasLayer
## Boat hold window.
## - Browse mode (open_hold key): game keeps running, clock keeps ticking.
## - Overflow mode (new fish doesn't fit): game is paused, the new fish waits
##   in the tray. Closing with the fish still in the tray throws it away.
## Runs with PROCESS_MODE_ALWAYS (set in the scene) so it works while paused.

signal closed

var _overflow: bool = false

@onready var _view: HoldGridView = %HoldGridView
@onready var _title_label: Label = %TitleLabel
@onready var _info_label: Label = %InfoLabel
@onready var _hint_label: Label = %HintLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_close_button.pressed.connect(close)
	_view.pending_changed.connect(_refresh_texts)


func setup(hold: GridInventory) -> void:
	# Callers' _ready may run before ours (sibling order), so wait for @onready vars.
	if not is_node_ready():
		await ready
	_view.set_hold(hold)
	_refresh_texts()


func open_browse() -> void:
	_overflow = false
	_view.set_pending(null)
	show()


## Pause the game and ask the player to make room for `item`.
func open_overflow(item: InventoryItem) -> void:
	_view.cancel_drag()
	_overflow = true
	_view.set_pending(item)
	get_tree().paused = true
	show()


func close() -> void:
	_view.cancel_drag()
	# Anything left in the tray is thrown back into the sea.
	_view.set_pending(null)
	if _overflow:
		_overflow = false
		get_tree().paused = false
	hide()
	closed.emit()


func _process(_delta: float) -> void:
	if visible:
		_info_label.text = _view.get_hover_text()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("open_hold") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("interact"):
		# Don't start fishing or docking behind the open window.
		get_viewport().set_input_as_handled()


func _refresh_texts() -> void:
	_title_label.text = "Khoang thuyền (%dx%d)" % [_view.hold.size.x, _view.hold.size.y] if _view.hold else "Khoang thuyền"
	if _view.pending:
		_hint_label.text = "Khoang đầy! Kéo cá mới vào khoang, xoay (R) hoặc bỏ bớt cá cũ."
		_close_button.text = "Bỏ cá mới & đóng"
	else:
		_hint_label.text = "Kéo-thả để xếp · R: xoay khi đang kéo · thả vào \"Bỏ\" để vứt · Tab: đóng"
		_close_button.text = "Đóng"
