# Stainless-steel dining table — input ready, inference blocked

Status: **blocked_by_quota**, 2026-10-28.

`input.png` is an original 1536×1024 RGBA single-object stainless-steel table image
created with built-in `image_gen.imagegen`; `prompt.txt` is the exact final prompt.
Target dimensions are 1.50 m X × 0.86 m Y × 1.20 m Z, 1,200 final triangles.

The actual official Tencent Space job was attempted, but it refused before shape
inference: `You have exceeded your ZeroGPU quota (90s requested vs. 65s left).
Try again in 23:37:39. Authenticate with a Hugging Face token for more quota`.
The full provider response and parameters are retained in `hunyuan_provenance.json`
and `build/art_pilots/furniture/table_job.log`.

There is **no table_raw.glb, table_reduced.glb or table.glb** and no generated mesh
is claimed. The existing procedural table remains in runtime and the gallery
wrapper; it is explicitly labelled as an existing visual pending Hunyuan output.
No repeated quota circumvention, paid provider or fabricated inference source was used.

Once genuine provider access is available, use:

```sh
uvx --from gradio-client==1.3.0 python tools/art/hunyuan_job.py --image assets/models/pilots/table/input.png --out-dir assets/models/pilots/table --name table --faces 1200
python3 tools/art/build_furniture_pilot.py
```

Then review the actual table mesh from several angles before replacing the table
visual. The normalizer will report the missing inference result until it exists.
