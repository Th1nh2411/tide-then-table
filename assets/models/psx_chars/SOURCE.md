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
| Character_Female_09 | ma_da (long-haired drowned woman; ghost look only) |
| Character_47_Female | ma_da_b (second ma da; ghost look only) |
| Character_32 | drowned_old (thin old man; ghost look only) |
| Character_Killer_06 (`Rig/Killer_M`) | corpse (long-drowned body; ghost look only, never plain: its own texture is a bloody slasher) |

Ghost cast review (`scenes/art_pilots/horror_cast_review.tscn`, shots in
`build/shot/horror_cast/`): also tried and dropped (not copied): Character_Monster
(alien face, rig imports without a skeleton), Character_Killer_08 (pig mask,
slasher), Female 36/37/40/44/49/Female_08 (short hair, office / rock / lace
clothes), Male 29/41/43 (Character_32 reads older and thinner).

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
