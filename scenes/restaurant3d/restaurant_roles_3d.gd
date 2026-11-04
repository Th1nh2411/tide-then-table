class_name RestaurantRoles3D
extends Node
## Who talks in the restaurant street besides Vy (PLAN §10 "Mọi nhân vật
## đều có vai trò"), each E one short subtitle from data:
## - Bảo at his cart (looked at): in-shop news by day, anh Út's wet money
##   mùng 12-14 (data/story/bao.tres); tonight's omen first when he has one.
## - Cô Năm at her counter: the rằm line, tonight's omen tell
##   (OmenData.co_nam_line), then the day's gossip (data/story/co_nam.tres).
## - anh Út at his table (AnhUtRegular3D), or the guest without a shadow.
## One line in RestaurantScene3D._ready; RestaurantInteract3D asks it.

const BAO: NpcLinesData = preload("res://data/story/bao.tres")
const CO_NAM: NpcLinesData = preload("res://data/story/co_nam.tres")
const NODE_NAME := "Roles"
const BAO_REACH := 2.7

var host: RestaurantScene3D
var bao: NpcTalk3D
var co_nam: NpcTalk3D
var ut: AnhUtRegular3D


static func attach(owner: RestaurantScene3D) -> RestaurantRoles3D:
	var roles := RestaurantRoles3D.new()
	roles.name = NODE_NAME
	roles.host = owner
	owner.add_child(roles)
	return roles


static func of(owner: Node) -> RestaurantRoles3D:
	return owner.get_node_or_null(NODE_NAME) as RestaurantRoles3D


func _ready() -> void:
	bao = NpcTalk3D.new(host.bao_model, BAO, BAO_REACH)
	bao.turn = false
	bao.head_height = 1.5
	co_nam = NpcTalk3D.new(null, CO_NAM)
	if RamNight.is_ram():
		co_nam.first.append(RamFx3D.LINES.co_nam)
	var omen := OmenPicker.tonight()
	if omen and omen.co_nam_line != "":
		co_nam.first.append(CO_NAM.format(omen.co_nam_line))
	ut = AnhUtRegular3D.attach(host)


## Cô Năm's next line (Rin is at her counter).
func co_nam_say() -> void:
	host._show_note(co_nam.say())


## E on Bảo / anh Út / the shadowless guest: true when someone answered.
func talk(at: Vector3) -> bool:
	var camera := host.demo_camera
	if ut and ut.seated() and ut.talk.can_talk(at, camera):
		host._show_note(ut.talk.say())
		return true
	if ut and ut.ghost_near(at):
		host._show_note(ut.ghost_line())
		return true
	if bao.can_talk(at, camera):
		host._show_note(bao.say())
		return true
	return false


## "[E] Nói chuyện · ..." for RestaurantPrompt3D ({} = none).
func hint(at: Vector3) -> Dictionary:
	var camera := host.demo_camera
	if ut and ut.seated() and ut.talk.can_talk(at, camera):
		return {"at": AnhUtRegular3D.SEAT + Vector3(0, 1.7, 0), "words": "[E] Nói chuyện · Anh Út"}
	if bao.can_talk(at, camera):
		return {"at": host.bao_model.global_position + Vector3(0, 2.0, 0), "words": "[E] Nói chuyện · Bảo"}
	return {}
