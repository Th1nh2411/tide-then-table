"""Repair the inferred tree's flat canopy; retain its inferred concrete planter.

uv run --with trimesh --with scipy --with fast-simplification python tools/art/repair_horror_planter_tree.py
Editable geometry recipe; no inference, image edits or material/style changes.
The accepted derivative is staged separately by prepare_horror_models.py.
"""
from pathlib import Path
import hashlib
import json
import shutil
import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[2]
NAME = 'planter_tree_street'


def branch(a, b, ra, rb):
    direction = b-a
    direction /= np.linalg.norm(direction)
    u = np.cross(direction, [0, 0, 1])
    if np.linalg.norm(u) < .01:
        u = np.cross(direction, [1, 0, 0])
    u /= np.linalg.norm(u)
    v = np.cross(direction, u)
    ring = np.array([np.cos(t)*u+np.sin(t)*v for t in np.linspace(0, 2*np.pi, 7, endpoint=False)])
    vertices = np.vstack([a+ring*ra, b+ring*rb, a, b])
    faces = []
    for i in range(7):
        j = (i+1) % 7
        faces += [[i, j, 7+j], [i, 7+j, 7+i], [14, j, i], [15, 7+i, 7+j]]
    return trimesh.Trimesh(vertices, faces, process=False)


def main():
    source = ROOT/'build/brief5/repair_tree'/NAME
    if not (source/f'{NAME}_raw.glb').exists():
        source = ROOT/'assets/models/ready'/NAME
    out = ROOT/'build/brief5/tree_geometry_repair'/NAME
    out.mkdir(parents=True, exist_ok=True)
    mesh = trimesh.load(source/f'{NAME}_raw.glb', force='mesh')
    low, high = mesh.bounds
    width, height, _ = mesh.extents
    # Keep the actual inferred concrete ring, not the rectangular canopy sheet.
    centers = mesh.triangles_center
    plane_z = np.median(mesh.vertices[mesh.vertices[:,1] > low[1]+height*.5, 2])
    sheet = (np.abs(mesh.face_normals[:,2]) > .8) & (np.abs(centers[:,2]-plane_z) < .035)
    keep = (centers[:,1] < low[1]+height*.19) & ~sheet & (np.linalg.norm(centers[:,[0,2]],axis=1) < .38)
    planter = mesh.submesh([np.where(keep)[0]], append=True)
    if len(planter.faces) > 900:
        planter = planter.simplify_quadric_decimation(face_count=900)
    # Image coordinates are an editable tracing of the approved original concept.
    # They map through its measured concept crop to the same model coordinates.
    crop = json.loads((ROOT/'assets/models/ready/horror_models.json').read_text())[NAME]['crop']
    def point(x, y, z=0):
        return np.array([low[0]+(x/1024-crop[0])/crop[2]*width,
                         low[1]+(1-(y/1024-crop[1])/crop[3])*height, z])
    parts = [planter]
    paths = [
        ([(525, 855, 0), (550, 685, .02), (505, 565, .04), (490, 485, 0), (455, 405, .04), (414, 300, -.03), (440, 190, .03)], .075, .018),
        ([(505, 565, .04), (610, 490, .08), (755, 470, .16), (845, 380, .18)], .045, .009),
        ([(490, 485, 0), (360, 455, -.10), (260, 380, -.18), (165, 338, -.12)], .038, .008),
        ([(414, 300, -.03), (300, 245, .12), (245, 165, .20)], .03, .008),
        ([(455, 405, .04), (550, 300, -.18), (650, 200, -.16), (775, 210, -.12)], .032, .008),
        ([(440, 190, .03), (490, 120, .12)], .018, .007),
    ]
    for path, start, end in paths:
        points = [point(*p) for p in path]
        radii = np.linspace(start, end, len(points))
        for i in range(len(points)-1):
            parts.append(branch(points[i], points[i+1], radii[i], radii[i+1]))
    rng = np.random.default_rng(5678)
    clusters = [(230, 145, .20), (390, 155, -.05), (510, 135, .15), (680, 195, -.18),
                (790, 210, -.12), (170, 330, -.12), (260, 370, -.18), (790, 355, .18),
                (865, 385, .16), (440, 230, .02)]
    for x, y, z in clusters:
        center = point(x, y, z)
        for i in range(9):
            angle = 2*np.pi*i/9+rng.uniform(-.2, .2)
            along = np.array([np.cos(angle), rng.uniform(-.18, .16), np.sin(angle)])
            side = np.cross(along, [0, 1, 0]); side /= np.linalg.norm(side)
            length = rng.uniform(.16, .24)
            middle = center+along*length*.7+np.array([0, rng.uniform(-.04, .04), 0])
            half = rng.uniform(.045, .075)
            # Broad almond leaves, folded along a real central vein; no alpha rectangle.
            vertices = np.array([center, middle-side*half, center+along*length*1.8,
                                 middle+side*half, middle+np.array([0, .018, 0])])
            parts.append(trimesh.Trimesh(vertices, [[0,1,4],[1,2,4],[2,3,4],[3,0,4]], process=False))
    finished = trimesh.util.concatenate(parts)
    assert len(finished.faces) <= 3000 and np.isfinite(finished.vertices).all()
    finished.export(out/f'{NAME}_reduced.glb', include_normals=True)
    for filename in [f'{NAME}_raw.glb', 'LICENSE-HUNYUAN.txt']:
        shutil.copy2(source/filename, out/filename)
    record = json.loads((source/'hunyuan_provenance.json').read_text())
    record['reduced_sha256'] = hashlib.sha256((out/f'{NAME}_reduced.glb').read_bytes()).hexdigest()
    record['artist_repair'] = {'tool': 'tools/art/repair_horror_planter_tree.py',
        'reason': 'Both inferred versions left trunk and canopy on a rectangular sheet',
        'preserved': 'Hunyuan raw source and inferred concrete planter',
        'rebuilt': 'Volumetric tapered trunk/branches and folded polygon leaves traced from original concept',
        'blend_source': 'art_source/horror/planter_tree_street_repair.blend',
        'triangles': len(finished.faces), 'input_raw_sha256': record['raw_sha256']}
    (out/'hunyuan_provenance.json').write_text(json.dumps(record, indent=2)+'\n')
    print('Tree geometry repaired:', len(finished.faces), 'triangles')


if __name__ == '__main__':
    main()
