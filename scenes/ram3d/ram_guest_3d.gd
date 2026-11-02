class_name RamGuest3D
extends Node3D
## Anh Út at the restaurant on rằm (PLAN §10 H7): late in the shift (or at
## closing) he rides in and sits at his own small table by the board. Rin
## walks up, E: he pours ginger tea "cho ấm bụng rồi ra khơi" — drink or not
## (RamNight.TEA_FLAG). Bảo says one line about him when he arrives. One
## line in RestaurantScene3D._ready (attach); nothing on other days.

const L := RamFx3D.LINES
const TABLE := Vector3(8.6, 0, 2.2)
const REACH := 1.9
## Arrives when this fraction of the shift is left.
@export var arrive_at_fraction := 0.45

var host: RestaurantScene3D
var arrived := false
var answered := false
var _rig: PersonRig3D
var _cup: MeshInstance3D
var _text: OnScreenText
var _box: DialogueBox
var _talking := false


static func attach(owner: RestaurantScene3D) -> RamGuest3D:
	if not RamNight.is_ram():
		return null
	var guest := RamGuest3D.new()
	guest.name = "AnhUt"
	guest.host = owner
	owner.add_child(guest)
	return guest


func _ready() -> void:
	answered = RamNight.tea_answered()
	var table: Node3D = RestaurantRoomBuilder3D.TABLE_PILOT.instantiate()
	add_child(table)
	table.position = TABLE
	table.rotation.y = RestaurantLayout3D.TABLE_YAW
	RestaurantRoomBuilder3D.solid_block(self, TABLE + Vector3(0, 0.8, 0), RestaurantLayout3D.TABLE_COLLISION_SIZE)
	var seat := TABLE + Vector3(0.95, 0, 0)
	var stool: Node3D = RestaurantRoomBuilder3D.STOOL_PILOT.instantiate()
	add_child(stool)
	stool.position = seat
	stool.scale = Vector3.ONE * WorldPresentation3D.RESTAURANT_STOOL_SCALE
	_rig = PersonRig3D.build(self, "guest_rich")
	_rig.position = seat
	_rig.rotation.y = -PI * 0.5  # facing the table (and Rin's side of it)
	_rig.set_seated(true)
	_rig.visible = false
	# Tea pot + cup on his table.
	OmenProps3D.box(self, TABLE + Vector3(0.1, 0.92, -0.2), Vector3(0.18, 0.16, 0.18), "6b4a32")
	_cup = OmenProps3D.box(self, TABLE + Vector3(-0.2, 0.88, 0.15), Vector3(0.08, 0.08, 0.08), "e8d9b7")
	_cup.visible = false
	_text = OnScreenText.new()
	add_child(_text)
	_box = DialogueBox.new()
	add_child(_box)


func _process(_delta: float) -> void:
	if not arrived:
		var late: bool = host.shift_running and host.seconds_left <= RestaurantShift3D.SHIFT_SECONDS * arrive_at_fraction
		if late or host.shift_over:
			arrive()
		return
	_text.prompt("E  Ngồi với anh Út" if can_talk() else "")


func arrive() -> void:
	if arrived:
		return
	arrived = true
	_rig.visible = true
	_cup.visible = true
	host._show_note(L.bao)


func can_talk() -> bool:
	return arrived and not answered and not _talking and not get_tree().paused \
		and Walker3D.near(host.player, TABLE, REACH)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_E or not can_talk():
		return
	get_viewport().set_input_as_handled()
	talk()


## The offer, the choice, his answer.
func talk() -> void:
	_talking = true
	_text.prompt("")
	var lines := RamLinesData.parse(L.ut_offer)
	for i in lines.size():
		_box.show_line(lines[i]["speaker"], lines[i]["text"])
		if i < lines.size() - 1:
			await _box.await_advance()
	var index := await _box.choose(PackedStringArray([L.choice_drink, L.choice_refuse]))
	answer(index == 0)
	await _box.play_lines(RamLinesData.parse(L.ut_drank if index == 0 else L.ut_refused))
	_talking = false


## Stores the choice (the bot calls this directly).
func answer(drink: bool) -> void:
	answered = true
	RamNight.set_tea(drink)
	Sfx.play("tea")
	if drink:
		_cup.visible = false
