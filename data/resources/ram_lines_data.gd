class_name RamLinesData
extends Resource
## Every line of đêm rằm (PLAN §10 H7) in one place: "Name: text" per line,
## no name = narration. Read by RamGuest3D, RamShore3D, RamSea3D,
## RamEpilogue3D and the ending card.

@export_group("Restaurant")
@export_multiline var ut_offer: Array[String] = []
@export var choice_drink := "Uống"
@export var choice_refuse := "Thôi, em không uống"
@export_multiline var ut_drank: Array[String] = []
@export_multiline var ut_refused: Array[String] = []
@export_multiline var bao: String = ""
@export_multiline var co_nam: String = ""
@export_group("Waterfront")
@export_multiline var shore: Array[String] = []
## After the house door on rằm: heard over the black before waking.
@export_multiline var gate_closed: Array[String] = []
@export_group("Sea")
@export_multiline var whispers_drank: Array[String] = []
@export_multiline var ut_at_sea: Array[String] = []
@export_multiline var whispers_trail: Array[String] = []
@export_multiline var ut_seen: Array[String] = []
@export_group("Endings")
@export_multiline var dawn: Array[String] = []
@export_multiline var grandpa: String = ""
@export_multiline var drowned: Array[String] = []
@export_multiline var card_true: Array[String] = []
@export_multiline var card_drowned: Array[String] = []
@export var card_title_true := "Hết."
@export var card_title_drowned := "Hết?"


## Lines as DialogueBox dictionaries ({speaker, text}).
static func parse(lines: Array[String]) -> Array[Dictionary]:
	return DialogueLibrary.parse("\n".join(lines))
