class_name OmenData
extends Resource
## One omen of the ghost month (PLAN §10): a custom gone wrong that warns Rin
## not to go out tonight. The scene node for `where` draws the normal version
## of the same thing every night and this omen's version on its night
## (OmenPicker picks at most one per night).

enum Where { RESTAURANT, STREET, DOCK }

## Matches the presentation code's switch (RestaurantOmens3D, StreetOmens3D, DockOmens3D).
@export var id: String = ""
@export var where: Where = Where.RESTAURANT
## Short name for notes / debug ("Mâm cúng bị ăn dở").
@export var title: String = ""
## Words the omen shows, if any (a dish on the LED board, a voice).
@export var text: String = ""
## The normal counterpart shown on other nights.
@export var calm_text: String = ""
## Cô Năm's first line on this omen's night ("" = she says nothing about it).
@export var co_nam_line: String = ""
@export var weight: float = 1.0
## The normal state is itself an eerie ghost-month custom (a "false omen":
## strange but right) that only shows on some nights (OmenPicker.customs);
## otherwise the normal state is there every night.
@export var custom: bool = false
