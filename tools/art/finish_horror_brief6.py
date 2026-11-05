"""Author real tiled UVs / clean geometry for brief 6, preserving raw inference.

uv run --with trimesh --with pillow --with scipy --with fast-simplification python tools/art/finish_horror_brief6.py --phase houses
The immutable before files and SHA manifest live in .art_backups/brief6_20261104.
"""
from pathlib import Path
import argparse, hashlib, json, tempfile
import numpy as np
import trimesh
from PIL import Image
from glb_common import load_mesh
from prepare_horror_models import with_normals, GROUPS

ROOT = Path(__file__).resolve().parents[2]
BACKUP = ROOT/'.art_backups/brief6_20261104'
READY = ROOT/'assets/models/ready'
TEXTURES = ROOT/'assets/textures/horror'
BUDGETS={name:budget for budget,names in GROUPS.items() for name in names}
BUDGETS.update({name:int(budget) for budget,names in json.loads((ROOT/'tools/art/horror_brief5_models.json').read_text()).items() for name in names})


def material(texture=None, color=(1,1,1,1), role=None):
    name = role or ('HorrorUV_'+texture if texture else 'HorrorSolid_'+'_'.join(str(round(c*255)) for c in color))
    return trimesh.visual.material.PBRMaterial(name=name,baseColorTexture=Image.open(TEXTURES/(texture+'.png')).convert('RGBA') if texture else None,
        baseColorFactor=np.array(color,dtype=float),roughnessFactor=.95,metallicFactor=0.0,doubleSided=True)


def source_mesh(name):
    v,f=load_mesh(BACKUP/f'assets/models/ready/{name}/{name}_reduced.glb')
    return trimesh.Trimesh(v,f,process=False)


def painted_part(mesh, selected, mat, scale=3.0, roof=False):
    triangles=mesh.triangles[selected]
    normals=mesh.face_normals[selected]
    positions=triangles.reshape(-1,3)
    uv=np.empty((len(triangles),3,2))
    for i,n in enumerate(normals):
        axes=[0,2] if roof else [2,1] if abs(n[0])>abs(n[2]) else [0,1]
        uv[i]=triangles[i][:,axes]*scale
    part=trimesh.Trimesh(positions,np.arange(len(positions)).reshape(-1,3),process=False)
    part.visual=trimesh.visual.TextureVisuals(uv=uv.reshape(-1,2),material=mat)
    return part


def export(name, parts, note, rebuilt=False):
    triangles=sum(len(p.faces) for p in parts.values())
    assert triangles <= BUDGETS[name], (name,triangles,BUDGETS[name])
    scene=trimesh.Scene()
    for label,part in parts.items():
        if len(part.faces):scene.add_geometry(part,geom_name=label,node_name=label)
    with tempfile.TemporaryDirectory() as directory:
        p=Path(directory)/'model.glb';scene.export(p);payload,_=with_normals(p)
    out=READY/name/f'{name}_reduced.glb';out.write_bytes(payload)
    record=json.loads((BACKUP/f'assets/models/ready/{name}/hunyuan_provenance.json').read_text())
    record['reduced_sha256']=hashlib.sha256(payload).hexdigest()
    record['brief6']={'input_reduced_sha256':hashlib.sha256((BACKUP/f'assets/models/ready/{name}/{name}_reduced.glb').read_bytes()).hexdigest(),
        'tool':'tools/art/finish_horror_brief6.py','date':'2026-11-04','finished':'2026-11-05','blend_source':f'art_source/horror/brief6/{name}.blend','true_uv':True,'rebuilt_geometry':rebuilt,'triangles':triangles,'note':note}
    record.setdefault('integration',{})['runtime_faces']=triangles
    record['integration']['geometry_unchanged']=False
    (READY/name/'hunyuan_provenance.json').write_text(json.dumps(record,indent=2)+'\n')
    if rebuilt:
        catalog_path=READY/'horror_models.json'
        catalog=json.loads(catalog_path.read_text());v=np.vstack([p.vertices for p in parts.values()])
        bounds=np.array([v.min(0),v.max(0)]);center=bounds.mean(0)
        _,axes=np.linalg.eigh(np.cov(v.T));axis=axes[:,-1]
        if axis[np.argmax(np.abs(axis))]<0:axis=-axis
        along=(v-center)@axis
        catalog[name].update(size=(bounds[1]-bounds[0]).tolist(),axis=axis.tolist(),anchor=(center+axis*along.min()).tolist(),length=float(np.ptp(along)))
        catalog_path.write_text(json.dumps(catalog,indent=2)+'\n')
        lines=['extends RefCounted','# Generated geometry / material calibration; source: horror_models.json.','const DATA := {']
        lines += ['\t'+json.dumps(k)+': '+json.dumps(s,separators=(',',':'))+',' for k,s in catalog.items()]
        (READY/'horror_models.gd').write_text('\n'.join(lines+['}'])+'\n')
    return triangles


