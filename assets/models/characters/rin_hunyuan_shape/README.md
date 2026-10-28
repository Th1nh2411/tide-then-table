# Rin — actual Hunyuan3D-2.1 image-to-shape trial

2026-10-28. Generated successfully through Tencent's official public Hugging Face
Space: https://huggingface.co/spaces/tencent/Hunyuan3D-2.1 . This is model inference
from an image, not the earlier hand-authored Python mesh experiment.

## Delivered files

- `input_front.png`: 505×941 front-view crop from the existing imagegen concept
  `assets/concepts/rin/lowpoly_turnaround_v1.png`. Only one character
  is submitted, not the whole three-view sheet.
- `rin_hunyuan_shape.glb`: original shape output, 78,972 triangles; preserved bytes.
- `rin_hunyuan_3k.glb`: reduced to exactly 3,000 triangles by the same Space's
  export endpoint; preserved bytes.
- `rin_hunyuan_3k_lit.glb`: the 3,000-triangle output with smooth vertex normals
  added by `tools/mesh/add_glb_normals.py`. Vertex positions and triangle indices
  are unchanged; this derivative supports lit preview/import. No color/texture was added.
- `provenance.json`: provider, parameters, input lineage, changes and SHA-256 hashes.
- `LICENSE-HUNYUAN.txt`: upstream Tencent Hunyuan 3D 2.1 Community License.

Both shape outputs are static: no skin, skeleton, animations or generated texture.
The preview uses a neutral clay material and reconstructs missing normals for
unprocessed shape outputs; this is display shading, not Hunyuan's PBR texturing.
The original dimensions are normalized to 1.84 m only in the preview node transform.

## Tested workflow

The public Space was running and accepted one unauthenticated job. Client:
`gradio-client==1.3.0`, run in an isolated uv tool environment. No local model weights,
CUDA packages, Blender process or full Hunyuan installation were used on this Mac.
The hosted Space is operated by Tencent; this test does not audit all of its internals.

1. `/shape_generation`: input image, steps=20, guidance_scale=5, seed=1234,
   octree_resolution=192, check_box_rembg=true, num_chunks=8000,
   randomize_seed=false. The endpoint returned a downloadable GLB.
2. `/on_export_click`: upload the generated GLB, file_type=glb, reduce_face=true,
   export_texture=false, target_face_num=3000. It returned the reduced GLB.
3. Added vertex normals locally with NumPy, then imported/reviewed in Godot 4.7.2
   Compatibility. Art preview is isolated from gameplay and existing Rin assets.

Review logs, API results and screenshots: `build/hunyuan21_trial/`.
Open `scenes/art_preview/rin_hunyuan_study.tscn` and press F6. Left/right rotate,
4 changes close/full body, B toggles original 78,972 and reduced 3,000 triangles.
Default view uses the reduced candidate. Input image appears on the left.

## Findings and limits

The shape captures the input's broad silhouette, swept hair, glasses, arms and
roomy shorts. The first low-resolution run still fuses small details: necklace,
clothing edges and fingers need cleanup. A 3,000-triangle mesh alone is not a
finished stylized character: retopology/shape refinement, materials and a
humanoid rig with checked skin weights remain required. No animation parity
or production quality is claimed by this trial.

## Local feasibility and license

The upstream README lists ~10 GB VRAM for shape, ~21 GB for paint, and ~29 GB for
both. Although it mentions macOS, its default install includes CUDA extensions,
`cupy-cuda12x` and `bpy==4.0`; the paint pipeline selects CUDA. The current M1 Mac
has 16 GB unified memory and approximately 12 GB free disk at review time. The
full upstream pipeline was not installed locally.

A community MPS/ROCm port exists at
https://github.com/VladimirTalyzin/hunyuan3d-2.1-mac-rocm . Its author documents
about 30 GB of downloads and a full-pipeline Mac test on M4 Pro/24 GB. That does
not establish feasibility on this M1/16 GB, and available disk is insufficient
for the documented full install. The port also offers Blender-free export.

Upstream sources checked:

- https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1
- https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/requirements.txt
- https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE

This is **not CC0**. The license excludes EU/UK/South Korea and section 5(c)
expressly extends that territorial restriction to Outputs. Treat this as an
evaluation candidate; account for the actual license before international release.
The license says Tencent claims no rights in generated Outputs, but that does
not remove the separately stated usage restrictions.
