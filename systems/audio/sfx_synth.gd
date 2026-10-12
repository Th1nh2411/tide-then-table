class_name SfxSynth
extends RefCounted
## Builds placeholder sounds in code (no audio files): a sound is a list of
## segments, each a short tone or noise burst with a pitch sweep and a
## fade-out. Segments play one after another unless they set "at" (seconds
## from the start), which layers them. Pure logic, no nodes.
##
## Segment keys: "w" wave (sine / square / tri / noise), "f" [start, end] Hz
## (noise ignores it), "d" seconds, "v" volume 0..1, "lp" noise brightness
## 0..1 (low = rumble), "a" attack seconds, "swell" seconds per volume wave
## (ambience), "at" start time.

const RATE := 22050


static func build(segments: Array, loop: bool = false) -> AudioStreamWAV:
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
	return _to_wav(samples, loop)


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
	var count := int(dur * RATE)
	var phase := 0.0
	var smooth := 0.0
	for i in count:
		var t := float(i) / RATE
		var k := t / dur
		var freq := f0 * pow(f1 / f0, k) if f0 > 0.0 and f1 > 0.0 else f0
		phase = fmod(phase + freq / RATE, 1.0)
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"tri":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				smooth += (rng.randf_range(-1.0, 1.0) - smooth) * lp
				s = smooth * (1.0 + (1.0 - lp) * 3.0)  # dark noise is quiet: lift it
			_:
				s = sin(phase * TAU)
		var env := minf(t / maxf(attack, 0.0001), 1.0)
		if not loop:
			env *= pow(1.0 - k, 1.5)
		if swell > 0.0:
			env *= 0.55 + 0.45 * sin(TAU * t / swell)
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


static func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
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
