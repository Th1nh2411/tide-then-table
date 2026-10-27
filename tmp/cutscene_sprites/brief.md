# Cutscene sprite brief — 2026-10-27

Destinations: characters/crate.png20×14, rin_bed.png32×16, rin_faint.png32×10; characters/glow.png320×80, 4 horizontal80×80 frames.

Perspective and framing: crate 3/4 orthographic with three small fish above rim; bed Rin prone head left, cool blanket and illuminated phone; faint Rin prone head left, white tank/dark shorts/sandals, exposed glowing hand and no blanket. Glow is a stepped breathing teal aura, centered with transparent padding.

Authority: ASSETS.md, ART_PLAN.md; inspected protected characters/rin.png and actual CutsceneActor fallback. Existing code-native fallback is the editable source; tools/cutscene_sprites.py independently authors every new native pixel. No AI source is required for this code-native conversion, no resampling, no changes to approved Rin pixels.

Palette: Xóm Đèn only; aim <=10 opaque colors for actors. Binary alpha on crate/Rin poses. Glow intentionally has stepped translucent rings, an explicit luminous exception matching _draw_glow; no blurred edges or antialiasing. Art.draw_frame overbright teal tint preserves night visibility just like the original fallback.

No existing file for these IDs was replaced at initial creation. Script backs up any subsequent active replacement under build/cutscene_sprites/backups/.
