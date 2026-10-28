# Rin — mesh + painted textures (candidate)

Draft 2026-10-28. A separate variant; the approved portrait, earlier mesh study and
active gameplay character are preserved.

- `rin_painted.glb`: one skinned mesh with 13 material surfaces, 11,718 triangles.
  Earlier study: 112 mesh objects/surfaces, 19,296 triangles. One mesh is not one draw call.
- Face/eyebrows/eyelids/mouth, hair strands and cotton folds use imagegen-created
  albedos, guided by the approved Rin portrait. Glasses, ears, nose and the main
  hair silhouette remain geometry. All materials still respond to lighting.
- Three 256×256 albedos are embedded in GLB. Original generated PNG sources are
  preserved in `textures/`; `face_albedo_v1.png` is the earlier unused candidate.
- `Idle`, `Walk`, `Carry` share the prior weighted skeleton.
- F6 `scenes/art_preview/rin_painted_study.tscn`: B compares the previous mesh;
  arrows rotate; 1/2/3 choose animation; 4 changes close/full body; 5 shows quán scale.
- Blender source/renders/backups: `build/characters/rin_painted/`.
- Builder: `tools/blender/build_rin_painted_study.py`, executed inside Blender.
  It derives from `build/characters/rin_portrait_study/rin_portrait_study.blend`;
  if missing, first run the original `build_rin_portrait_study.py` builder.

This applies the simple-mesh/painted-detail approach discussed in the Reddit
reference; it does not copy that author's assets or claim to reproduce their engine.
Likeness, texture treatment and animation quality remain subject to art review.
