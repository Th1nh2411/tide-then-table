class_name HoldManager
extends Node
## Owns the boat hold for the current sea day. Catches (rod or net) go
## straight into free spots; whatever doesn't fit opens the hold UI in
## (paused) overflow mode.

@export var boat: Boat
@export var fishing: FishingController
@export var nets: NetController
@export var hold_ui: HoldUI
@export var hud: SeaHud

var hold: GridInventory


func _ready() -> void:
	hold = GridInventory.new(boat.boat_data.hold_size)
	hold_ui.setup(hold)
	fishing.fish_caught.connect(add_catch)
	# Hold button on the fishing overlay (shared by rod and net).
	fishing.minigame.hold_requested.connect(_open_hold)
	nets.fish_caught.connect(add_catch)
	boat.boat_data_changed.connect(_on_boat_data_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_hold") and not hold_ui.visible:
		get_viewport().set_input_as_handled()
		_open_hold()


## Mid-fishing the game pauses so sorting the hold can't lose the fish.
func _open_hold() -> void:
	if not hold_ui.visible:
		hold_ui.open_browse(fishing.is_fishing())


## Items to unload at the dock.
func get_items() -> Array[InventoryItem]:
	return hold.items.duplicate()


func add_catch(fish: FishData, quality: float, count: int) -> void:
	GameState.record_catch(fish, count)  # for the phone's Dex
	var overflow: Array[InventoryItem] = []
	for i in count:
		var item := InventoryItem.new(fish, quality)
		if not hold.auto_place(item):
			overflow.append(item)
	if not overflow.is_empty():
		hud.flash_message("Khoang đầy!")
		hold_ui.open_overflow(overflow)


## Boat swapped (debug key now, upgrades later): rebuild the hold at the new
## size and keep whatever still fits.
func _on_boat_data_changed(data: BoatData) -> void:
	var old_items := hold.items.duplicate()
	hold = GridInventory.new(data.hold_size)
	for item in old_items:
		if not hold.auto_place(item):
			push_warning("Hold resize dropped %s" % item.fish.id)
	hold_ui.setup(hold)
