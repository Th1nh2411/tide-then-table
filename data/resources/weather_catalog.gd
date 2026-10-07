class_name WeatherCatalog
extends Resource
## All weathers, with weighted picking and lookup by id.

@export var weathers: Array[WeatherData] = []


func find(weather_id: String) -> WeatherData:
	for weather in weathers:
		if weather.id == weather_id:
			return weather
	return weathers[0] if not weathers.is_empty() else null


func pick(rng: RandomNumberGenerator) -> WeatherData:
	var weights := PackedFloat32Array()
	for weather in weathers:
		weights.append(weather.weight)
	return weathers[rng.rand_weighted(weights)]
