class_name HoldUI
extends CanvasLayer
## Boat hold window.
## - Browse mode (open_hold key): game keeps running, clock keeps ticking,
##   unless opened mid-fishing: then the game pauses so the fight can't be lost.
## - Overflow mode (new catch doesn't fit): game is paused, the new fish wait
##   in the tray one at a time (a net haul can bring several). Closing throws
##   away whatever is still waiting.
## - Sell mode (at the lobster raft): game is paused; drag fish onto "Bán" or
##   right-click them to sell one by one, or "Bán hết" (`sold` per fish).
## Runs with PROCESS_MODE_ALWAYS (set in the scene) so it works while paused.

signal closed
## A fish sold in sell mode (money already paid).
signal sold(item: InventoryItem, price: int)

var _overflow: bool = false
## True if this window paused the game and must unpause it on close.
var _paused_game: bool = false
## Overflow fish waiting behind the one currently in the tray.
var _queue: Array[InventoryItem] = []
var _buyer: String = ""
var _sold_count: int = 0
var _sold_money: int = 0
var _sell_all_button: Button

@onready var _view: HoldGridView = %HoldGridView
@onready var _title_label: Label = %TitleLabel
@onready var _info_label: Label = %InfoLabel
@onready var _hint_label: Label = %HintLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_close_button.pressed.connect(close)
	_view.pending_changed.connect(_on_pending_changed)
	_view.item_sold.connect(_on_item_sold)
	_sell_all_button = Button.new()
	_sell_all_button.focus_mode = Control.FOCUS_NONE
	_sell_all_button.pressed.connect(_sell_all)
	_sell_all_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.add_sibling(_sell_all_button)
	_close_button.get_parent().move_child(_sell_all_button, _close_button.get_index())
	_sell_all_button.hide()


func setup(hold: GridInventory) -> void:
	# Callers' _ready may run before ours (sibling order), so wait for @onready vars.
	if not is_node_ready():
		await ready
	_view.set_hold(hold)
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


func is_selling() -> bool:
	return visible and _view.is_selling()


func has_pending() -> bool:
	return visible and _view.pending != null


func sold_count() -> int:
	return _sold_count


func grid_view() -> HoldGridView:
	return _view


## Pause and let the player sell fish to `buyer`; `price_of` = what one fish
## fetches (InventoryItem -> int).
func open_sell(buyer: String, price_of: Callable) -> void:
	_view.cancel_drag()
	_overflow = false
	_view.set_pending(null)
	_buyer = buyer
	_sold_count = 0
	_sold_money = 0
	_view.sell_price = price_of
	_sell_all_button.show()
	_refresh_texts()
	_pause()
	show()


func close() -> void:
	for item in _view.hold.items:  # seen now
		item.is_new = false
	_view.cancel_drag()
	_view.sell_price = Callable()
	_sell_all_button.hide()
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
	if visible:
		_info_label.text = _view.get_hover_text()
		if _view.is_selling():
			var value := 0
			for item in _view.hold.items:
				value += int(_view.sell_price.call(item))
			_sell_all_button.text = "Bán hết khoang: %dk" % value
			_sell_all_button.disabled = _view.hold.items.is_empty()
			if _info_label.text.is_empty() and _sold_count > 0:
				_info_label.text = "Đã bán %d con: +%dk" % [_sold_count, _sold_money]


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


func _on_item_sold(item: InventoryItem) -> void:
	var price := int(_view.sell_price.call(item))
	GameState.add_money(price)
	_sold_count += 1
	_sold_money += price
	sold.emit(item, price)


func _sell_all() -> void:
	for item in _view.hold.items.duplicate():
		_view.hold.remove(item)
		_on_item_sold(item)


func _refresh_texts() -> void:
	_title_label.text = "Khoang thuyền (%dx%d)" % [_view.hold.size.x, _view.hold.size.y] if _view.hold else "Khoang thuyền"
	if _view.is_selling():
		_title_label.text = "Bán cho %s" % _buyer
		_hint_label.text = "Kéo cá vào ô \"Bán\" hoặc chuột phải để bán từng con"
		_close_button.text = "Xong"
		return
	if _view.pending:
		var waiting := " (còn %d con chờ)" % _queue.size() if not _queue.is_empty() else ""
		_hint_label.text = "Khoang đầy!%s" % waiting
		_close_button.text = "Bỏ cá mới & đóng"
	else:
		_hint_label.text = ""  # SeaGuide points at things the first time
		_close_button.text = "Đóng"
