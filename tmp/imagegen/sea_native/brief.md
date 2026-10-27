# Sea boat assets — 2026-10-27

Destinations: assets/sprites/sea/thuyen_thung.png (32x32), ghe_cheo.png (48x20), ghe_may.png (60x24).
Consumer: Boat._draw uses sea/<BoatData.id>, hull_size at half native dimensions, sea camera x2; bow points +X. Rin and cat are separate upright drawings and must not be baked into boat.
Perspective: top-down orthographic deck, no isometric convergence. Hull side remains screen-down, so no baked lateral shadow or tall side. No water baked into asset.
Palette: Xóm Đèn; restrained navy outline, warm wood for basket/rowboat, navy/blue motorboat with warm wood interior; target <=8 opaque colours each, binary alpha.
References inspected: restaurant/table.png, food_cart_0.png, portraits/rin/base.png; native geometric pixel clusters, simple material cues, navy outlines. Preserve all existing art and hand-corrected character sprites. Sea directory has no active boat PNG to replace.
Tool: built-in imagegen, one asset per call, exact native canvas requested. No oversized-image rescue or pixelize. Source retained under tmp/imagegen/sea_native. Native-size output must be validated before runtime integration.

## Delivery and provenance

Built-in imagegen was used separately for all four assets. It did not honor native pixel output dimensions: all generated sources are oversized concepts retained as `*_source.png`. None was resized, sampled, quantized, or used as a master. The four masters were drawn independently by explicit native pixel placement in `tools/make_sea_sprites.py`; this is the hand-finish fallback described in ASSETS.md for thuyền thúng and nón lá. Native renderer placement preserves the documented screen dimensions.

Prompt set: `stylized-concept`, final native transparent sprite, precise canvas requested per asset, navy outline and Xóm Đèn colours, 1px margin, no antialiasing/dithering/gradients/shadows/text/water. Subjects were (1) empty round Vietnamese bamboo basket coracle with one bench, (2) right-facing narrow wooden rowing boat with two cross benches, (3) right-facing blue wooden motorboat with left-stern compact outboard, (4) standing Rin with conical nón lá, glasses, white tank top, dark shorts and sandals. Exact native dimensions were included in each individual generation prompt; source resolution mismatch is why they remain concepts.

Technical checks: exact 32x32 / 48x20 / 60x24 / 16x32; all corners alpha 0; only binary alpha; all opaque colours in Xóm Đèn palette; 5 / 5 / 8 / 6 colours. Native and enlarged pixels inspected against table/cart references. Real Godot Boat consumer preview generated with 0°, 90°, 180° at `consumer_preview.png`; hull extrusion stays down-screen, crew stays upright. No old PNG existed before this batch; revisions of newly created files were recovered in `build/sea/backups/`.

Code integration: Boat now extrudes the actual texture silhouette in screen-down direction before drawing the rotating deck. The old angular placeholder shadow is only drawn on the placeholder path, so no polygon leaks below the art. Sea-scene headless smoke run passed, native renderer preview passed. Visual approval remains pending with the user; this technical/art review is not user approval.
