# PSX character pack (NPCs)

- Source: "Characters_psx" pack, version 1.2, folder `Characters_psx_02`
  (`Models/Rig/{Male,Female}/*.fbx`, Mixamo rig, `Textures/*.png`).
- **License: unverified, check before release.** No license file came with the
  download; nothing from this folder may ship until the license is confirmed.
- Only the models used in the game are copied here (FBX + same-name PNG):

| File | Used as (variant id in `PsxCharacterVisual.CAST`) |
|---|---|
| Character_Male_46 | bao (Bảo) |
| Character_51_Female | co_nam (Cô Năm) |
| Character_Male_35 | guest_rich (anh Út) |
| Character_Male_49 | chu_hai, ong_tam (old fisherman) |
| Character_Male_45 | ong_tu (ông Tư's ghost) |
| Character_Male_34 | guest_1 |
| Character_29_Female | guest_2 |
| Character_12 | guest_3 (also the young fisherman of the bad ending) |
| Character_30_Female | guest_4, vy |
| Character_13 | guest_5, staff |
| Character_32_Female | guest_6 |
| Character_Male_50 | guest_7, guest_regular |
| Character_54_Female | guest_8, vy_sau |
| Character_Male_53 | guest_9 |
| Character_Male_57 | drowned_m (drowned ghost) |
| Character_31_Female | drowned_f (drowned ghost) |

- Not from the pack: `clip_source.glb` is a copy of the game's own
  `assets/models/ready/bao/bao.glb` (batch rig with Idle / Walk / Carry), used
  only as the animation source; `*_bone_map.tres` are generated.

## Pipeline

1. Copy `<name>.fbx` + `<name>.png` here, add the id to `PsxCharacterVisual.CAST`.
2. `Godot --headless --path . --import` (creates the default `.import`).
3. `python3 tools/psx_chars/set_retarget_import.py` (BoneMap to
   SkeletonProfileHumanoid, rename to profile names, unique `GeneralSkeleton`,
   overwrite axis + fix silhouette, spine / feet excluded from the silhouette fix).
4. `--import` again. Bone maps come from `tools/psx_chars/make_bone_maps.gd`.
