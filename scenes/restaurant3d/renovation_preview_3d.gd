class_name RenovationPreview3D
extends Node
## "Sửa quán" in 3D: pick levels, see new tables / decor right in the room
## (green ghosts), then Hủy or Xác nhận (pays). Only upgrades, never downgrades.

signal finished(applied: bool)

var upgrades: Array[UpgradeData] = []
var room: Node3D
var tables: Array[Vector3] = []
var theme: Theme
var preview: Dictionary = {}
var ghosts: Node3D
var panel: PanelContainer
var rows: VBoxContainer
var confirm: Button
var layer: CanvasLayer


func setup(room_node: Node3D, table_spots: Array[Vector3], list: Array[UpgradeData], ui_theme: Theme) -> void:
	room = room_node
	tables = table_spots
	upgrades = list.filter(func(u: UpgradeData) -> bool: return u != null)
	theme = ui_theme


func open() -> void:
	preview.clear()
	for u: UpgradeData in upgrades:
		preview[u] = GameState.get_upgrade_level(u.id)
	if layer == null:
		_build_ui()
	layer.show()
	_refresh()


func close() -> void:
	if layer:
		layer.hide()
	_clear_ghosts()


func total_cost() -> int:
	var total := 0
	for u: UpgradeData in preview:
		for lv: int in range(GameState.get_upgrade_level(u.id), int(preview[u])):
			total += u.next_cost(lv)
	return total


func cancel() -> void:
	close()
	finished.emit(false)


func apply() -> bool:
	if not GameState.spend_money(total_cost()):
		return false
	_solidify()
	for u: UpgradeData in preview:
		GameState.upgrade_levels[u.id] = int(preview[u])
	close()
	finished.emit(true)
	return true


func set_level(u: UpgradeData, level: int) -> void:
	preview[u] = clampi(level, GameState.get_upgrade_level(u.id), u.max_level())
	_refresh()


func _refresh() -> void:
	_clear_ghosts()
	ghosts = Node3D.new()
	room.add_child(ghosts)
	_draw_additions(ghosts, true)
	for c in rows.get_children():
		c.queue_free()
	for u: UpgradeData in upgrades:
		var row := HBoxContainer.new()
		rows.add_child(row)
		var lv: int = preview[u]
		var label := Label.new()
		label.text = "%s: %s" % [u.display_name, u.label_at(lv)]
		label.custom_minimum_size.x = 250
		row.add_child(label)
		var less := Button.new()
		less.text = "-"
		less.focus_mode = Control.FOCUS_NONE
		less.disabled = lv <= GameState.get_upgrade_level(u.id)
		less.pressed.connect(set_level.bind(u, lv - 1))
		row.add_child(less)
		var more := Button.new()
		more.text = "+"
		more.focus_mode = Control.FOCUS_NONE
		more.disabled = lv >= u.max_level()
		more.pressed.connect(set_level.bind(u, lv + 1))
		row.add_child(more)
	var cost := total_cost()
	confirm.text = "Xác nhận" if cost == 0 else "Xác nhận (-%dk)" % cost
	if cost > GameState.money:
		confirm.text = "Thiếu tiền (%dk)" % cost
	confirm.disabled = cost > GameState.money


## Things the previewed levels add over what the room already shows.
func _draw_additions(parent: Node3D, ghost: bool) -> void:
	var color := Color(0.3, 1.0, 0.45, 0.55) if ghost else Color.WHITE
	var seats_u: UpgradeData = _find("seats")
	if seats_u:
		var have := _table_count(GameState.get_upgrade_level(seats_u.id), seats_u)
		for i: int in range(have, _table_count(int(preview.get(seats_u, 0)), seats_u)):
			var table: Node3D = RestaurantRoomBuilder3D.TABLE_PILOT.instantiate()
			parent.add_child(table)
			table.position = tables[i]
			if ghost:
				RestaurantBatchVisuals.tint(table, color)
			for side in [-1.0, 1.0]:
				var stool: Node3D = RestaurantRoomBuilder3D.STOOL_PILOT.instantiate()
				parent.add_child(stool)
				stool.position = tables[i] + Vector3(side * 1.02, 0, 0)
				if ghost:
					RestaurantBatchVisuals.tint(stool, color)
	var decor_u: UpgradeData = _find("decor")
	if decor_u:
		var now := GameState.get_upgrade_level(decor_u.id)
		var want: int = preview.get(decor_u, 0)
		if want > 0 and now == 0:
			for x in RestaurantScene3D.DECOR_LANTERNS:
				_box(parent, Vector3(x, 2.02, RestaurantScene3D.BACK_Z + 1.2), Vector3(0.33, 0.28, 0.33), color if ghost else Color("de9e41"))
		if want > 1 and now <= 1:
			for x in RestaurantScene3D.DECOR_PLANTERS:
				var plant := RestaurantBatchVisuals.add(parent, "plant_pot", Vector3(x, 0, RestaurantScene3D.PLANTER_Z))
				if ghost:
					RestaurantBatchVisuals.tint(plant, color)

	if ghost:
		for id: String in ["kitchen", "fridge"]:
			var u := _find(id)
			if u == null or int(preview.get(u, 0)) == GameState.get_upgrade_level(id):
				continue
			var current := room.get_node_or_null("BatchUpgrade_" + id) as Node3D
			if current:
				current.visible = false
			var choices := ["food_cart_0", "food_cart_1", "food_cart_2"] if id == "kitchen" else ["fridge_0", "fridge_1", "fridge_2"]
			var at := RestaurantLayout3D.GRILL_POSITION if id == "kitchen" else MarketBag3D.FRIDGE_POSITION
			var model := RestaurantBatchVisuals.add(parent, choices[clampi(int(preview[u]), 0, 2)], at)
			RestaurantBatchVisuals.tint(model, color)


func _table_count(level: int, u: UpgradeData) -> int:
	return clampi(int(u.value_at(level)), 1, tables.size())


func _find(id: String) -> UpgradeData:
	for u: UpgradeData in upgrades:
		if u.id == id:
			return u
	return null


## Confirmed: keep the ghosts' shapes as real props (full colour).
func _solidify() -> void:
	_clear_ghosts()
	var real := Node3D.new()
	room.add_child(real)
	_draw_additions(real, false)


func _clear_ghosts() -> void:
	if is_instance_valid(room):
		for id: String in ["kitchen", "fridge"]:
			var current := room.get_node_or_null("BatchUpgrade_" + id) as Node3D
			if current:
				current.visible = true
	if ghosts and is_instance_valid(ghosts):
		ghosts.queue_free()
	ghosts = null


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = pos


func _build_ui() -> void:
	layer = CanvasLayer.new()
	add_child(layer)
	panel = PanelContainer.new()
	panel.theme = theme
	panel.add_theme_stylebox_override("panel", RestaurantPanels3D.panel_style())
	panel.position = Vector2(120, 72)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "SỬA QUÁN • xem thử rồi xác nhận"
	box.add_child(title)
	rows = VBoxContainer.new()
	box.add_child(rows)
	var bar := HBoxContainer.new()
	box.add_child(bar)
	var no := Button.new()
	no.text = "Hủy"
	no.pressed.connect(cancel)
	bar.add_child(no)
	confirm = Button.new()
	confirm.pressed.connect(apply)
	bar.add_child(confirm)
