#!/bin/bash
# Plays the whole game headless (tools/bot/game_bot.gd) and prints one line
# per day + the run summary. Never touches the real save (--no-autosave).
#   tools/run_bot.sh            # upgrade order "story" (boat first)
#   POLICY=balanced tools/run_bot.sh
# Exit code != 0 when the run gets stuck, a save doesn't round-trip, or
# there are script errors.
cd "$(dirname "$0")/.." || exit 1
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
out=$("$GODOT" --headless --path . --fixed-fps 60 --quit-after 400000 res://tools/bot/game_bot_launch.tscn -- --no-autosave 2>&1)
echo "$out" | grep -E "^(DAY|SEA|RUN|STUCK|SAVE MISMATCH|  before|  after)|SCRIPT ERROR|ERROR:"
if echo "$out" | grep -qE "STUCK|SAVE MISMATCH|SCRIPT ERROR|^RUN NO ENDING" || ! echo "$out" | grep -q "^RUN ENDING"; then
	echo "BOT FAIL"
	exit 1
fi
echo "BOT OK"
