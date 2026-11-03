# bamboo_fence

Generated: 2026-11-02 (Asia/Ho_Chi_Minh).
Tool: built-in `image_gen` (generation).
Brief: `docs/HORROR_CODEX_BRIEF_3.md`.
Source: `/Users/nguyenthinh/.codex/generated_images/01a19b19-ca39-7e02-b125-3a24b6bac1fa/exec-0851de4d-61b1-49a5-abc5-9f3a3d4f8df5.png`
Output: `assets/concepts/horror/bamboo_fence.png`
Native dimensions: 1254×1254.
Delivered: 1024×1024, opaque RGB PNG.
SHA-256: `89933f5a330634baed7a0a260c08e58658498787c0decf8339e66bf56086d4e7`

## Prompt used

```text
Style: late-1990s PS1 survival-horror look for a low-poly 3D game. Low detail, readable shapes,
slightly desaturated colours, soft grainy noise, no photographic sharpness. Rural coastal Vietnam
in the 1990s, poor fishing village, humid and worn. Palette: faded lime-wash yellow and green
plaster, rust, dark wet wood, grey-blue sea, warm oil-lamp amber as the only bright accent.
No text, no logos, no watermark.
Concept for image-to-3D, single object: a 3 m section of a low village fence of split bamboo tied with rope, slightly leaning.
1024x1024 opaque PNG. Single centered isolated complete asset, three-quarter view from slightly above, plain uniform light-grey background, no cast shadow, nothing cropped, clear margins. Simplified PS1 low-poly shapes and low-resolution texture detail, not photorealistic. No extra props beyond the requested subject.
No readable text, no logos, no watermarks, no real place names, brands or real people.
```

## Post-processing

Proportional Lanczos resize and edge-colour padding; no subject stretching.
Original generator source retained. No programmatic repainting or palette quantization.

## Validation and review

Isolated whole-object concept for image-to-3D; draft for art review.
No game integration, no runtime references changed, not approved.

## Brief 4 — background removal, 2026-11-03

Tool: local Python (Pillow/NumPy), explicitly requested background cut. Source RGB and original sidecar preserved at `.art_backups/brief4_projection_20261103/assets/concepts/horror/bamboo_fence.png`. Removed neutral pixels within 35 RGB levels of median border colour, with channel spread <16; geometry and object colours retained. Output RGBA with true alpha, dimensions unchanged. Projection uses alpha to replace background samples with object-colour fallback; it does not cut holes in the 3D mesh.
Material PNG SHA-256: `6b288d8e3afc85ea0045b12fc4db874aa0d23ff2d9702af495a5fe06604b47e1`.
