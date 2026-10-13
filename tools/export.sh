#!/bin/bash
# Builds the playtest versions into build/ (git-ignored):
#   build/mac/RinTheFisher.zip      (macOS universal, ad-hoc signed)
#   build/windows/RinTheFisher.exe  (Windows x86_64, one file)
# Runs the tests first; stops if they fail. Needs the export templates for
# this exact Godot version (Editor > Manage Export Templates > Download).
#   tools/export.sh            # both
#   tools/export.sh macOS      # one preset (names in export_presets.cfg)
cd "$(dirname "$0")/.." || exit 1
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
version=$("$GODOT" --version | sed -E 's/^([0-9.]+\.[a-z]+).*/\1/')
templates="$HOME/Library/Application Support/Godot/export_templates/$version"
if [ ! -d "$templates" ]; then
	echo "Missing export templates for Godot $version:"
	echo "  $templates"
	echo "Open the editor > Editor > Manage Export Templates > Download and Install."
	exit 1
fi
tools/run_tests.sh > /dev/null || { echo "Tests failed, not exporting (run tools/run_tests.sh)"; exit 1; }
presets=("$@")
[ ${#presets[@]} -eq 0 ] && presets=("macOS" "Windows")
status=0
for preset in "${presets[@]}"; do
	path=$(awk -v name="$preset" '/^name=/{n=($0=="name=\"" name "\"")} n && /^export_path=/{gsub(/export_path=|"/,""); print; exit}' export_presets.cfg)
	mkdir -p "$(dirname "$path")"
	if "$GODOT" --headless --path . --export-release "$preset" "$path" > build/export_"$preset".log 2>&1 && [ -e "$path" ]; then
		echo "OK   $preset -> $path"
	else
		echo "FAIL $preset (see build/export_$preset.log)"
		status=1
	fi
done
exit $status
