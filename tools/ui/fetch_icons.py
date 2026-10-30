#!/usr/bin/env python3
"""Downloads the UI icon set from game-icons.net (CC BY 3.0) into assets/icons/.

Each SVG is a white glyph on a black square; the square is removed so the
glyph can be tinted in Godot (modulate). Run from the repo root:
    python3 tools/ui/fetch_icons.py
Keep ICONS in sync with UiIcons.IDS (scenes/ui/ui_icons.gd) and CREDITS.md.
"""
import os
import re
import urllib.request

BASE = "https://raw.githubusercontent.com/game-icons/icons/master/"
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "icons")

# id -> author/name on game-icons.net
ICONS = {
    "money": "delapouite/two-coins",
    "clock": "delapouite/alarm-clock",
    "star": "delapouite/round-star",
    "guest": "delapouite/person",
    "people": "delapouite/three-friends",
    "fire": "carl-olsen/flame",
    "beer": "lorc/beer-stein",
    "fish": "delapouite/double-fish",
    "shrimp": "delapouite/shrimp",
    "crab": "lorc/crab",
    "squid": "lorc/squid",
    "snail": "lorc/snail",
    "boat": "delapouite/fishing-boat",
    "lamp": "delapouite/old-lantern",
    "lantern": "delapouite/asian-lantern",
    "wrench": "sbed/wrench",
    "hammer": "lorc/hammer-nails",
    "cart": "delapouite/shopping-cart",
    "basket": "delapouite/basket",
    "shop": "delapouite/shop",
    "menu": "delapouite/checklist",
    "settings": "lorc/cog",
    "sound_on": "delapouite/speaker",
    "sound_off": "delapouite/speaker-off",
    "play": "guard13007/play-button",
    "pause": "guard13007/pause-button",
    "help": "lorc/open-book",
    "quit": "delapouite/exit-door",
    "save": "delapouite/save",
    "upgrade": "delapouite/upgrade",
    "hot": "delapouite/chili-pepper",
    "check": "delapouite/check-mark",
    "lock": "lorc/padlock",
    "trophy": "lorc/trophy",
    "chart": "delapouite/histogram",
    "phone": "delapouite/smartphone",
    "grill": "delapouite/barbecue",
    "pot": "delapouite/cooking-pot",
    "meal": "delapouite/hot-meal",
    "leaf": "delapouite/broccoli",
    "back": "lorc/return-arrow",
    "close": "sbed/cancel",
    "trash": "delapouite/trash-can",
    "house": "delapouite/house",
    "moon": "lorc/moon",
    "keyboard": "delapouite/keyboard",
    "mouse": "delapouite/mouse",
    "sparkles": "delapouite/sparkles",
    "wave": "lorc/wave-crest",
    "anchor": "lorc/anchor",
    "rod": "delapouite/fishing-pole",
    "calendar": "delapouite/calendar",
    "sleep": "delapouite/night-sleep",
    "info": "delapouite/info",
    "auto": "delapouite/perspective-dice-six-faces-random",
    "growth": "delapouite/growth",
}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for icon_id, path in ICONS.items():
        with urllib.request.urlopen(BASE + path + ".svg", timeout=30) as response:
            svg = response.read().decode("utf-8")
        svg = svg.replace('<path d="M0 0h512v512H0z"/>', "")
        svg = re.sub(r'fill="#fff"', 'fill="#ffffff"', svg)
        with open(os.path.join(OUT, icon_id + ".svg"), "w", encoding="utf-8") as out:
            out.write(svg)
        print(icon_id, "<-", path)


if __name__ == "__main__":
    main()
