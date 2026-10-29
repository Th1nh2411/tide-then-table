"""Read-only validation of finished Hunyuan batch geometry, lineage and skin data."""
import json
from pathlib import Path
import numpy as np
from check_pilot_assets import GLB, checksum

ROOT = Path(__file__).resolve().parents[2]


def main():
    sources = sorted((ROOT / 'assets/models/batch').glob('*/*/*_reduced.glb'))
    assert len(sources) == 45, f'Expected 45 source assets, got {len(sources)}'
    total, people = 0, 0
    for source in sources:
        asset = source.parent.name
        folder = ROOT / 'assets/models/ready' / asset
        output = folder / (asset + '.glb')
        meta = json.loads((folder / 'provenance.json').read_text())
        assert meta['source_sha256'] == checksum(source), asset + ': source checksum mismatch'
        assert meta['output_sha256'] == checksum(output), asset + ': output checksum mismatch'
        original, final = GLB(source), GLB(output)
        counts = []
        for glb in (original, final):
            triangles = 0
            for mesh in glb.doc['meshes']:
                for primitive in mesh['primitives']:
                    attrs = primitive['attributes']
                    positions = glb.read(attrs['POSITION'])
                    ids = glb.read(primitive['indices']).reshape(-1) if 'indices' in primitive else np.arange(len(positions))
                    assert len(ids) % 3 == 0 and ids.min() >= 0 and ids.max() < len(positions)
                    triangles += len(ids) // 3
                    if glb is final:
                        normal = glb.read(attrs['NORMAL'])
                        assert np.allclose(np.linalg.norm(normal, axis=1), 1, atol=.003), asset + ': invalid normals'
                        a, b, c = positions[ids].reshape(-1, 3, 3).transpose(1, 0, 2)
                        assert (np.linalg.norm(np.cross(b-a, c-a), axis=1) > 1e-10).all(), asset + ': degenerate faces'
                        assert 0 <= primitive['material'] < len(glb.doc['materials'])
                        if source.parent.parent.name == 'characters':
                            weights = glb.read(attrs['WEIGHTS_0'])
                            joints = glb.read(attrs['JOINTS_0'])
                            assert weights.shape == joints.shape == (len(positions), 4)
                            assert weights.min() >= 0 and np.allclose(weights.sum(axis=1), 1, atol=.002)
                            assert joints.min() >= 0 and joints.max() < 20
            counts.append(triangles)
        assert counts[0] == counts[1], asset + ': source triangle count changed'
        for material in final.doc['materials']:
            factor = material['pbrMetallicRoughness']['baseColorFactor']
            assert len(factor) == 4 and all(0 <= v <= 1 for v in factor)
        if source.parent.parent.name == 'characters':
            people += 1
            assert len(final.doc['skins'][0]['joints']) == 20
            assert {a['name'] for a in final.doc['animations']} == {'Idle', 'Walk', 'Carry'}
        total += counts[1]
        print(f'PASS {asset}: {counts[1]} triangles; source/output checksums, finite accessors, normals and materials')
    assert people == 11
    print(f'ALL OK: {len(sources)} assets, {total} triangles, {people} weighted humanoids; source triangle counts preserved')


if __name__ == '__main__':
    main()
