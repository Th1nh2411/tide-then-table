class_name SfxEnvRecipes
extends RefCounted
## Environment sounds of the village map (house, lane, waterfront, street),
## SfxSynth segments like SfxRecipes. Sfx builds them on first use; the
## HorrorBed mixes "house" / "lane" / "waterfront" layer the LOOPS.

## Footsteps: name -> variations (Sfx.step("wood") picks one).
const STEPS := {
	"wood": ["step_wood_1", "step_wood_2", "step_wood_3"],
	"sand": ["step_sand_1", "step_sand_2", "step_sand_3"],
	"dirt": ["step_dirt_1", "step_dirt_2", "step_dirt_3"],
}

const SOUNDS := {
	# Wooden door: latch click, then a slow creak rising (stick-slip buzz).
	"door_open": [{"w": "tri", "f": [1300, 900], "d": 0.03, "v": 0.12},
		{"at": 0.05, "w": "square", "f": [42, 78], "d": 0.95, "v": 0.16, "lp": 0.22, "hp": 0.02, "a": 0.15, "am": [7.0, 0.5]},
		{"at": 0.1, "w": "tri", "f": [330, 520], "d": 0.8, "v": 0.035, "lp": 0.3, "a": 0.2, "am": [11.0, 0.6]}],
	# Door shut: a dull thud on the frame, the latch catching, a small rattle.
	"door_close": [{"w": "sine", "f": [100, 52], "d": 0.28, "v": 0.5}, {"at": 0.0, "w": "noise", "lp": 0.15, "d": 0.12, "v": 0.22},
		{"at": 0.07, "w": "tri", "f": [1500, 1000], "d": 0.03, "v": 0.1},
		{"at": 0.1, "w": "crackle", "rate": 120.0, "d": 0.15, "v": 0.12, "lp": 0.4}],
	# Footsteps on planks: a hollow knock over a soft thump.
	"step_wood_1": [{"w": "sine", "f": [150, 90], "d": 0.08, "v": 0.3}, {"at": 0.0, "w": "noise", "lp": 0.3, "d": 0.05, "v": 0.1},
		{"at": 0.0, "w": "tri", "f": [430, 390], "d": 0.045, "v": 0.05}],
	"step_wood_2": [{"w": "sine", "f": [135, 85], "d": 0.09, "v": 0.28}, {"at": 0.0, "w": "noise", "lp": 0.25, "d": 0.06, "v": 0.1},
		{"at": 0.005, "w": "tri", "f": [380, 350], "d": 0.05, "v": 0.05}],
	"step_wood_3": [{"w": "sine", "f": [160, 95], "d": 0.07, "v": 0.3}, {"at": 0.0, "w": "noise", "lp": 0.35, "d": 0.05, "v": 0.1},
		{"at": 0.0, "w": "tri", "f": [470, 440], "d": 0.04, "v": 0.045}, {"at": 0.06, "w": "square", "f": [60, 50], "d": 0.12, "v": 0.03, "lp": 0.15}],
	# Sand: a soft hissing crunch, grains ticking.
	"step_sand_1": [{"w": "noise", "lp": 0.5, "hp": 0.2, "d": 0.15, "v": 0.14, "a": 0.03},
		{"at": 0.0, "w": "crackle", "rate": 420.0, "d": 0.13, "v": 0.18, "lp": 0.6, "a": 0.02}],
	"step_sand_2": [{"w": "noise", "lp": 0.45, "hp": 0.2, "d": 0.17, "v": 0.13, "a": 0.04},
		{"at": 0.01, "w": "crackle", "rate": 360.0, "d": 0.14, "v": 0.17, "lp": 0.55, "a": 0.03}],
	"step_sand_3": [{"w": "noise", "lp": 0.55, "hp": 0.25, "d": 0.13, "v": 0.14, "a": 0.025},
		{"at": 0.0, "w": "crackle", "rate": 480.0, "d": 0.12, "v": 0.18, "lp": 0.65, "a": 0.02}],
	# Packed dirt: a dull thump, a few pebbles.
	"step_dirt_1": [{"w": "sine", "f": [95, 60], "d": 0.07, "v": 0.3}, {"at": 0.0, "w": "noise", "lp": 0.2, "d": 0.08, "v": 0.18},
		{"at": 0.0, "w": "crackle", "rate": 150.0, "d": 0.07, "v": 0.14, "lp": 0.7}],
	"step_dirt_2": [{"w": "sine", "f": [85, 55], "d": 0.08, "v": 0.28}, {"at": 0.0, "w": "noise", "lp": 0.18, "d": 0.09, "v": 0.17},
		{"at": 0.01, "w": "crackle", "rate": 110.0, "d": 0.08, "v": 0.13, "lp": 0.65}],
	"step_dirt_3": [{"w": "sine", "f": [105, 65], "d": 0.06, "v": 0.3}, {"at": 0.0, "w": "noise", "lp": 0.22, "d": 0.07, "v": 0.18},
		{"at": 0.0, "w": "crackle", "rate": 190.0, "d": 0.06, "v": 0.15, "lp": 0.75}],
	# A motorbike passing far off: engine putter coming closer, then the pitch
	# drops as it goes away (doppler), muffled by distance.
	"moto_pass": [{"w": "tri", "f": [158, 150], "d": 1.9, "v": 0.14, "lp": 0.12, "a": 1.6, "fade": false, "am": [26.0, 0.35]},
		{"at": 0.0, "w": "noise", "lp": 0.08, "d": 1.9, "v": 0.08, "a": 1.6, "fade": false},
		{"at": 1.75, "w": "tri", "f": [122, 104], "d": 2.4, "v": 0.14, "lp": 0.1, "a": 0.15, "am": [22.0, 0.35]},
		{"at": 1.75, "w": "noise", "lp": 0.07, "d": 2.4, "v": 0.08, "a": 0.15}],
	# A dog barking far away: two short muffled barks, then one more.
	"dog_far": [{"w": "tri", "f": [640, 380], "d": 0.13, "v": 0.14, "lp": 0.14}, {"at": 0.0, "w": "noise", "lp": 0.25, "d": 0.1, "v": 0.04},
		{"at": 0.32, "w": "tri", "f": [600, 360], "d": 0.15, "v": 0.13, "lp": 0.14}, {"at": 0.32, "w": "noise", "lp": 0.25, "d": 0.11, "v": 0.04},
		{"at": 1.05, "w": "tri", "f": [620, 350], "d": 0.17, "v": 0.1, "lp": 0.12}],
	# A rooster at dawn, a few gardens away: "ò ó o o" with a rasp.
	"rooster": [{"w": "tri", "f": [480, 690], "d": 0.2, "v": 0.1, "lp": 0.3, "am": [32.0, 0.3], "fade": false},
		{"w": "tri", "f": [690, 760], "d": 0.38, "v": 0.11, "lp": 0.3, "am": [32.0, 0.3], "fade": false},
		{"w": "tri", "f": [760, 700], "d": 0.3, "v": 0.1, "lp": 0.28, "am": [30.0, 0.35], "fade": false},
		{"w": "tri", "f": [700, 430], "d": 0.6, "v": 0.1, "lp": 0.25, "am": [28.0, 0.4]},
		{"at": 0.0, "w": "noise", "lp": 0.4, "hp": 0.2, "d": 1.4, "v": 0.02, "a": 0.1}],
	# Wind chime: a few thin bells knocking together, ringing out.
	"wind_chime": [{"w": "sine", "f": [1568, 1566], "d": 1.8, "v": 0.08}, {"at": 0.0, "w": "sine", "f": [4320, 4310], "d": 0.5, "v": 0.015},
		{"at": 0.18, "w": "sine", "f": [2093, 2090], "d": 1.6, "v": 0.07}, {"at": 0.18, "w": "sine", "f": [5770, 5760], "d": 0.4, "v": 0.012},
		{"at": 0.41, "w": "sine", "f": [1865, 1862], "d": 1.7, "v": 0.06},
		{"at": 0.7, "w": "sine", "f": [2794, 2790], "d": 1.4, "v": 0.05},
		{"at": 1.05, "w": "sine", "f": [2349, 2346], "d": 1.5, "v": 0.04}],
	# The small bell at the pier head (DockBell3D): a soft knock, a low bell
	# with inharmonic partials, ringing out slowly.
	"dock_bell": [{"w": "tri", "f": [900, 700], "d": 0.02, "v": 0.05},
		{"at": 0.0, "w": "sine", "f": [740, 739], "d": 2.6, "v": 0.11}, {"at": 0.0, "w": "sine", "f": [1776, 1772], "d": 1.4, "v": 0.035},
		{"at": 0.0, "w": "sine", "f": [2420, 2414], "d": 0.7, "v": 0.015}, {"at": 0.0, "w": "sine", "f": [372, 371], "d": 2.2, "v": 0.03, "a": 0.05}],
	# Bamboo stems rubbing in the wind, then a hollow clack.
	"bamboo_creak": [{"w": "square", "f": [58, 40], "d": 0.75, "v": 0.14, "lp": 0.18, "a": 0.18, "am": [6.0, 0.6]},
		{"at": 0.05, "w": "tri", "f": [220, 190], "d": 0.6, "v": 0.035, "lp": 0.25, "a": 0.15},
		{"at": 0.78, "w": "tri", "f": [610, 520], "d": 0.05, "v": 0.09}, {"at": 0.9, "w": "tri", "f": [560, 500], "d": 0.04, "v": 0.05}],
	# Jump scares (UncannyDirector): no screams, only the body of the sound.
	# Something heavy and wet hits the thúng (the fake scare's fish).
	"hull_thump": [{"w": "sine", "f": [95, 38], "d": 0.32, "v": 0.6}, {"at": 0.0, "w": "noise", "lp": 0.12, "d": 0.16, "v": 0.3},
		{"at": 0.02, "w": "noise", "lp": 0.4, "d": 0.3, "v": 0.12, "a": 0.02}],
	# A fish thrashing on wet bamboo: quick slaps, slowing down.
	"fish_thrash": [{"w": "noise", "lp": 0.55, "d": 0.05, "v": 0.26}, {"at": 0.13, "w": "noise", "lp": 0.5, "d": 0.05, "v": 0.22},
		{"at": 0.24, "w": "noise", "lp": 0.55, "d": 0.04, "v": 0.2}, {"at": 0.4, "w": "noise", "lp": 0.45, "d": 0.05, "v": 0.15},
		{"at": 0.62, "w": "noise", "lp": 0.4, "d": 0.05, "v": 0.1}, {"at": 0.95, "w": "noise", "lp": 0.35, "d": 0.05, "v": 0.06}],
	# A slow breath out right by the ear (ông Tư behind Rin).
	"breath_close": [{"w": "noise", "lp": 0.22, "hp": 0.02, "d": 1.3, "v": 0.2, "a": 0.4, "swell": 0.5},
		{"at": 0.1, "w": "noise", "lp": 0.6, "hp": 0.3, "d": 0.9, "v": 0.04, "a": 0.3}],
	# Water dripping off someone standing still.
	"drip": [{"w": "sine", "f": [1300, 2100], "d": 0.04, "v": 0.12}, {"at": 0.35, "w": "sine", "f": [1150, 1900], "d": 0.04, "v": 0.09},
		{"at": 0.9, "w": "sine", "f": [1400, 2300], "d": 0.04, "v": 0.08}],
	# The wrong night's last frame: a dull, close, muffled thud.
	"dead_thud": [{"w": "sine", "f": [70, 30], "d": 0.45, "v": 0.7}, {"at": 0.0, "w": "noise", "lp": 0.06, "d": 0.3, "v": 0.25}],
}

