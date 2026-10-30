# Pixel Art Production Rules

These rules apply to all raster artwork below `assets/sprites/`, including gameplay characters, portraits, cats, seafood, dishes, restaurant props, grill assets, and sea assets.

## General quality rules

- Read the relevant sections of `ART_PLAN.md` and `ASSETS.md` before generating or editing an asset.
- Use the documented master dimensions. Do not upscale a smaller existing image and present it as a newly drawn master.
- Use hard, intentional pixels with crisp silhouettes.
- Do not use anti-aliasing, blur, gradients, soft lighting, bloom, glow, cast shadows, contact shadows, or texture noise unless the asset specification explicitly requires one of them.
- Use a truly transparent PNG background. Before accepting a file, verify that all four corner pixels have alpha `0`.
- Keep visual detail restrained. Prefer a readable silhouette and two or three identifying features over small patterns or decorative marks.
- Keep outer outlines consistent and predominantly use the project's dark navy outline color.
- Use nearest-neighbor for resizing and in-game display.
- Back up every active file before replacement. Keep generated source files separate from final game-ready files.
- Before completion, verify dimensions, alpha, palette size, filename, orientation, and appearance at 100% scale.

## Text in artwork

- Any words painted into an asset are short English (e.g. a stamp says "SOLD", a burst says "NEW!"). Never paint Vietnamese words into a PNG; Vietnamese player text is drawn by code with the game fonts. Exception: signs in the game world (shop signs, stall boards) keep Vietnamese, as in ASSETS.md.

## AI image workflow

- Generate each distinct asset separately. Do not ask the image model to create a multi-asset sheet and then treat inconsistent crops as final assets.
- Ask for a centered subject, generous padding, flat colors, crisp pixel edges, and no text or watermark.
- Treat generated images as source material. Crop transparent padding, resize with nearest-neighbor, reduce the palette, and inspect the result before copying it into an active asset directory.
- Do not replace an active asset when the generated subject, silhouette, anatomy, clothing, framing, or cultural detail is incorrect.
- Store intermediate generated sources under `tmp/imagegen/`. Final project assets must be copied into their documented `assets/sprites/` path.

## Gameplay character sprites

- Preserve the documented sheet layout, frame dimensions, facing directions, animation order, waist position, and manually corrected details.
- Do not regenerate an entire sheet when only one frame or body part needs correction.
- Maintain strong readability at native scale. Avoid facial or clothing details that collapse into noise.
- Re-run the relevant idle or animation assembly tools when required by `ART_PLAN.md`.

## Portraits

- Use `128x128` unless `ASSETS.md` explicitly specifies otherwise.
- Frame characters from the navel or upper abdomen upward, extending approximately to the elbows. Do not crop at the chest, and do not include hands or the lower torso unless explicitly requested.
- Match the approved Rin portrait's visual density: simple shapes, limited clusters, restrained highlights, and minimal fabric or hair texture.
- Portraits may use more than six colors when needed for readable skin, hair, clothing, and expression, but every color must serve a clear purpose.
- Keep the character's documented age, personality, hairstyle, clothing, accessories, pose, and story role recognizable.
- Expressions should change the face and posture without changing the character's identity or base proportions.

## Seafood and fish

- Use at most six opaque colors per final asset, excluding transparency.
- Follow the master grid documented in `ASSETS.md`: one inventory cell equals `80x80`; preserve the intended multi-cell proportions.
- Use a clean side view unless the asset specification calls for a top-down view.
- Keep fins, legs, tentacles, shell markings, and spots sparse and readable. Do not add realistic scales or dense surface patterns.
- Glowing variants must preserve the exact silhouette of the normal variant and should primarily use a controlled palette swap.

## Dishes and drinks

- Use `64x64` master files and at most six opaque colors per final asset, excluding transparency.
- Keep plates and bowls visually consistent across the set: similar outline weight, viewing angle, size, and ceramic color.
- Show only the food and one or two identifying garnish or cooking cues, such as grill marks, ginger, lemongrass, scallion oil, or tomato sauce.
- Do not add table surfaces, background decoration, cutlery, labels, or readable branding.
- Drinks may omit the plate but must retain the same outline weight, pixel density, and palette restraint as the dishes.

## Acceptance checks

- Confirm the file exists at its documented final path.
- Confirm exact pixel dimensions.
- Confirm transparent corners and no unintended halo.
- Confirm the opaque color count does not exceed the category limit.
- Confirm the asset remains recognizable at native scale and matches adjacent approved assets.
- Report the backup path and final asset path whenever an active file is replaced.
