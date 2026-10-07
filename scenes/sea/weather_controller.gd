class_name WeatherController
extends Node
## Applies tonight's weather (GameState.weather_id) at sea: night brightness,
## lamp radius, oil burn, spots (count and species), wind drift and rain.
## Must run before the spawner places spots (it waits one physics frame).

@export var catalog: WeatherCatalog
@export var day_tint: DayTint
@export var lamp: BoatLamp
@export var oil: LampOil
@export var spawner: FishingSpotSpawner
@export var boat: Boat
@export var dock: Dock
@export var hud: SeaHud
## Screen-space rain layer (shown only when it rains).
@export var rain_overlay: CanvasItem

var weather: WeatherData
var wind: Vector2 = Vector2.ZERO


func _ready() -> void:
	weather = catalog.find(GameState.weather_id)
	if weather == null:
		return
	day_tint.night_color = Color(day_tint.night_color * weather.night_brightness, 1.0)
	day_tint.refresh()
	lamp.weather_scale = weather.lamp_scale
	oil.weather_burn_scale = weather.oil_burn_scale
	spawner.rarity_boost += weather.rarity_bonus
	spawner.big_rarity_boost += weather.rarity_bonus
	spawner.extra_spots = weather.extra_spots
	spawner.species_bonus = weather.species_bonus
	if weather.wind_speed > 0.0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		wind = Vector2.RIGHT.rotated(rng.randf() * TAU) * weather.wind_speed
	if rain_overlay:
		rain_overlay.visible = weather.rain
	hud.set_weather(weather.display_name)
	if weather.start_message:
		hud.flash_message.call_deferred(weather.start_message, 3.0)


func _physics_process(delta: float) -> void:
	# Wind drifts the boat while it can move (not fishing, not docked).
	if wind == Vector2.ZERO or not boat.is_physics_processing() or dock.is_boat_inside():
		return
	boat.move_and_collide(wind * delta)