const LOOPS := {
	# Rain on a tin roof: hiss, pings on the sheet, fat drops, gutter drips.
	"rain_roof": [{"w": "noise", "lp": 0.5, "hp": 0.15, "d": 5.0, "v": 0.07, "a": 0.0, "swell": 2.5},
		{"at": 0.0, "w": "crackle", "f": [2400, 5200], "rate": 80.0, "ring": 0.006, "d": 5.0, "v": 0.09},
		{"at": 0.0, "w": "crackle", "rate": 45.0, "ring": 0.003, "d": 5.0, "v": 0.14, "lp": 0.45},
		{"at": 0.0, "w": "noise", "lp": 0.04, "d": 5.0, "v": 0.05, "a": 0.0, "swell": 5.0},
		{"at": 0.6, "w": "sine", "f": [750, 1350], "d": 0.06, "v": 0.12, "fade": true},
		{"at": 1.9, "w": "sine", "f": [700, 1250], "d": 0.06, "v": 0.1, "fade": true},
		{"at": 2.75, "w": "sine", "f": [780, 1400], "d": 0.05, "v": 0.11, "fade": true},
		{"at": 4.1, "w": "sine", "f": [720, 1300], "d": 0.06, "v": 0.1, "fade": true}],
	# Cicadas and crickets at dusk: buzzing trills, a chirp underneath.
	"insects": [{"w": "sine", "f": [4700, 4700], "d": 6.0, "v": 0.04, "a": 0.0, "swell": 3.0, "am": [42.0, 0.95]},
		{"at": 0.0, "w": "sine", "f": [5300, 5300], "d": 6.0, "v": 0.03, "a": 0.0, "swell": 2.0, "am": [37.0, 0.9]},
		{"at": 0.0, "w": "sine", "f": [3900, 3900], "d": 6.0, "v": 0.035, "a": 0.0, "am": [5.5, 1.0]},
		{"at": 0.0, "w": "noise", "lp": 0.9, "hp": 0.5, "d": 6.0, "v": 0.01, "a": 0.0, "swell": 6.0}],
	# Wind in palm fronds and bamboo: low gusts, leaf rustle, a stem knocking.
	"wind_palms": [{"w": "noise", "lp": 0.05, "d": 8.0, "v": 0.2, "a": 0.0, "swell": 8.0},
		{"at": 0.0, "w": "noise", "lp": 0.55, "hp": 0.25, "d": 8.0, "v": 0.06, "a": 0.0, "swell": 4.0},
		{"at": 0.0, "w": "noise", "lp": 0.85, "hp": 0.5, "d": 8.0, "v": 0.03, "a": 0.0, "swell": 2.667},
		{"at": 2.3, "w": "tri", "f": [520, 470], "d": 0.05, "v": 0.05, "fade": true},
		{"at": 2.55, "w": "tri", "f": [480, 440], "d": 0.04, "v": 0.035, "fade": true},
		{"at": 4.2, "w": "square", "f": [52, 40], "d": 0.6, "v": 0.06, "lp": 0.15, "a": 0.15, "am": [6.0, 0.6], "fade": true},
		{"at": 6.1, "w": "tri", "f": [500, 460], "d": 0.05, "v": 0.04, "fade": true}],
	# Sea lapping against a wooden pier: slow swell, small slaps on the
	# pilings, a hollow knock under the planks, a drip.
	"pier_lap": [{"w": "noise", "lp": 0.03, "d": 6.0, "v": 0.22, "a": 0.0, "swell": 3.0},
		{"at": 0.4, "w": "noise", "lp": 0.25, "d": 0.5, "v": 0.1, "a": 0.12, "fade": true},
		{"at": 0.45, "w": "sine", "f": [110, 70], "d": 0.25, "v": 0.12, "fade": true},
		{"at": 1.9, "w": "noise", "lp": 0.3, "d": 0.4, "v": 0.08, "a": 0.1, "fade": true},
		{"at": 3.3, "w": "noise", "lp": 0.22, "d": 0.55, "v": 0.11, "a": 0.15, "fade": true},
		{"at": 3.35, "w": "sine", "f": [100, 65], "d": 0.3, "v": 0.13, "fade": true},
		{"at": 4.9, "w": "noise", "lp": 0.3, "d": 0.4, "v": 0.08, "a": 0.1, "fade": true},
		{"at": 2.6, "w": "sine", "f": [900, 1500], "d": 0.05, "v": 0.06, "fade": true}],
	# Village at night, far off: still air, a radio playing an old tune two
	# houses down, a dog barking once in a while.
	"village_night": [{"w": "noise", "lp": 0.02, "d": 12.0, "v": 0.06, "a": 0.0, "swell": 6.0},
		{"at": 0.0, "w": "noise", "lp": 0.8, "hp": 0.4, "d": 5.6, "v": 0.006, "a": 0.4, "fade": true},
		{"at": 0.5, "w": "tri", "f": [392, 392], "d": 0.5, "v": 0.025, "lp": 0.08, "fade": true},
		{"at": 1.0, "w": "tri", "f": [440, 440], "d": 0.5, "v": 0.025, "lp": 0.08, "fade": true},
		{"at": 1.5, "w": "tri", "f": [523, 523], "d": 0.9, "v": 0.025, "lp": 0.08, "fade": true},
		{"at": 2.5, "w": "tri", "f": [440, 440], "d": 0.5, "v": 0.022, "lp": 0.08, "fade": true},
		{"at": 3.0, "w": "tri", "f": [392, 392], "d": 0.5, "v": 0.022, "lp": 0.08, "fade": true},
		{"at": 3.5, "w": "tri", "f": [330, 330], "d": 1.2, "v": 0.02, "lp": 0.08, "fade": true},
		{"at": 7.2, "w": "tri", "f": [600, 360], "d": 0.13, "v": 0.06, "lp": 0.08, "fade": true},
		{"at": 7.5, "w": "tri", "f": [580, 350], "d": 0.15, "v": 0.05, "lp": 0.08, "fade": true}],
}
