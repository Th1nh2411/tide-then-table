class_name HorrorBed
extends RefCounted
## The horror build's background "bed", made in code (no audio files): an
## old tape hissing, a vinyl record crackling, a broken radio drifting
## through static, glitches that drop or stutter the sound, and a low,
## slightly detuned drone. Each place mixes the layers differently (MIXES).
## Pure logic: build(name) returns a looping AudioStreamWAV.

const RATE := 22050
const SECONDS := 9.0
## Layer volumes per place: hiss, crackle, radio, glitch, drone.
const MIXES := {
	"room": {"hiss": 0.05, "crackle": 0.16, "radio": 0.0, "glitch": 0.3, "drone": 0.05},
	"street": {"hiss": 0.035, "crackle": 0.1, "radio": 0.05, "glitch": 0.5, "drone": 0.035},
	"sea": {"hiss": 0.045, "crackle": 0.06, "radio": 0.07, "glitch": 0.7, "drone": 0.06},
}


static func build(mix_name: String) -> AudioStreamWAV:
	var mix: Dictionary = MIXES.get(mix_name, MIXES["room"])
	var n := int(SECONDS * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mix_name)
	_hiss(out, float(mix["hiss"]), rng)
	_crackle(out, float(mix["crackle"]), rng)
	_radio(out, float(mix["radio"]), rng)
	_drone(out, float(mix["drone"]))
	_glitch(out, float(mix["glitch"]), rng)
	_fade_seam(out, int(0.05 * RATE))
	return _to_wav(out)


## Tape hiss: bright noise whose level wobbles slowly (worn tape, wow).
static func _hiss(out: PackedFloat32Array, volume: float, rng: RandomNumberGenerator) -> void:
	if volume <= 0.0:
		return
	var smooth := 0.0
	for i in out.size():
		var t := float(i) / RATE
		smooth += (rng.randf_range(-1.0, 1.0) - smooth) * 0.7
		var wow := 0.8 + 0.2 * sin(TAU * t / 3.0) + 0.06 * sin(TAU * t * 1.7)
		out[i] += smooth * volume * wow


## Vinyl crackle: sparse sharp ticks, now and then a fatter pop.
static func _crackle(out: PackedFloat32Array, volume: float, rng: RandomNumberGenerator) -> void:
	if volume <= 0.0:
		return
	var i := 0
	while i < out.size():
		i += rng.randi_range(int(RATE * 0.01), int(RATE * 0.12))
		var pop := rng.randf() < 0.08
		var length := rng.randi_range(40, 160) if pop else rng.randi_range(6, 24)
		var amp := volume * (2.2 if pop else rng.randf_range(0.4, 1.0))
		var sign := 1.0 if rng.randf() < 0.5 else -1.0
		for k in length:
			var at := i + k
			if at >= out.size():
				break
			out[at] += sign * amp * exp(-float(k) / (length * 0.25)) * rng.randf_range(0.6, 1.0)


## Broken radio: mid-band static that fades in and out in bursts, with a thin
## tuning whistle sliding underneath.
static func _radio(out: PackedFloat32Array, volume: float, rng: RandomNumberGenerator) -> void:
	if volume <= 0.0:
		return
	var low := 0.0
	var band := 0.0
	var phase := 0.0
	var gate := 0.0
	var target := 0.0
	for i in out.size():
		var t := float(i) / RATE
		if i % int(RATE * 0.25) == 0:
			target = 1.0 if rng.randf() < 0.45 else 0.0
		gate += (target - gate) * 0.0008
		var white := rng.randf_range(-1.0, 1.0)
		low += (white - low) * 0.35
		band += ((white - low) - band) * 0.5  # crude band-pass: no hiss, no rumble
		var whistle_hz := 900.0 + 500.0 * sin(TAU * t / 7.0)
		phase = fmod(phase + whistle_hz / RATE, 1.0)
		out[i] += (band * 1.6 + sin(phase * TAU) * 0.12) * volume * gate


## Low drone: two sines a few cents apart beat slowly against each other.
static func _drone(out: PackedFloat32Array, volume: float) -> void:
	if volume <= 0.0:
		return
	for i in out.size():
		var t := float(i) / RATE
		var s := sin(TAU * 55.0 * t) + 0.8 * sin(TAU * 55.7 * t) + 0.3 * sin(TAU * 82.4 * t)
		out[i] += s * volume * (0.7 + 0.3 * sin(TAU * t / SECONDS))


## Glitches: short dropouts (the tape catching) and stutters (a slice repeated).
## `amount` 0..1 sets how many per loop.
static func _glitch(out: PackedFloat32Array, amount: float, rng: RandomNumberGenerator) -> void:
	var count := int(round(amount * 6.0))
	for g in count:
		var start := rng.randi_range(int(RATE * 0.3), out.size() - int(RATE * 0.6))
		if rng.randf() < 0.5:
			var length := rng.randi_range(int(RATE * 0.04), int(RATE * 0.18))
			for k in length:
				out[start + k] *= 0.05
		else:
			var slice := rng.randi_range(int(RATE * 0.015), int(RATE * 0.04))
			for rep in range(1, 4):
				for k in slice:
					out[start + rep * slice + k] = out[start + k] * 1.3


static func _fade_seam(out: PackedFloat32Array, width: int) -> void:
	var n := out.size()
	for i in width:
		var w := float(i) / width
		out[i] = out[i] * w + out[n - width + i] * (1.0 - w)
	out.resize(n - width)


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples.size()
	return wav
