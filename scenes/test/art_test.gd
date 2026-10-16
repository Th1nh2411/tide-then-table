extends Node
## Standalone test for Art (run with F6): missing art falls back, a PNG
## dropped into the folder is found (also without import), person sheet
## frames (row per direction, mirrored right, busy row, walk cycle).

const TEST_ROOT := "user://art_test/"


func _ready() -> void:
	var failures := 0
	var old_root := Art.root
	DirAccess.make_dir_recursive_absolute(TEST_ROOT + "characters")
	var image := Image.create(64, 128, false, Image.FORMAT_RGBA8)  # 4 cols x 4 rows of 16x32
	image.fill(Color.RED)
	image.save_png(TEST_ROOT + "characters/tester.png")
	Art.root = TEST_ROOT
	Art.clear_cache()
	var canvas := Node2D.new()
	failures += _check("missing art -> false", not Art.has("characters/nobody")
		and not Art.draw(canvas, "characters/nobody", Rect2(0, 0, 16, 16)))
	canvas.free()
	failures += _check("png found without import", Art.has("characters/tester"))
	var size := Vector2(64, 128)
	var down := Art.person_frame(size, Vector2i.DOWN, false, false, 0.0, 0.0)
	failures += _check("4 rows from a 64x128 sheet, standing = column 0", down["rows"] == 4
		and down["row"] == Art.ROW_DOWN and down["column"] == 0)
	failures += _check("up row", Art.person_frame(size, Vector2i.UP, false, false, 0.0, 0.0)["row"] == Art.ROW_UP)
	var right := Art.person_frame(size, Vector2i.RIGHT, true, false, 0.3, 0.0)
	failures += _check("right = left row mirrored, walk ping-pongs 1-2-3-2", right["row"] == Art.ROW_LEFT
		and right["flip"] and right["column"] == 3
		and Art.person_frame(size, Vector2i.DOWN, true, false, 0.4, 0.0)["column"] == 2
		and Art.person_frame(size, Vector2i.DOWN, true, false, 0.0, 0.0)["column"] == 1)
	failures += _check("busy row when the sheet has it",
		Art.person_frame(size, Vector2i.DOWN, false, true, 0.0, 0.0)["row"] == Art.ROW_BUSY)
	var small := Art.person_frame(Vector2(64, 96), Vector2i.DOWN, false, true, 0.0, 0.0)
	failures += _check("3-row sheet: busy falls back to facing", small["rows"] == 3 and small["row"] == Art.ROW_DOWN)
	failures += _check("2x art (128x256) has the same layout",
		Art.person_frame(Vector2(128, 256), Vector2i.LEFT, false, false, 0.0, 0.0)["rows"] == 4)
	failures += _check("diagonal keeps a matching facing",
		StreetPerson.facing_for(Vector2(1, 1), Vector2i.DOWN) == Vector2i.DOWN
		and StreetPerson.facing_for(Vector2(1, -1), Vector2i.RIGHT) == Vector2i.RIGHT)
	failures += _check("diagonal from an unrelated facing turns sideways",
		StreetPerson.facing_for(Vector2(-1, -1), Vector2i.DOWN) == Vector2i.LEFT)
	failures += _check("straight moves use the main axis",
		StreetPerson.facing_for(Vector2(0.2, 1), Vector2i.LEFT) == Vector2i.DOWN
		and StreetPerson.facing_for(Vector2.ZERO, Vector2i.UP) == Vector2i.UP)
	var half := Art.IDLE_BREATH * 0.5
	failures += _check("idle breathes: standing, then breathing in, eyes shut at each blink",
		Art.idle_column(Art.IDLE_BLINK_LENGTH + 0.01) == 0 and Art.idle_column(half + 0.05) == 1
		and Art.idle_column(Art.IDLE_BLINK * 2.0 + 0.01) in [2, 3])
	DirAccess.remove_absolute(TEST_ROOT + "characters/tester.png")
	Art.root = old_root
	Art.clear_cache()
	print("art_test: %s" % ("ALL PASS" if failures == 0 else "%d FAIL" % failures))
	get_tree().quit()


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
