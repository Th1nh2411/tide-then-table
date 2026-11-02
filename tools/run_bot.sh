#!/bin/bash
# Runs the native 3D loop through its ending, with scratch saves only.
# Travel and minigame success are scripted: this checks integration, not balance.
# POLICY=balanced selects kitchen-first upgrades; default is boat-first.
cd "$(dirname "$0")/.." || exit 1
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
bot_scene="res://tools/bot/game_bot_3d.tscn"
out=$("$GODOT" --headless --path . --fixed-fps 60 --quit-after 400000 "$bot_scene" -- --no-autosave 2>&1)
exit_code=$?
echo "$out" | grep -E "^(DAY|SEA|HOME|LOOP|RUN|STUCK|SAVE MISMATCH|  before|  after)|SCRIPT ERROR|ERROR:"
if [ "$exit_code" -ne 0 ] || echo "$out" | grep -qE "STUCK|SAVE MISMATCH|SCRIPT ERROR|^ERROR|^RUN NO ENDING" || ! echo "$out" | grep -q "^RUN ENDING"; then
	echo "BOT FAIL"
	exit 1
fi
echo "BOT OK"
