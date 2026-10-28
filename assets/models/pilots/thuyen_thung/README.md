# Thuyền thúng — Hunyuan art pilot

2026-10-28. Actual imagegen → Hunyuan image-to-shape → reduction → palette → Godot
asset. No Blender and no procedurally synthesized replacement hull were used.

## Inputs and source

- `input.png`: 1536×1024 RGBA concept generated with the built-in imagegen tool.
  One round Vietnamese bamboo coracle, open interior, rim and one bench; no sea,
  person, lantern or paddle. Full final prompt: `prompt.txt`.
- `thuyen_thung_raw.glb`: original Hunyuan shape result.
- `thuyen_thung_reduced.glb`: 2,400-triangle result from the official Tencent
  Space's reduction/export endpoint.
- `hunyuan_provenance.json`: input checksum, provider/API parameters, generation
  and reduction results. `LICENSE-HUNYUAN.txt` preserves source attribution.

The public Space accepted this shape and reduction request. No paid provider,
local weights or Blender install were involved. To regenerate via the shared CLI:

```sh
uvx --from gradio-client==1.3.0 python tools/art/hunyuan_job.py --image assets/models/pilots/thuyen_thung/input.png --out-dir assets/models/pilots/thuyen_thung --name thuyen_thung --faces 2400
```

## Prepared asset

`thuyen_thung.glb`: 2,400 triangles, 6 material surfaces, static geometry.
Canonical dimensions: X 2.4 m, Y .535 m, Z 2.396 m. Pivot is centered in X/Z,
bottom is Y=.025 m, rim maximum is Y=.560 m.

`tools/art/build_boat_pilot.py` preserves the reduced mesh's topology/face count,
normalizes its scale, relaxes only small ripples on existing low-floor vertices,
adds flat face normals and assigns six muted bamboo/wood/tar materials. It does
not add a procedural rim, bench, floor, lid or hull. The raw/reduced files remain
unchanged; `prepared_provenance.json` records transformations and checksums.

A 25-point ray test inside the rim confirms a real low interior rather than a lid:
all topmost interior hits are below .34 m, sampled area includes the inferred
floor/bench, centre top is about .091 m and interior sample heights span
approximately .048–.195 m. The visible rim reaches .560 m.

Residual limitation: the inferred floor retains a small uneven patch in its centre
and the rim is not perfectly circular after low-poly reduction. This is a visual
pilot, not a manifold/physical boat simulation or final approved production asset.

## Scenes and runtime

- `scenes/art_pilots/boat_pilot.tscn`: bare visual wrapper, no lights, camera or UI;
  safe to instance in the gallery or sea.
- `scenes/art_pilots/boat_pilot_preview.tscn`: standalone F6 inspection. 1 three-quarter,
  2 top, 3 side, 4 gameplay camera distance; left/right rotate.
- `scenes/sea3d/sea_scene_3d.gd::_build_boat()`: only the default `thuyen_thung`
  hull/bench primitives are replaced. Existing BoatVisual, lamp, collider, controller, upgrade variants and casting
  cinematic are retained. The three temporary rider boxes are replaced by a bare
  Rin pilot instance (scale .85, feet Y=.20 for the thúng or Y=.65 for upgraded decks, Z=.30, yaw=PI), keeping the existing
  `rin_figure` hide/show array contract without adding a cutscene actor group.

Runtime-only fit uses hull scale Y=.75 and position Y=.14. This keeps the maximum
rim at .560 m while lifting the inferred interior above the sea's flat water
planes even during the existing ±.06 m bob. There is no added cover-floor mesh.
The canonical GLB and bare gallery wrapper retain their full .535 m height.

Pre-integration runtime backup:
`build/art_pilots/backups/20261028_144134_755913/sea_scene_3d.gd`.

## Validation

Godot 4.7.2 Compatibility import, six review views and an actual sea gameplay
capture completed without engine errors. Logs/images: `build/art_pilots/boat/`.

- `sea_scene_3d_smoke.tscn`: PASS.
- `cast_cinematic_3d_test.tscn`: 5 PASS, including control return.
- Actual-sea capture checks the generated hull node plus separate actor and lamp.

All game checks used `-- --no-autosave`. No approved sprite/portrait was changed.
