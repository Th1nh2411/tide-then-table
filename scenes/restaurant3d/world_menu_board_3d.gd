class_name WorldMenuBoard3D
extends Node3D
## A physical, event-driven menu display using the same approved icons as the UI.

var plan: MenuPlan
var catalog: DishCatalog
var displayed_dishes: Array[DishData] = []
var _viewport: SubViewport
var _grid: GridContainer

func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(960, 600)
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)
	var background := ColorRect.new()
	background.size = Vector2(960, 600)
	background.color = Color("243b38")
	_viewport.add_child(background)
	var title := Label.new()
	title.text = "THỰC ĐƠN"
	title.position = Vector2(0, 8)
	title.size.x = 960
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("f2d98a"))
	_viewport.add_child(title)
	_grid = GridContainer.new()
	_grid.position = Vector2(20, 90)
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_viewport.add_child(_grid)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.30, .70)
	face.mesh = quad
	face.position = Vector3(0, 1.025, .105)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	face.material_override = material
	add_child(face)

func bind(menu_plan: MenuPlan, dishes: DishCatalog) -> void:
	if plan and plan.changed.is_connected(refresh):
		plan.changed.disconnect(refresh)
	plan = menu_plan
	catalog = dishes
	plan.changed.connect(refresh)
	refresh()

func refresh() -> void:
	displayed_dishes = plan.get_dishes()
	for dish in catalog.dishes:
		if dish.on_menu_today() and dish not in displayed_dishes:
			displayed_dishes.append(dish)
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var columns := clampi(displayed_dishes.size(), 1, 3)
	if displayed_dishes.size() > 3:
		columns = ceili(displayed_dishes.size() / 2.0)
	_grid.columns = columns
	var cell_width := (920.0 - 8 * (columns - 1)) / columns
	var picture_height := 158 if displayed_dishes.size() > 3 else 280
	for dish in displayed_dishes:
		var card := VBoxContainer.new()
		card.custom_minimum_size.x = cell_width
		_grid.add_child(card)
		var picture := TextureRect.new()
		picture.texture = Art.texture("dishes/" + dish.id)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.custom_minimum_size = Vector2(cell_width, picture_height)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(picture)
		var caption := Label.new()
		caption.text = dish.display_name
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.custom_minimum_size.x = cell_width
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 28)
		card.add_child(caption)
	if displayed_dishes.is_empty():
		var empty := Label.new()
		empty.text = "Lên món hôm nay"
		empty.add_theme_font_size_override("font_size", 42)
		_grid.add_child(empty)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