def textured(mesh, mat, scale=2):
    return painted_part(mesh,np.ones(len(mesh.faces),dtype=bool),mat,scale)


def cylinder(a,b,radius,sections=8):
    a=np.array(a,dtype=float);b=np.array(b,dtype=float)
    m=trimesh.creation.cylinder(radius=radius,height=np.linalg.norm(b-a),sections=sections)
    m.apply_transform(trimesh.geometry.align_vectors([0,0,1],(b-a)/np.linalg.norm(b-a)))
    m.apply_translation((a+b)*.5)
    return m


def box(at,size):
    m=trimesh.creation.box(extents=size);m.apply_translation(at);return m


def join(meshes):
    return trimesh.util.concatenate(meshes)


def tree():
    name='planter_tree_street'
    v,f=load_mesh(READY/name/f'{name}_raw.glb');raw=trimesh.Trimesh(v,f,process=False)
    low=raw.bounds[0];height=raw.extents[1];c=raw.triangles_center
    plane_z=np.median(v[v[:,1]>low[1]+height*.5,2])
    sheet=(np.abs(raw.face_normals[:,2])>.8)&(np.abs(c[:,2]-plane_z)<.035)
    keep=(c[:,1]<low[1]+height*.19)&~sheet&(np.linalg.norm(c[:,[0,2]],axis=1)<.38)
    pot=raw.submesh([np.where(keep)[0]],append=True).simplify_quadric_decimation(face_count=700)
    pot.apply_translation(-np.array([pot.bounds.mean(0)[0],pot.bounds[0,1],pot.bounds.mean(0)[2]]))
    pot.apply_scale([.85/pot.extents[0],.27/pot.extents[1],.85/pot.extents[2]])
    wood=[]
    from repair_horror_planter_tree import branch
    for a,b,ra,rb in [(0.20,1.75,.085,.065),(1.75,2.6,.065,.047),(2.6,3.35,.047,.033),(3.35,3.96,.033,.012)]:
        wood.append(branch(np.array([0,a,0]),np.array([0,b,0]),ra,rb))
    leaves=[[],[],[]];rng=np.random.default_rng(6006)
    for tier,(y,radius) in enumerate([(1.8,.83),(2.65,.71),(3.4,.57),(3.96,.27)]):
        for spoke in range(6):
            angle=spoke*np.pi/3+tier*.27
            endpoint=np.array([np.cos(angle)*radius,y+.015,np.sin(angle)*radius])
            wood.append(branch(np.array([0,y-.05,0]),endpoint,.027-tier*.003,.008))
            for leaf in range(6):
                a=angle+(leaf-2.5)*.34
                direction=np.array([np.cos(a),0,np.sin(a)])
                side=np.array([-np.sin(a),0,np.cos(a)])
                center=endpoint*.85+direction*rng.uniform(.0,.12)
                center[1]=y+rng.uniform(-.035,.035)
                length=rng.uniform(.22,.30);width=rng.uniform(.16,.22)
                ring=[]
                for t in np.linspace(0,2*np.pi,8,endpoint=False):
                    ring.append(center+side*np.cos(t)*width*.5+direction*np.sin(t)*length*.5)
                vertices=np.vstack([ring,center+np.array([0,.012,0])])
                faces=[[8,i,(i+1)%8] for i in range(8)]
                leaves[(tier+leaf)%3].append(trimesh.Trimesh(vertices,faces,process=False))
    parts={'ConcretePlanter':textured(pot,material('wall_plaster_old',(.78,.78,.74,1)),2),
           'StraightTrunkAndTiers':textured(join(wood),material('floor_wood_planks',(.67,.62,.53,1)),3)}
    for index,color in enumerate([(.25,.34,.21,1),(.31,.39,.25,1),(.36,.41,.27,1)]):
        parts[f'BroadLeaves_{index}']=textured(join(leaves[index]),material(color=color))
    print(name,export(name,parts,'Terminalia street tree: straight tapering trunk, four horizontal tiers of broad rounded leaves; inferred planter retained. Local height about 4.1 m, width under 2.4 m so the existing fit yields 4.2 m.',True))


