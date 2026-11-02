#!/usr/bin/env python3
"""Turns on humanoid retargeting in the .import files of assets/models/psx_chars.

Run after Godot created the default .import files (--import), then --import again.
Pack FBX (Mixamo rig) -> mixamo_bone_map.tres; clip_source.glb (batch rig) ->
batch_bone_map.tres. Bones are renamed to SkeletonProfileHumanoid names, the
skeleton becomes the unique node "GeneralSkeleton", limb rests are fixed to a
T-pose with profile axes, so one AnimationLibrary plays on every model. The
spine chain keeps the pack's natural lean (PsxCharacterVisual drops its tracks).
"""
import pathlib
import re

DIR = pathlib.Path(__file__).resolve().parents[2] / "assets/models/psx_chars"
OPTIONS = """{
"nodes": {
"PATH:%s": {
"retarget/bone_map": Resource("res://assets/models/psx_chars/%s"),
"retarget/bone_renamer/rename_bones": true,
"retarget/bone_renamer/unique_node/make_unique": true,
"retarget/bone_renamer/unique_node/skeleton_name": "GeneralSkeleton",
"retarget/rest_fixer/retarget_method": 1,
"retarget/rest_fixer/fix_silhouette/enable": true,
"retarget/rest_fixer/fix_silhouette/filter": [&"LeftFoot", &"RightFoot", &"LeftToes", &"RightToes", &"Spine", &"Chest", &"UpperChest", &"Neck", &"Head"],
"retarget/remove_tracks/unmapped_bones": true
}
}
}"""


def main() -> None:
    for path in sorted(DIR.glob("*.import")):
        if path.name.endswith(".fbx.import"):
            skeleton, bone_map = "Skeleton3D", "mixamo_bone_map.tres"
        elif path.name == "clip_source.glb.import":
            skeleton, bone_map = "Batch_baoSkin/Skeleton3D", "batch_bone_map.tres"
        else:
            continue
        text = path.read_text()
        start = text.index("_subresources=")
        # The block runs until the next "key/name=" line.
        match = re.compile(r"^[a-z_]+/", re.M).search(text, start + 1)
        end = match.start() - 1 if match else len(text)
        text = text[:start] + "_subresources=" + OPTIONS % (skeleton, bone_map) + text[end:]
        # ufbx importer (FBX2glTF is not installed).
        text = text.replace("fbx/importer=1", "fbx/importer=0")
        path.write_text(text)
        print("retarget on", path.name)


if __name__ == "__main__":
    main()
