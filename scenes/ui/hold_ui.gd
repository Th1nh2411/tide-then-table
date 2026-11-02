class_name HoldUI
extends CanvasLayer
## Boat hold window.
## - Browse mode (open_hold key): game keeps running, clock keeps ticking,
##   unless opened mid-fishing: then the game pauses so the fight can't be lost.
## - Overflow mode (new catch doesn't fit): game is paused, the new fish wait
##   in the tray one at a time (a net haul can bring several). Closing throws
##   away whatever is still waiting.
## Runs with PROCESS_MODE_ALWAYS (set in the scene) so it works while paused.
## Look: a wooden fish crate ("CratePanel") with wet slots, a small wooden
## sign (crate icon + how full) hanging over its top-left edge, an icon
## close button on the top-right corner, a paper tag with the fish under the
## mouse and a red "ĐẦY!" stamp. (No selling: no money in the horror build.)

signal closed

var _overflow: bool = false
## True if this window paused the game and must unpause it on close.
var _paused_game: bool = false
## Overflow fish waiting behind the one currently in the tray.
var _queue: Array[InventoryItem] = []
var _sign_icon: TextureRect
var _shown_hover: String = "-"

@onready var _view: HoldGridView = %HoldGridView
@onready var _title_label: Label = %TitleLabel
@onready var _info_label: Label = %InfoLabel
@onready var _hint_label: Label = %HintLabel
@onready var _close_button: Button = %CloseButton
@onready var _panel: PanelContainer = %Panel
@onready var _sign: PanelContainer = %Sign
@onready var _info_tag: PanelContainer = %InfoTag


func _ready() -> void:
	hide()
	_close_button.pressed.connect(close)
	UiIcons.dress(_close_button, "close", 12)
	_close_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFx.hover_lift(_close_button, 0.08)
	_view.pending_changed.connect(_on_pending_changed)
	_sign_icon = UiIcons.make("crate", 12, UiIcons.GOLD)
	%SignRow.add_child(_sign_icon)
	%SignRow.move_child(_sign_icon, 0)
	_panel.resized.connect(_place_decor)
	visibility_changed.connect(func() -> void:
		if visible:
			_open_fx.call_deferred())
	UiFx.tilt(_sign, -3.0)


func _open_fx() -> void:
	_place_decor()
	UiFx.pop_in(_panel)
	UiFx.settle(_sign, Vector2(0, -10), 0.1, -10.0)


## Sign over the crate's top-left edge, close button on its top-right corner.
func _place_decor() -> void:
	_sign.reset_size()
	_sign.position = _panel.position + Vector2(-8, -_sign.size.y + 10)
	_close_button.position = _panel.position + Vector2(_panel.size.x - _close_button.size.x + 4, -10)


func setup(hold: GridInventory) -> void:
	# Callers' _ready may run before ours (sibling order), so wait for @onready vars.
	if not is_node_ready():
		await ready
	_view.set_hold(hold)
	if not hold.changed.is_connected(_refresh_texts):
		hold.changed.connect(_refresh_texts)
	_refresh_texts()


## `pause_game`: freeze everything else while open (used during fishing).
func open_browse(pause_game: bool = false) -> void:
	_overflow = false
	_view.set_pending(null)
	if pause_game:
		_pause()
	show()


## Pause the game and ask the player to make room for `items`.
func open_overflow(items: Array[InventoryItem]) -> void:
	_view.cancel_drag()
	_queue.append_array(items)
	_overflow = true
	if _view.pending == null:
		_view.set_pending(_queue.pop_front())
	_pause()
	show()


func has_pending() -> bool:
	return visible and _view.pending != null


func grid_view() -> HoldGridView:
	return _view


func close() -> void:
	for item in _view.hold.items:  # seen now
		item.is_new = false
	_view.cancel_drag()
	# Anything left in the tray or queue is thrown back into the sea.
	_queue.clear()
	_view.set_pending(null)
	_overflow = false
	if _paused_game:
		_paused_game = false
		get_tree().paused = false
	_refresh_texts()
	hide()
	closed.emit()


func _pause() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		_paused_game = true


func _process(_delta: float) -> void:
	if not visible:
		return
	var text := _view.get_hover_text()
	if text == _shown_hover:
		return
	_shown_hover = text
	_info_label.text = text
	_info_label.visible = text != ""
	_info_tag.visible = text != ""
	if _info_tag.visible:
		UiFx.bounce(_info_tag, 0.06)


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


## Sign, stamp and close icon for the current mode (pictures, few words).
func _refresh_texts() -> void:
	var hold := _view.hold
	var fill := roundi(hold.fill_fraction() * 100.0) if hold else 0
	_sign.tooltip_text = "Khoang thuyền %dx%d" % [hold.size.x, hold.size.y] if hold else "Khoang thuyền"
	_title_label.text = "%d%%" % fill
	_sign_icon.texture = UiIcons.sticker("crate", 12, UiIcons.GOLD)
	_hint_label.hide()
	_close_button.icon = UiIcons.sticker("close", 12, UiIcons.CREAM)
	if _view.pending:
		var waiting := " +%d" % _queue.size() if not _queue.is_empty() else ""
		_hint_label.text = "ĐẦY!%s" % waiting
		_hint_label.show()
		_close_button.tooltip_text = "Bỏ cá mới & đóng"
	else:
		_close_button.tooltip_text = "Đóng (Tab)"
