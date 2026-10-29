# jellyfish

Derived from `assets/models/batch/small/jellyfish/jellyfish_reduced.glb` using `tools/art/build_batch_sea.py`.

- Hunyuan reduced geometry preserved; only world-baked affine fit/orientation, face palette, and flat normals applied.
- Y-up, bottom at Y=0; dimensions in `provenance.json` are meters.
- Source concept and SHA-256 are recorded in provenance; upstream license is included.
- Runtime boat/POI collisions remain the existing gameplay shapes, rather than inferred mesh collisions.
- AI-inferred small details remain approximate. Boats use separate Rin and lamp visuals; no rig or animation is embedded in these static props.