def vessel(at,radius,height,sections=12):
    profile=np.array([[0,0],[radius*.72,0],[radius,height*.83],[radius*.96,height],
                      [radius*.83,height],[radius*.72,height*.27],[0,height*.22]])
    m=trimesh.creation.revolve(profile,sections=sections)
    m.apply_transform(trimesh.transformations.rotation_matrix(-np.pi/2,[1,0,0]))
    m.apply_translation(at);return m


def offering():
    name='altar_tray_offerings';wood=[box([0,.49,0],[.94,.055,.72])]
    for x in [-.38,.38]:
        for z in [-.27,.27]:wood.append(cylinder([x,0,z],[x,.49,z],.024))
    for z in [-.27,.27]:wood.append(box([0,.34,z],[.78,.035,.035]))
    for x in [-.38,.38]:wood.append(box([x,.34,0],[.035,.035,.54]))
    tray=trimesh.creation.annulus(r_min=.31,r_max=.34,height=.035,sections=16)
    tray.apply_transform(trimesh.transformations.rotation_matrix(-np.pi/2,[1,0,0]));tray.apply_translation([0,.55,0])
    base=trimesh.creation.cylinder(radius=.32,height=.018,sections=16)
    base.apply_transform(trimesh.transformations.rotation_matrix(-np.pi/2,[1,0,0]));base.apply_translation([0,.53,0])
    ceramic=[];rice=[]
    for x,z,r in [(-.16,.12,.075),(-.21,-.01,.05)]:
        ceramic.append(vessel([x,.55,z],r,.065))
        mound=trimesh.creation.icosphere(subdivisions=1,radius=1);mound.apply_scale([r*.85,.027,r*.85]);mound.apply_translation([x,.615,z]);rice.append(mound)
    incense=vessel([.03,.55,-.16],.065,.12)
    sticks=[cylinder([.03+x,.65,-.16],[.03+x,.95,-.16+z],.0035,6) for x,z in [(-.023,-.014),(0,.015),(.022,-.005)]]
    cane=[cylinder([.08+i*.025,.59,.04],[.25+i*.025,.59,.12],.012,7) for i in range(3)]
    cakes=[box([-.03+(i%2)*.065,.585,.10+(i//2)*.065],[.055,.055,.055]) for i in range(4)]
    papers=[box([.13,.56,-.07],[.15,.005,.12]),box([.13,.565,-.07],[.12,.004,.11]),
            box([.13,.571,-.07],[.12,.004,.10]),box([.06,.571,-.105],[.05,.004,.04]),box([.20,.571,-.105],[.05,.004,.04])]
    parts={'TableFrame':textured(join(wood),material('floor_wood_planks'),3),
           'WovenTray':textured(join([tray,base]),material('floor_wood_planks',(.74,.69,.51,1)),4),
           'RiceAndSaltBowls':textured(join(ceramic),material(color=(.48,.53,.49,1))),
           'RiceAndSalt':textured(join(rice),material(color=(.64,.61,.51,1))),
           'IncensePot':textured(incense,material(color=(.24,.30,.31,1))),
           'Incense':textured(join(sticks),material(color=(.48,.35,.22,1))),
           'Sugarcane':textured(join(cane),material(color=(.41,.46,.28,1))),
           'Cakes':textured(join(cakes),material(color=(.51,.49,.31,1))),
           'PaperClothes':textured(join(papers),material(color=(.48,.29,.23,1)))}
    print(name,export(name,parts,'Clean low table, tray, rice/salt bowls, cakes, cane, paper clothes and continuous incense stems; normal/eaten runtime logic unchanged.',True))


def clothesline():
    name='clothesline';poles=[cylinder([x,0,0],[x,1.88,0],.028) for x in [-1.35,1.35]]
    def y(x):return 1.82-.13*(1-(x/1.35)**2)
    points=[np.array([x,y(x),0]) for x in np.linspace(-1.35,1.35,9)]
    rope=[cylinder(points[i],points[i+1],.005,6) for i in range(8)]
    parts={'BambooPoles':textured(join(poles),material('floor_wood_planks',(.74,.76,.53,1)),3),
           'ContinuousRope':textured(join(rope),material(color=(.29,.27,.21,1)))}
    outline=np.array([[-.17,0],[-.33,-.09],[-.26,-.20],[-.17,-.16],[-.16,-.56],[.16,-.56],[.17,-.16],[.26,-.20],[.33,-.09],[.17,0]])
    for index,(x,col) in enumerate([(-.7,(.31,.39,.43,1)),(.1,(.43,.31,.27,1))]):
        verts=np.array([[x+u,y(x+u)+v,0 if v==0 else .025*np.sin(13*u+8*v)] for u,v in outline]+[[x,y(x)-.23,.015]])
        faces=[[10,i,(i+1)%10] for i in range(10)]
        parts[f'Shirt_{index}']=textured(trimesh.Trimesh(verts,faces,process=False),material(color=col))
    vertices=[];faces=[]
    for row in range(5):
        for col in range(5):
            x=.62+col*.105;vertices.append([x,y(x)-row*.15,0 if row==0 else .02*np.sin(col*1.8+row*.4)])
    for row in range(4):
        for col in range(4):
            a=row*5+col;faces += [[a,a+1,a+6],[a,a+6,a+5]]
    parts['FoldedTowel']=textured(trimesh.Trimesh(vertices,faces,process=False),material(color=(.54,.51,.41,1)))
    print(name,export(name,parts,'Straight poles, continuous sagging rope and folded shirts/towel; no fractured inferred strands.',True))


def fishrack():
    name='fish_drying_rack';wood=[]
    def top(z):return .82-.22*z
    for x in [-1,1]:
        for z in [-.48,.48]:wood.append(cylinder([x,0,z],[x,top(z),z],.029))
    for z in [-.5,.5]:wood.append(cylinder([-1.06,top(z),z],[1.06,top(z),z],.025))
    for x in np.linspace(-1,1,12):wood.append(cylinder([x,top(-.5),-.5],[x,top(.5),.5],.013,6))
    fish=[];spines=[]
    for x in np.linspace(-.87,.87,7):
        for z in [-.36,-.12,.12,.36]:
            y=top(z)+.024
            vertices=[[x,y,z-.095],[x-.037,y,z-.035],[x-.028,y,z+.065],[x,y+.012,z+.085],
                      [x+.028,y,z+.065],[x+.037,y,z-.035],[x,y+.02,z],[x-.027,y,z+.12],[x+.027,y,z+.12]]
            faces=[[6,i,(i+1)%6] for i in range(6)]+[[3,7,8]]
            for p in vertices:p[1]-=.22*(p[2]-z)
            fish.append(trimesh.Trimesh(vertices,faces,process=False))
            spines.append(cylinder([x,top(z-.06)+.043,z-.06],[x,top(z+.07)+.043,z+.07],.0025,5))
    parts={'BambooFrameAndSlats':textured(join(wood),material('floor_wood_planks',(.78,.77,.59,1)),3),
           'RowsOfSplitFish':textured(join(fish),material(color=(.52,.47,.35,1))),
           'FishSpines':textured(join(spines),material(color=(.35,.33,.25,1)))}
    print(name,export(name,parts,'Continuous bamboo frame/slats and 28 split drying fish; clean thin support geometry.',True))


def lamppost():
    name='lamp_post_village';pole=cylinder([0,0,0],[0,3.85,0],.065,8)
    arm=join([cylinder([0,3.78,0],[.32,3.90,0],.025,8),cylinder([.32,3.90,0],[.42,3.72,0],.025,8)])
    shade=trimesh.creation.cone(radius=.13,height=.12,sections=12)
    shade.apply_transform(trimesh.transformations.rotation_matrix(-np.pi/2,[1,0,0]));shade.apply_translation([.42,3.6,0])
    bulb=trimesh.creation.icosphere(subdivisions=1,radius=.045);bulb.apply_translation([.42,3.57,0])
    glow=material(color=(.62,.53,.34,1));glow.emissiveFactor=np.array([.4,.25,.07])
    parts={'ConcretePole':textured(pole,material('wall_plaster_old',(.69,.69,.64,1)),2),
           'JoinedMetalArm':textured(arm,material(color=(.24,.27,.25,1))),
           'TinShade':textured(shade,material('roof_tin_rusty'),2),
           'WarmBulb':textured(bulb,glow)}
    print(name,export(name,parts,'Connected bent metal arm, continuous concrete pole and tin shade; existing world lights retained.',True))


def thin():
    offering();clothesline();fishrack();lamppost()


def white():
    for name in ['wooden_bed','low_table_tea','bamboo_fence']:
        mesh=source_mesh(name);y=(mesh.triangles_center[:,1]-mesh.bounds[0,1])/mesh.extents[1]
        if name=='wooden_bed':light=(mesh.face_normals[:,1]>.65)&(y>.20)
        elif name=='low_table_tea':light=y>.68
        else:light=np.zeros(len(mesh.faces),dtype=bool)
        parts={'WornWood':painted_part(mesh,~light,material('floor_wood_planks'),3)}
        if light.any():parts['WovenMatOrCeramic']=painted_part(mesh,light,material(color=(.51,.50,.42,1)),2)
        print(name,export(name,parts,'Authored wood UV and muted mat/ceramic material; concept background cannot paint the object white.'))
    name='fishing_rod';mesh=source_mesh(name)
    part=textured(mesh,material('door_wood_old',role='HorrorBend_Wood'))
    spec=json.loads((READY/'horror_models.json').read_text())[name]
    axis=np.array(spec['axis']);anchor=np.array(spec['anchor']);v=part.vertices-anchor
    u=np.cross(axis,[0,1,0]);u=u/np.linalg.norm(u) if np.linalg.norm(u)>.01 else np.array([1,0,0])
    w=np.cross(axis,u)
    uv=np.column_stack([np.arctan2(v@w,v@u)/np.pi,(v@axis)/spec['length']*6])
    part.visual.uv=uv
    print(name,export(name,{'BendingRod':part},'Cylindrical real wood UVs; keep the existing concept shader bend interface used by Rod3D.'))


def furniture():
    name='table_stall_folding';mesh=source_mesh(name)
    y=(mesh.triangles_center[:,1]-mesh.bounds[0,1])/mesh.extents[1]
    top=y>.76
    cloth=painted_part(mesh,top,material(role='HorrorConcept_Cloth'))
    x=(cloth.vertices[:,0]-mesh.bounds[0,0])/mesh.extents[0]
    z=(cloth.vertices[:,2]-mesh.bounds[0,2])/mesh.extents[2]
    q=np.array([[86,230],[650,119],[935,270],[330,420]],dtype=float)
    pixels=(q[0]*(1-x)[:,None]+q[1]*x[:,None])*(1-z)[:,None]+(q[3]*(1-x)[:,None]+q[2]*x[:,None])*z[:,None]
    strip=np.array([[390,466],[880,343],[880,292],[390,414]],dtype=float)
    for face,n in enumerate(cloth.face_normals):
        if abs(n[1])>=.55:continue
        indices=slice(face*3,face*3+3);vertices=cloth.vertices[indices]
        axis=2 if abs(n[0])>abs(n[2]) else 0
        u=(vertices[:,axis]-mesh.bounds[0,axis])/mesh.extents[axis]
        v=np.clip(((vertices[:,1]-mesh.bounds[0,1])/mesh.extents[1]-.76)/.24,0,1)
        pixels[indices]=(strip[0]*(1-u)[:,None]+strip[1]*u[:,None])*(1-v)[:,None]+(strip[3]*(1-u)[:,None]+strip[2]*u[:,None])*v[:,None]
    cloth.visual=trimesh.visual.TextureVisuals(uv=np.column_stack([pixels[:,0]/1024,1-pixels[:,1]/1024]),
        material=trimesh.visual.material.PBRMaterial(name='HorrorUV_FloralCloth',baseColorTexture=Image.open(ROOT/f'assets/concepts/horror/{name}.png').convert('RGBA'),roughnessFactor=1.0,metallicFactor=0,doubleSided=True))
    parts={'FloralOilcloth':cloth,'RustyXLegs':painted_part(mesh,~top,material('roof_tin_rusty',(.61,.57,.48,1)),3)}
    print(name,export(name,parts,'Project only the floral tabletop quadrilateral into real UVs; rusty X-legs use aged metal UVs, never the grey background.'))

    name='thung_boat'
    # A continuous woven bowl replaces the merged paddle/inner-wall inference.
    # The separate live ThungPaddle3D is owned by the sea scene.
    # Keep ThungHull3D.FLOOR_FRACTION=.16 without changing placement code.
    profile=np.array([[0,0],[.72,0],[.95,.22],[1.05,.60],[1.04,.70],[.99,.70],[1,.60],[.91,.25],[.68,.1132],[0,.1132]])
    hull=trimesh.creation.revolve(profile,sections=24)
    hull.apply_transform(trimesh.transformations.rotation_matrix(-np.pi/2,[1,0,0]))
    rim=trimesh.creation.annulus(r_min=1.0,r_max=1.08,height=.035,sections=24)
    rim.apply_transform(trimesh.transformations.rotation_matrix(-np.pi/2,[1,0,0]));rim.apply_translation([0,.69,0])
    bands=[]
    for y,r in [(.22,.955),(.40,1.01),(.58,1.05)]:
        band=trimesh.creation.annulus(r_min=r-.01,r_max=r+.012,height=.018,sections=24)
        band.apply_transform(trimesh.transformations.rotation_matrix(-np.pi/2,[1,0,0]));band.apply_translation([0,y,0]);bands.append(band)
    weave=[]
    for angle in np.linspace(0,2*np.pi,24,endpoint=False):
        path=[np.array([r*np.cos(angle),y,r*np.sin(angle)]) for y,r in [(.03,.75),(.23,.96),(.43,1.03),(.65,1.055)]]
        weave.extend(cylinder(path[i],path[i+1],.009,5) for i in range(3))
    c=hull.triangles_center;n=hull.face_normals
    tar=(np.sum(c[:,[0,2]]*n[:,[0,2]],axis=1)>.01)|(c[:,1]<.02)
    parts={'BasketHull':painted_part(hull,~tar,material('floor_wood_planks',(.82,.75,.55,1)),2),
           'TarExterior':painted_part(hull,tar,material(color=(.18,.17,.13,1))),
           'BambooRim':textured(rim,material('floor_wood_planks',(.9,.83,.62,1)),3),
           'WovenBands':textured(join(bands+weave),material(color=(.30,.28,.19,1)),2)}
    # Circumferential UVs on the bowl remove the top-down background projection.
    v=parts['BasketHull'].vertices
    parts['BasketHull'].visual.uv=np.column_stack([np.arctan2(v[:,2],v[:,0])/np.pi*4,v[:,1]*4])
    print(name,export(name,parts,'Paddle-free basket hull with true circumferential bamboo UVs; no grey background on rim/walls. Live paddle and sea placement untouched.',True))


def other():
    for name,texture in [('shed_tin','roof_tin_rusty'),('ice_box_styrofoam',None)]:
        mesh=source_mesh(name);dims=mesh.extents
        axis=np.array([0,0,1]) if dims[2]>dims[0]*1.25 else np.array([1,0,0]);front=np.cross(axis,[0,1,0])
        keep=(mesh.face_normals@front>.65)&((mesh.triangles_center-mesh.bounds.mean(0))@front>0)
        rest=material(texture) if texture else material(color=(.59,.58,.51,1))
        parts={'ConceptFront':painted_part(mesh,keep,material(role='HorrorConcept_Front')),
               'WornSidesAndBack':painted_part(mesh,~keep,rest,3)}
        print(name,export(name,parts,'Retain signed concept-facing detail; non-front surfaces use authored worn UVs/material instead of streaked projection.'))


def houses():
    for name,wall in [('tube_house_a','plaster_shopfront'),('tube_house_b','wall_plaster_old'),('tube_house_c','blue_lime_wall')]:
        mesh=source_mesh(name);dims=mesh.extents
        if name in ['tube_house_a','tube_house_b']:
            # Inference put the facade on -X, whereas TubeHouse3D places a
            # +Z-front shell. Keep the footprint/height but face the street.
            old=mesh.vertices.copy();mesh.vertices[:,0]=old[:,2]*dims[0]/dims[2]
            mesh.vertices[:,2]=-old[:,0]*dims[2]/dims[0]
            dims=mesh.extents
        front=np.array([0,0,1]);n=mesh.face_normals;c=mesh.triangles_center
        front_mask=(n@front>.62)&((c-mesh.bounds.mean(axis=0))@front>-.03)
        roof=(n[:,1]>.4)&((c[:,1]-mesh.bounds[0,1])/dims[1]>.65)
        front_mask &= ~roof
        facade=painted_part(mesh,front_mask,material(role='HorrorConcept_Front'))
        # Project just the photographed facade, not the whole 3/4 house.
        # UVs keep the original artwork and its lettering in the front only.
        corners={'tube_house_a':[(450,990),(790,930),(795,78),(435,100)],
                 'tube_house_b':[(292,980),(609,1010),(594,140),(294,140)],
                 'tube_house_c':[(242,907),(956,837),(932,395),(247,395)]}[name]
        q=np.array(corners,dtype=float)
        s=(facade.vertices[:,0]-mesh.bounds[0,0])/dims[0]
        t=(facade.vertices[:,1]-facade.bounds[0,1])/max(facade.extents[1],1e-6)
        pixels=(q[0]*(1-s)[:,None]+q[1]*s[:,None])*(1-t)[:,None]+(q[3]*(1-s)[:,None]+q[2]*s[:,None])*t[:,None]
        uv=np.column_stack([pixels[:,0]/1024,1-pixels[:,1]/1024])
        facade.visual=trimesh.visual.TextureVisuals(uv=uv,material=trimesh.visual.material.PBRMaterial(name='HorrorUV_ConceptFront',
            baseColorTexture=Image.open(ROOT/f'assets/concepts/horror/{name}.png').convert('RGBA'),roughnessFactor=.95,metallicFactor=0,doubleSided=False))
        parts={
            'Front':facade,
            'Wall':painted_part(mesh,~front_mask&~roof,material(wall),scale=3.0),
            'Roof':painted_part(mesh,roof,material('roof_tin_rusty'),scale=4.0,roof=True)}
        print(name,export(name,parts,'Concept facade projected only onto canonical +Z front; authored UV plaster walls/back and tin roof. A/B reoriented to match the placement contract without changing footprint/height.',name!='tube_house_c'))


def cart():
    name='food_cart_glass';mesh=source_mesh(name)
    n=mesh.face_normals;c=mesh.triangles_center
    y=(c[:,1]-mesh.bounds[0,1])/mesh.extents[1]
    front=(n[:,2]>.55)&(c[:,2]>mesh.bounds.mean(axis=0)[2])
    roof=(n[:,1]>.4)&(y>.78)&~front
    wheels=(y<.16)&~front
    glass=(y>.47)&(y<.77)&~front&~roof
    panel=~front&~roof&~wheels&~glass
    parts={'Front':painted_part(mesh,front,material(role='HorrorConcept_Front')),
           'TinPanels':painted_part(mesh,panel,material('roof_tin_rusty',(.7,.73,.63,1)),2.0),
           'Roof':painted_part(mesh,roof,material('roof_tin_rusty'),3.0,True),
           'GlassBack':painted_part(mesh,glass,material(color=(.30,.38,.38,1))),
           'Wheels':painted_part(mesh,wheels,material(color=(.16,.19,.18,1)))}
    print(name,export(name,parts,'Lettering stays only on outward +Z front; UV tin sides/rear, dull glass and dark wheels.'))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--phase',choices=['houses','cart','tree','thin','white','other','furniture'],required=True)
    args=parser.parse_args()
    if args.phase=='houses':houses()
    if args.phase=='cart':cart()
    if args.phase=='tree':tree()
    if args.phase=='thin':thin()
    if args.phase=='white':white()
    if args.phase=='other':other()
    if args.phase=='furniture':furniture()


if __name__=='__main__':main()
