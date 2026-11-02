# Night sky panorama v1

Generated with built-in `image_gen`, 2026-11-02. No existing assets replaced; no gameplay integration changed.

Deliverable: `night_sky_panorama_v1.png`, opaque RGB PNG, 4096×2048. The generator produced 1774×887; final is a mechanical Lanczos upscale. Original selected output retained as `night_sky_panorama_v1.source.png`.

Visual review: navy-indigo night sky, one pale-teal moon at approximately 47° elevation, sparse stars, clean painterly wispy clouds, no land, sea, people or text. Moon is horizontally elongated for equirectangular mapping. The quiet vertical edges have no clipped clouds; their measured source RGB difference averages 0.85/255, maximum 5/255. This is visually close to seamless but not mathematically identical. Colors are approximate generated interpretations of the specified hex palette. Full in-engine spherical validation remains outstanding.

## Initial prompt

```text
Use case: stylized-concept
Asset type: game sky texture, seamless 360-degree full-sphere equirectangular panorama, EXACT 4096x2048 pixels (2:1).
Primary request: Seamless 360° equirectangular night sky panorama for a stylized low-poly fishing game. Deep navy-indigo gradient (#090a14 at zenith to #172038 near horizon), one large soft pale-teal full moon at approximately 45° elevation with a faint halo, sparse small stars, a few thin wispy clouds lit from below by the moon. Painterly but clean, low detail, limited palette.
Projection/composition: full 360 longitude by 180 latitude equirectangular sphere texture. Zenith at top, horizon exactly at vertical center, nadir at bottom; moon center at one quarter of image height (45° elevation). Moon should appear naturally round when mapped to a sphere (horizontally elongated in this equirectangular image). Below the horizon continue the dark indigo sky gradient smoothly without terrestrial objects. Left and right edges must match perfectly in color and cloud pattern, no visible seam; keep objects away from the wrap seam. Pole rows should be uniform colors without stars to avoid pinching. Broad quiet negative space. Soft subtle clouds only, very sparse small stars, no galaxy.
Constraints: no text, no watermark, no land, no sea, no horizon silhouettes, no people, no borders. Opaque background. Clean low-poly-friendly painterly look, restrained contrast, no photographic texture.
```

## Targeted edit prompt

```text
Edit this game equirectangular sky texture. Keep its navy indigo clean painterly low-detail style, pale teal full moon faint halo, sparse stars and thin wispy moonlit clouds. Make the panorama horizontally seamless by making the LEFTMOST and RIGHTMOST 5% entirely plain identical horizontal color gradient with NO clouds or stars near these edges. Clouds must not cross either outer vertical edge. Make top and bottom 3% uniform #090a14 without stars. Gradient horizon at y50% should be subdued #172038 and zenith #090a14; reduce bright blue band at horizon. Move moon to y25% height for 45 degree elevation and horizontally elongate moon by factor 1.414 so mapped sphere makes it round. Preserve moon longitude and roughly size. Full 360x180 equirectangular 2:1 output, requested 4096x2048. No land sea people text watermarks.
```
