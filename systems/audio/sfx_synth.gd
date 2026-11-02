class_name SfxSynth
extends RefCounted
## Builds placeholder sounds in code (no audio files): a sound is a list of
## segments, each a short tone or noise burst with a pitch sweep and a
## fade-out. Segments play one after another unless they set "at" (seconds
## from the start), which layers them. Pure logic, no nodes.
##
## Segment keys: "w" wave (sine / square / tri / noise / crackle), "f" [start,
## end] Hz (noise ignores it), "d" seconds, "v" volume 0..1, "lp" noise
## brightness 0..1 (low = rumble; on other waves a low-pass, only if set),
## "hp" high-pass 0..1 (cuts rumble), "a" attack seconds, "swell" seconds per
## volume wave (ambience), "am" [Hz, depth] tremolo (insects, rasp), "fade"
## true / false overrides the fade-out (loops don't fade by default), "at"
## start time.
## "crackle": random clicks, "rate" per second, each ringing "ring" seconds;
## with "f" each click is a ping at a random pitch in [start, end] (rain on
## tin), without it a noise tick (sand, gravel).

const RATE := 22050


static func build(segments: Array, loop: bool = false) -> AudioStreamWAV:
	return to_wav(render(segments, loop), loop)


## Raw samples (unclamped) of a recipe, for mixing (HorrorBed) and peak checks.
static func render(segments: Array, loop: bool = false) -> PackedFloat32Array:
	var total := 0.0
	var cursor := 0.0
	for seg: Dictionary in segments:
		var start: float = seg.get("at", cursor)
		var dur: float = seg.get("d", 0.1)
		cursor = start + dur
		total = maxf(total, cursor)
	var samples := PackedFloat32Array()
	samples.resize(ceili(total * RATE) + 1)
	cursor = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for seg: Dictionary in segments:
		var start: float = seg.get("at", cursor)
		var dur: float = seg.get("d", 0.1)
		cursor = start + dur
		_render(samples, seg, int(start * RATE), dur, loop, rng)
	if loop:
		_smooth_seam(samples, int(0.03 * RATE))
	return samples


static func _render(out: PackedFloat32Array, seg: Dictionary, offset: int, dur: float, loop: bool,
		rng: RandomNumberGenerator) -> void:
	var wave: String = seg.get("w", "sine")
	var freqs: Array = seg.get("f", [440, 440])
	var f0: float = float(freqs[0])
	var f1: float = float(freqs[1]) if freqs.size() > 1 else f0
	var volume: float = seg.get("v", 0.3)
	var lp: float = seg.get("lp", 1.0)
	var attack: float = seg.get("a", 0.005)
	var swell: float = seg.get("swell", 0.0)
	var fade: bool = seg.get("fade", not loop)
	var filter_lp := wave != "noise" and seg.has("lp")
	var hp: float = seg.get("hp", 0.0)
	var am: Array = seg.get("am", [])
	var am_hz: float = float(am[0]) if am.size() > 1 else 0.0
	var am_depth: float = float(am[1]) if am.size() > 1 else 0.0
	var rate: float = seg.get("rate", 40.0)
	var ring: float = seg.get("ring", 0.004)
	var pinged := seg.has("f")
	var count := int(dur * RATE)
	var phase := 0.0
	var smooth := 0.0
	var low := 0.0
	var imp := 0.0
	var ping_hz := f0
	var imp_decay := exp(-1.0 / maxf(ring * RATE, 1.0))
	for i in count:
		var t := float(i) / RATE
		var k := t / dur
		var freq := f0 * pow(f1 / f0, k) if f0 > 0.0 and f1 > 0.0 else f0
		var s := 0.0
		match wave:
			"square":
				phase = fmod(phase + freq / RATE, 1.0)
				s = 1.0 if phase < 0.5 else -1.0
			"tri":
				phase = fmod(phase + freq / RATE, 1.0)
				s = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				smooth += (rng.randf_range(-1.0, 1.0) - smooth) * lp
				s = smooth * (1.0 + (1.0 - lp) * 3.0)  # dark noise is quiet: lift it
			"crackle":
				imp *= imp_decay
				if rng.randf() < rate / RATE:
					imp = rng.randf_range(0.3, 1.0)
					ping_hz = rng.randf_range(f0, f1)
					phase = 0.0
				if pinged:
					phase = fmod(phase + ping_hz / RATE, 1.0)
					s = sin(phase * TAU) * imp
				else:
					s = rng.randf_range(-1.0, 1.0) * imp
			_:
				phase = fmod(phase + freq / RATE, 1.0)
				s = sin(phase * TAU)
		if filter_lp:
			smooth += (s - smooth) * lp
			s = smooth
		if hp > 0.0:
			low += (s - low) * hp
			s -= low
		var env := minf(t / maxf(attack, 0.0001), 1.0)
		if fade:
			env *= pow(1.0 - k, 1.5)
		if swell > 0.0:
			env *= 0.55 + 0.45 * sin(TAU * t / swell)
		if am_hz > 0.0:
			env *= 1.0 - am_depth * (0.5 + 0.5 * sin(TAU * am_hz * t))
		var at := offset + i
		if at < out.size():
			out[at] += s * env * volume


## Crossfades the end into the start so a loop doesn't click.
static func _smooth_seam(samples: PackedFloat32Array, width: int) -> void:
	var n := samples.size()
	width = mini(width, n / 4)
	for i in width:
		var w := float(i) / width
		samples[i] = samples[i] * w + samples[n - width + i] * (1.0 - w)
	samples.resize(n - width)


static func to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
