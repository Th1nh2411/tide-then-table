"""Rebuild the clean 128px portrait reference directory from approved sheets."""
from pathlib import Path
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "build/portraits/ref"
SOURCES = {
    "rin": ROOT / "assets/sprites/portraits/rin",
    "bao": ROOT / "assets/sprites/portraits/bao",
    "vy": ROOT / "assets/sprites/portraits/vy",
}
MOODS = {
    "rin": ["base", "base_open", "vui", "vui_open", "lo", "lo_open",
            "ngac_nhien", "ngac_nhien_open", "buon", "buon_open", "boi_roi", "boi_roi_open"],
    "bao": ["base", "base_open", "vui", "vui_open", "lo", "lo_open",
            "ngac_nhien", "ngac_nhien_open", "buon", "buon_open", "boi_roi", "boi_roi_open"],
    "vy": ["base", "base_open", "vui", "vui_open", "lo", "lo_open",
           "ngac_nhien", "ngac_nhien_open", "buon", "buon_open", "boi_roi", "boi_roi_open",
           "che", "che_open", "kieu", "kieu_open"],
}


def main() -> None:
    # The user requested a clean ref directory. Keep the directory itself.
    for child in REF.iterdir():
        if child.name == ".gitkeep":
            continue
        if child.is_dir():
            shutil.rmtree(child)
        else:
            child.unlink()
    for character, source in SOURCES.items():
        cols = 4 if character == "vy" else 3
        out = REF / character
        out.mkdir(parents=True)
        for i, name in enumerate(MOODS[character]):
            tile = Image.open(source / f"{name}.png").convert("RGBA")
            assert tile.size == (512, 512), (character, name, tile.size)
            # Nearest keeps the 128px drawing grid explicit for hand-pixel reference work.
            tile.resize((128, 128), Image.Resampling.NEAREST).save(out / f"{name}.png")
        (out / "README.txt").write_text(
            "128x128 nearest-neighbour reference frames; row-major order from the source sheet.\n"
            "These are drawing references, not runtime assets.\n"
        )
    print("created", sum(len(v) for v in MOODS.values()), "reference frames")


if __name__ == "__main__":
    main()
