# Vietnamese plastic stool — Hunyuan pilot

2026-10-28. A real imagegen → Hunyuan → reduction → flat material → Godot pilot.
No Blender, procedural replacement shape or paid generator was used.

- `input.png`: original isolated blue Vietnamese plastic stool image generated
  with built-in `image_gen.imagegen`, transparent RGBA, 1313×1198.
- `prompt.txt`: exact final image prompt.
- `stool_raw.glb`: original official Tencent Space shape output.
- `stool_reduced.glb`: actual Space reduction result, exactly 600 triangles.
- `stool.glb`: derivative of that reduced shape; oriented footprint, normalized
  to 0.55 m X × 0.52 m Y × 0.55 m Z with bottom-centred origin, flat vertex normals
  and muted blue `3c5e8b` lit plastic material. The geometry is inference-derived.
- `hunyuan_provenance.json`: endpoint parameters, status, raw/reduced SHA-256.
- `provenance.json`: normalization/material changes and final SHA-256.
- `LICENSE-HUNYUAN.txt`: retained source license; it is not CC0.

Reproduction:

```sh
uvx --from gradio-client==1.3.0 python tools/art/hunyuan_job.py --image assets/models/ready/stool/input.png --out-dir assets/models/ready/stool --name stool --faces 600
python3 tools/art/build_furniture_pilot.py
```

The second command only normalizes existing inference output, retaining backups.
The first command uploads the image and requests a public GPU job; quota applies.
The source image and original output are preserved.

Runtime integration replaces only the two old box stool visuals beside each table.
The existing red/blue distinction is preserved: red is a per-instance material
variant of the same inferred geometry. Collider dimensions/positions, table
visuals/colliders, dish placements, interaction positions and gameplay are unchanged.
Runtime source backup: `build/art_pilots/backups/furniture_before_runtime/`.

Bare gallery wrapper: `scenes/art_pilots/furniture_pilot.tscn`.
Standalone review scene removed 2026-10-29; view in the restaurant.
Review captures/logs: `build/art_pilots/furniture/`.

Verified: front/side/back/three-quarter, furniture arrangement and gameplay scale;
actual runtime screenshot; 8 inferred stool instances at canonical dimensions and
floor origins; unchanged stool collider count and plate heights; restaurant smoke
and cook/pickup/eat/pay/clean/pantry regression checks passed with `--no-autosave`.
The inferred legs/feet retain small asymmetries visible close up. This is a first
pilot, not a claim that image-to-shape yields manufactured dimensional precision.
