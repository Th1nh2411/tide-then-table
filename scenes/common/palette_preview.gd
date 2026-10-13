class_name PalettePreview
extends CanvasLayer
## Debug view of the art direction: the whole screen redrawn with only the
## game palette (assets/palette/xom_den.hex: Apollo + 6 colours of our own),
## so placeholders and new art can be judged in the final colours.
## SceneRouter toggles it with F7 (debug builds).

const PALETTE_PATH := "res://assets/palette/xom_den.hex"
const MAX_COLORS := 64


func _ready() -> void:
	layer = 99  # over the game and its dialogs, under SceneRouter's fade
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://scenes/common/palette_preview.gdshader")
	var colors := load_palette()
	var values := PackedVector3Array()
	for color in colors:
		values.append(Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("palette", values)
	material.set_shader_parameter("count", mini(colors.size(), MAX_COLORS))
	rect.material = material
	add_child(rect)


## The palette's colours, from the .hex file (one RRGGBB per line).
static func load_palette(path: String = PALETTE_PATH) -> Array[Color]:
	var colors: Array[Color] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return colors
	while not file.eof_reached():
		var line := file.get_line().strip_edges().trim_prefix("#")
		if line.length() == 6 and line.is_valid_hex_number():
			colors.append(Color.html(line))
	return colors
