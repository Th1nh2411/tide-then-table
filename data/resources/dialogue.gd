class_name Dialogue
extends Resource
## One conversation. Written as plain text, one line per speech bubble:
##   Bảo: Ê Rin! Lâu quá mới gặp.
##   Rin: ...Bảo?
##   (a line without "Name:" is narration)
## Conditions decide when it can play (see DialogueLibrary.pick). One .tres
## per conversation in res://data/dialogues/, listed on a Talker.

@export var id: String = ""
@export_multiline var script_text: String = ""
## Earliest day it can play.
@export var min_day: int = 1
## Story flag that must be set ("" = none).
@export var requires_flag: String = ""
## Plays only once (remembered as story flag "dlg_<id>", saved with the game).
@export var once: bool = true
## Story flag set when it finishes ("" = none).
@export var sets_flag: String = ""
## Higher plays first when several are eligible.
@export var priority: int = 0
