class_name RestaurantShop3D
extends RefCounted
## Spending in the 3D restaurant: Cô Năm's market (goods go straight to the
## pantry before the shift, into Rin's bag during it), "Sửa quán"
## renovation (RenovationPreview3D) and upgrades.

var host: Node3D


func _init(owner: Node3D) -> void:
	host = owner


func buy_market(dish: DishData, bulk: bool) -> void:
	var cost := dish.buy_cost(bulk)
	if not GameState.spend_money(cost):
		host._show_note("Không đủ tiền mua %s." % dish.display_name)
		return
	if host.shift_running:
		host.bag.add(dish, bulk)
		host._show_note("Mua xong. Đem túi cất vô tủ lạnh (E).")
	else:
		host.market_stock.add(dish, dish.buy_units(bulk))
	host.market_spent += cost
	Sfx.play("bag")
	host.panels.refresh_market()


func open_renovation() -> void:
	if host.renovation == null:
		var renovation := RenovationPreview3D.new()
		host.renovation = renovation
		host.add_child(renovation)
		var list: Array[UpgradeData] = [host.seats_upgrade, host.decor_upgrade, host.kitchen_upgrade, host.fridge_upgrade]
		var spots: Array[Vector3] = []
		spots.assign(RestaurantLayout3D.TABLES)
		renovation.setup(host, spots, list, RestaurantPanels3D.ui_theme())
		renovation.finished.connect(_on_renovation_finished)
	host.planning_panel.hide()
	host.renovation.open()


func _on_renovation_finished(applied: bool) -> void:
	if applied:
		var seats_changed: bool = host.renovation and host.renovation.last_seat_change
		host._show_note("Đã thuê thêm mặt bằng và mở bàn mới." if seats_changed else "Sửa quán xong!")


func buy_upgrade(upgrade: UpgradeData) -> void:
	if GameState.buy_upgrade(upgrade):
		host._show_note("Đã nâng cấp %s. Có hiệu lực từ ca sau." % upgrade.display_name)


func is_renovating() -> bool:
	return host.renovation != null and host.renovation.layer != null and host.renovation.layer.visible
