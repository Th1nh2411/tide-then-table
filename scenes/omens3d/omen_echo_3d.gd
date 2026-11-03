class_name OmenEcho3D
extends Node3D
## A subtle omen's second tell on the evening waterfront (research 1.2): a
## few seconds after Rin walks down to the waterfront after the shift, a sound from the pier head
## (OmenData.echo_sound, placed in the world) and a neighbour's line
## (echo_line). Only on the night of an omen that has one; dock omens get
## their second tell from Cô Năm at the restaurant instead.

const NODE_NAME := "OmenEcho"

@export var delay := 3.5
@export var line_seconds := 4.5

var host: VillageScene3D
var sound_at := Vector3.ZERO
var omen: OmenData
var played := false
var _left := 0.0


## Added only on an evening whose omen has an echo; null otherwise.
static func attach(owner: VillageScene3D, at: Vector3) -> OmenEcho3D:
	var tonight := OmenPicker.tonight()
	if tonight == null or tonight.echo_line == "":
		return null
	var echo := OmenEcho3D.new()
	echo.name = NODE_NAME
	echo.host = owner
	echo.sound_at = at
	echo.omen = tonight
	owner.add_child(echo)
	return echo


func _ready() -> void:
	_left = delay


func _process(delta: float) -> void:
	if played or host.leaving:
		return
	_left -= delta
	if _left <= 0.0:
		play()


func play() -> void:
	played = true
	if omen.echo_sound != "":
		Sfx.duck(1.4)
		Sfx.play_at(omen.echo_sound, sound_at, host, 1.0, 4.0)
	host.text.say(omen.echo_line, line_seconds)
