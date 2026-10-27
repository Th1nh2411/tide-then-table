#!/usr/bin/env python3
"""Check documented masters; leave existing approved portraits untouched.

  python3 tools/check_assets.py                     # grill + sea, required
  python3 tools/check_assets.py --group fish --group dishes
  python3 tools/check_assets.py --group characters --group cutscenes --group portraits
  python3 tools/check_assets.py --inventory         # also list fallback art

Requires Pillow, like tools/pixelize.py. Checks technical acceptance only:
orientation, silhouette, framing and native-scale appearance need visual review.
Dimensions follow ASSETS.md master sizes (inventory cell = 80px).
"""

import argparse
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Needs Pillow: python3 -m pip install Pillow")

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets/sprites"
FISH = {
    "oc_huong": (80, 80), "tom": (160, 80), "muc": (160, 80),
    "ca_thu": (240, 80), "ca_thu_phat_sang": (240, 80),
    "cua": (160, 160), "ca_mu": (240, 160),
}
GRILL = {name: (60, 32) for name in ("ca_thu", "tom", "muc", "oc_huong")}
SEA = {
    "thuyen_thung": (32, 32), "ghe_cheo": (48, 20),
    "ghe_may": (60, 24), "rin_boat": (16, 32),
}
CHARACTERS = {"co_nam": (64, 128), "co_nam_idle": (64, 96), "staff": (64, 128)}
for variant in ("guest_rich", "guest_regular"):
    CHARACTERS[variant] = (64, 128)
    for pose in ("wait", "eat"):
        CHARACTERS[f"{variant}_{pose}"] = (64, 32)
CUTSCENES = {"crate": (20, 14), "rin_bed": (32, 16), "rin_faint": (32, 10), "glow": (320, 80)}
SIDE_PORTRAITS = {"ong_tam/base": (128, 128), "khach_quen/base": (128, 128)}
# These are allowed to keep their code/character fallback in the current MVP.
FALLBACK_ART = {
    "characters/co_nam": "main character sheet; currently code fallback",
    "characters/guest_rich": "optional guest variant; uses guest sheet",
    "characters/guest_regular": "optional guest variant; uses guest sheet",
    "characters/staff": "generic hired helper; individual sheets may override",
    "characters/crate": "cutscene prop; code fallback",
    "characters/rin_bed": "intro pose; code fallback",
    "characters/glow": "omen animation; code fallback",
    "portraits/ong_tam/base": "optional portrait; code fallback",
    "portraits/khach_quen/base": "optional portrait; code fallback",
}


def resource_ids(folder):
    """Use actual data IDs so additions to the dish catalog need an image."""
    ids = []
    for path in sorted((ROOT / "data" / folder).glob("*.tres")):
        match = re.search(r'^id = "([^"]+)"', path.read_text(), re.MULTILINE)
        if match:
            ids.append(match[1])
    return ids


def palette():
    return {
        tuple(bytes.fromhex(line.strip().lstrip("#")))
        for line in (ROOT / "assets/palette/xom_den.hex").read_text().splitlines()
        if re.fullmatch(r"#?[0-9a-fA-F]{6}", line.strip())
    }


def check_image(path, expected, allowed, limit, strict_palette=False, allow_partial_alpha=False):
    issues = []
    try:
        with Image.open(path) as source:
            if source.format != "PNG":
                issues.append("must be a PNG")
            image = source.convert("RGBA")
    except (OSError, ValueError) as error:
        return [str(error)]
    if image.size != expected:
        issues.append(f"size {image.size}, expected {expected}")
    w, h = image.size
    if any(image.getpixel(p)[3] != 0 for p in ((0, 0), (w-1, 0), (0, h-1), (w-1, h-1))):
        issues.append("all four corners must be transparent")
    pixels = set(image.getdata())
    if not allow_partial_alpha and any(0 < a < 255 for _, _, _, a in pixels):
        issues.append("partial alpha / halo")
    colors = {(r, g, b) for r, g, b, a in pixels if a > 0}
    if not colors:
        issues.append("empty transparent image")
    if limit and len(colors) > limit:
        issues.append(f"{len(colors)} colors, maximum {limit}")
    outside = colors - allowed
    if outside and strict_palette:
        issues.append(f"{len(outside)} colors outside Xóm Đèn palette")
    return issues


def palette_warning(path, allowed):
    try:
        with Image.open(path) as source:
            colors = {(r, g, b) for r, g, b, a in source.convert("RGBA").getdata() if a > 0}
        return len(colors - allowed)
    except (OSError, ValueError):
        return 0  # Decoding failure is already reported by check_image.


def check_consumers():
    """Guard filename hooks that connect these masters to runtime renderers."""
    hooks = {
        "scenes/restaurant/cooking/grill_view.gd": ['"grill/" + fish_id'],
        "scenes/sea/boat.gd": ['"sea/" + boat_data.id', '"sea/rin_boat"'],
    }
    issues = []
    for name, needles in hooks.items():
        source = (ROOT / name).read_text()
        for needle in needles:
            if needle not in source:
                issues.append(f"runtime hook missing: {name}: {needle}")
    boat_ids = set(resource_ids("boats"))
    if boat_ids != set(SEA) - {"rin_boat"}:
        issues.append(f"boat data IDs differ from sea art names: {sorted(boat_ids)}")
    return issues


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--group", action="append", choices=("fish", "dishes", "grill", "sea", "characters", "cutscenes", "portraits"),
                        help="portraits checks only the two new secondary bases, leaving approved portraits untouched")
    parser.add_argument("--inventory", action="store_true", help="list other documented missing fallback art")
    parser.add_argument("--strict-palette", action="store_true", help="fail on off-palette colors (legacy masters warn by default)")
    args = parser.parse_args()
    groups = args.group or ["grill", "sea"]
    specs = {"fish": FISH, "grill": GRILL, "sea": SEA, "characters": CHARACTERS,
             "cutscenes": CUTSCENES, "portraits": SIDE_PORTRAITS,
             "dishes": {name: (64, 64) for name in resource_ids("dishes")}}
    allowed = palette()
    failures, checked = 0, 0
    for group in dict.fromkeys(groups):
        for name, size in specs[group].items():
            folder = "characters" if group == "cutscenes" else group
            path = SPRITES / folder / (name + ".png")
            # Sea has no documented per-image cap; Rin is a character (10).
            limits = {"fish": 6, "dishes": 6, "grill": 6, "characters": 10, "portraits": 16}
            limit = 10 if name == "rin_boat" else limits.get(group)
            strict_palette = args.strict_palette or group in ("grill", "sea", "characters", "cutscenes", "portraits")
            if path.exists():
                issues = check_image(path, size, allowed, limit, strict_palette,
                                     allow_partial_alpha=(group == "cutscenes" and name == "glow"))
            else:
                issues = ["missing required master"]
            checked += 1
            failures += bool(issues)
            print(f"{'FAIL' if issues else 'PASS'} {folder}/{name}.png" +
                  (": " + "; ".join(issues) if issues else ""))
            outside = palette_warning(path, allowed) if path.exists() else 0
            if outside and not strict_palette:
                print(f"WARN {group}/{name}.png: {outside} off-palette colors (use --strict-palette)")
    if "sea" in groups or "grill" in groups:
        for issue in check_consumers():
            failures += 1
            print("FAIL " + issue)
    if args.inventory:
        for name, note in FALLBACK_ART.items():
            if not (SPRITES / (name + ".png")).exists():
                print(f"FALLBACK {name}.png: {note}")
    print(f"{checked} masters checked; {failures} failures. Existing approved portraits untouched; visual review still required.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
