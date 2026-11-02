class_name FixedMenuData
extends Resource
## The horror build's restaurant menu: a few fixed dishes guests order from.
## Bảo cooks every non-instant one; instant ones (beer) Rin takes at the keg.
## No stock, no planning: everything is always available.

@export var dishes: Array[DishData] = []
