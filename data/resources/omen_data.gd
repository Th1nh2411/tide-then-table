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
## 0 = obvious (a voice, a dish that does not exist) .. 1 = subtle (a detail
## you must know to notice). OmenPicker keeps early days obvious.
@export_range(0.0, 1.0) var subtlety: float = 0.3
## Subtle omens' second tell elsewhere that night: a line overheard on the
## evening waterfront (restaurant / street omens; dock omens use co_nam_line)
## and a sound placed at the pier with it (Sfx recipe, "" = none).
@export var echo_line: String = ""
@export var echo_sound: String = ""
## Printed on the mùng 9 paper after a loop reset that missed this omen:
## vague, never naming the rule.
@export var missed_hint: String = ""
