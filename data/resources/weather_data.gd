class_name WeatherData
extends Resource
## One kind of night at sea. One .tres per weather in res://data/weather/,
## listed in weather_catalog.tres. Rolled each morning for the next trip
## (GameState.weather_id) and applied at sea by WeatherController.

@export var id: String = ""
@export var display_name: String = ""
## Phone forecast line, dev style: "[INFO] forecast: <this>".
@export var forecast: String = ""
## Shown when the night starts.
@export var start_message: String = ""
## Relative chance when rolling.
@export var weight: float = 1.0
## Night tint brightness multiplier (moonlight > 1, rain < 1).
@export var night_brightness: float = 1.0
## Boat lamp radius multiplier.
@export var lamp_scale: float = 1.0
## Lamp oil burn multiplier.
@export var oil_burn_scale: float = 1.0
## Wind drift pushing the boat (px/s); the direction is random each night.
@export var wind_speed: float = 0.0
## Draw rain over the sea.
@export var rain: bool = false
## Added to the spawner's rarity boost (pricier fish bite more).
@export var rarity_bonus: float = 0.0
## Extra fishing spots per zone.
@export var extra_spots: int = 0
## Species id -> spawn weight multiplier tonight (e.g. squid under the moon).
@export var species_bonus: Dictionary = {}
