# Rin — portrait-led 3D study

Draft dated 2026-10-28; not approved and not installed in gameplay.
Reference: `assets/sprites/portraits/rin/base.png` (read only).

- Mesh details: swept dark hair, rectangular frames, eyes/lids, nose/mouth,
  ear helix/concha, silver stud, white singlet, black cord/fish-hook pendant,
  fingers, shorts and sandals.
- Imported Godot height approximately 1.8 metres, front +Z.
- Rig: weighted skeleton; clips `Idle`, `Walk`, `Carry`. A first-pass animation
  study, not a final deformation/animation polish pass.
- Preview: open `scenes/art_preview/rin_portrait_study.tscn`, F6.
  Arrows rotate; 1/2/3 choose clip; 4 toggles close/full-body.
- Editable Blender source and renders: `build/characters/rin_portrait_study/`.
- Reproducible builder: `tools/blender/build_rin_portrait_study.py`.
  Execute from Blender's Python context; each rebuild backs up earlier outputs
  before exporting the candidate GLB. No original scene is cleared.
- `comparison.png` compares the approved portrait and three rendered views;
  `godot_preview.png` shows the imported asset next to the reference.

This is a separate character candidate. The face proportions and hair likeness
remain subject to art review; preview success does not establish visual approval.
