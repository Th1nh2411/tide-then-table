class_name HoldUI
extends CanvasLayer
## Boat hold window.
## - Browse mode (open_hold key): game keeps running, clock keeps ticking.
## - Overflow mode (new catch doesn't fit): game is paused, the new fish wait
##   in the tray one at a time (a net haul can bring several). Closing throws
##   away whatever is still waiting.
## Runs with PROCESS_MODE_ALWAYS (set in the scene) so it works while paused.

signal closed

var _overflow: bool = false
## Overflow fish waiting behind the one currently in the tray.
var _queue: Array[InventoryItem] = []

@onready var _view: HoldGridView = %HoldGridView
@onready var _title_label: Label = %TitleLabel
@onready var _info_label: Label = %InfoLabel
@onready var _hint_label: Label = %HintLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_close_button.pressed.connect(close)
	_view.pending_changed.connect(_on_pending_changed)


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


## Pause the game and ask the player to make room for `items`.
func open_overflow(items: Array[InventoryItem]) -> void:
	_view.cancel_drag()
	_queue.append_array(items)
	_overflow = true
	if _view.pending == null:
		_view.set_pending(_queue.pop_front())
	get_tree().paused = true
	show()


func close() -> void:
	_view.cancel_drag()
	# Anything left in the tray or queue is thrown back into the sea.
	_queue.clear()
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


## Tray emptied (placed or discarded): bring in the next waiting fish.
func _on_pending_changed() -> void:
	if _view.pending == null and not _queue.is_empty():
		_view.set_pending(_queue.pop_front())  # re-enters here with pending set
		return
	_refresh_texts()


func _refresh_texts() -> void:
	_title_label.text = "Khoang thuyền (%dx%d)" % [_view.hold.size.x, _view.hold.size.y] if _view.hold else "Khoang thuyền"
	if _view.pending:
		var waiting := " (còn %d con chờ)" % _queue.size() if not _queue.is_empty() else ""
		_hint_label.text = "Khoang đầy! Kéo cá mới vào khoang, xoay (R) hoặc bỏ bớt cá cũ.%s" % waiting
		_close_button.text = "Bỏ cá mới & đóng"
	else:
		_hint_label.text = "Kéo-thả để xếp · R: xoay khi đang kéo · thả vào \"Bỏ\" để vứt · Tab: đóng"
		_close_button.text = "Đóng"
