#!/usr/bin/env bash
# Runs every standalone test scene (scenes/test/*_test.tscn) headless, then
# smoke-runs the main scenes, and reports PASS/FAIL/script errors.
# Exit code is non-zero if anything failed, so it can gate commits/CI.
#
# Usage: tools/run_tests.sh            (Godot path from $GODOT, else macOS default)
set -u

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.."

if [ ! -x "$GODOT" ]; then
	echo "Godot not found at $GODOT (set GODOT=/path/to/godot)" >&2
	exit 2
fi

# Register new class_name scripts / resources first. The editor sometimes
# crashes while shutting down after --import; that's harmless, so ignore it.
"$GODOT" --headless --path . --import >/dev/null 2>&1

status=0
run_scene() {
	local scene="$1"
	# `-- --no-autosave`: the sea scene must not overwrite the player's save.
	local out
	local exit_code=0
	out=$("$GODOT" --headless --path . --fixed-fps 60 --quit-after 120 "res://$scene" -- --no-autosave 2>&1)
	exit_code=$?
	local pass fail err
	pass=$(grep -c '^PASS' <<<"$out")
	fail=$(grep -c '^FAIL' <<<"$out")
	err=$(grep -cE 'SCRIPT ERROR|^ERROR' <<<"$out")
	printf '%-45s %3d pass  %d fail  %d errors\n' "$scene" "$pass" "$fail" "$err"
	if [ "$fail" -gt 0 ] || [ "$err" -gt 0 ] || [ "$exit_code" -ne 0 ]; then
		status=1
		if [ "$exit_code" -ne 0 ]; then
			printf '    Godot exited with status %d\n' "$exit_code"
		fi
		grep -E '^FAIL|SCRIPT ERROR|^ERROR' -A2 <<<"$out" | sed 's/^/    /'
	fi
}

echo "== Test scenes"
for scene in scenes/test/*_test.tscn scenes/test/*3d*smoke.tscn; do
	run_scene "$scene"
done

echo "== Smoke runs"
for scene in scenes/main_menu/main_menu.tscn scenes/village3d/village_scene_3d.tscn scenes/ending/ending_scene.tscn \
		scenes/sea3d/*smoke.tscn scenes/restaurant3d/*smoke.tscn scenes/restaurant3d/*check.tscn; do
	[ -e "$scene" ] || continue  # a glob with no match stays literal
	run_scene "$scene"
done

if [ "$status" -eq 0 ]; then echo "ALL OK"; else echo "FAILURES"; fi
exit "$status"
