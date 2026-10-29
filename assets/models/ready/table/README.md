# Stainless-steel dining table — active Hunyuan model

Status: **integrated**, 2026-10-29.

`input.png` is an original 1536×1024 RGBA single-object stainless-steel table image
created with built-in `image_gen.imagegen`; `prompt.txt` is the exact final prompt.
Target dimensions are 1.50 m X × 0.86 m Y × 1.20 m Z, 1,200 final triangles.

The first attempt on the official Tencent Hunyuan3D-2.1 Space was refused by its
ZeroGPU quota. The shape was then generated locally with Hunyuan3D-2mini-turbo on CPU
(FlashVDM, octree 128, seed 1234, ~3.5 min), the project's main tool since 2026-10-28:

- `table_raw.glb`: 65,596-triangle inference output.
- `table_reduced.glb`: reduced to 1,200 triangles by hy3dgen `FaceReducer`.
- `table.glb`: normalized to metre dimensions, bottom-centred, flat normals, two
  palette materials (top / legs) by `tools/art/build_furniture_pilot.py`.
- `hunyuan_provenance.json` / `provenance.json`: parameters, weights and SHA-256 chain.

Reproduce:

```
powershell -File tools/art/hunyuan_local.ps1 -Image assets/models/ready/table/input.png -OutDir assets/models/ready/table -Name table -Faces 1200
python tools/art/build_furniture_pilot.py
```

Used in the restaurant, renovation preview and art pilot gallery. The previous
tabletop collider is retained; inferred mesh bounds match the original table size.
