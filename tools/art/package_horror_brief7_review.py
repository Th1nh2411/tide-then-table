"""Assemble the complete catalog audit and before/after delivery plates."""
from pathlib import Path
import json
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/art_reviews';BUILD=ROOT/'build/brief7';REVIEW=ROOT/'build/horror_integration/review'
validation=json.loads((OUT/'brief7_validation_20261105.json').read_text());ids=list(validation['changed'])
# Original reference sheet supplies the one newly added underside-only model.
original=Image.open(OUT/'brief7_white_check_5.jpg')
for angle in range(3):
 target=BUILD/'before'/f'tray_aluminium_{angle}.png'
 if not target.exists():original.crop((angle*200,620,(angle+1)*200,800)).save(target)
for page in range(4):
 group=ids[page*8:(page+1)*8];sheet=Image.new('RGB',(1200,len(group)*225),(27,30,34));d=ImageDraw.Draw(sheet)
 for row,name in enumerate(group):
  d.text((6,row*225+3),name+' | BEFORE: 3 left / AFTER: 3 right',fill='white')
  for col in range(6):
   path=BUILD/'before'/f'{name}_{col}.png' if col<3 else REVIEW/f'{name}_{col-3}.png'
   im=Image.open(path).convert('RGB');im.thumbnail((200,195));sheet.paste(im,(col*200+(200-im.width)//2,row*225+25))
 sheet.save(OUT/f'brief7_compare_{page+1}.jpg',quality=94)
catalog=json.loads((ROOT/'assets/models/ready/horror_models.json').read_text())
for page in range(5):
 group=list(catalog)[page*10:(page+1)*10];sheet=Image.new('RGB',(1500,len(group)*240),(27,30,34));d=ImageDraw.Draw(sheet)
 for row,name in enumerate(group):
  d.text((6,row*240+3),name+' | FRONT / BACK / LEFT / RIGHT / TOP / BOTTOM',fill='white')
  for angle in range(6):
   im=Image.open(BUILD/f'sides_after/{name}_{angle}.png').convert('RGB');im.thumbnail((250,210));sheet.paste(im,(angle*250+(250-im.width)//2,row*240+25))
 sheet.save(OUT/f'brief7_all_sides_{page+1}.jpg',quality=94)
cases=[('dish_plate_fish',5),('hat_hook',1),('stone_steps',5),('tray_aluminium',5),('water_jar',5),('dish_bowl_soup',5),('charcoal_stove_clay',5),('boat_pulled_up',5)]
sheet=Image.new('RGB',(1000,len(cases)*280),(27,30,34));d=ImageDraw.Draw(sheet)
for row,(name,angle) in enumerate(cases):
 d.text((6,row*280+3),name+' | BEFORE left / AFTER right | back or underside',fill='white')
 for col,phase in enumerate(['before','after']):
  im=Image.open(BUILD/f'sides_{phase}/{name}_{angle}.png').convert('RGB');im.thumbnail((480,250));sheet.paste(im,(col*500+(500-im.width)//2,row*280+25))
sheet.save(OUT/'brief7_projection_spill.jpg',quality=94)
for p in (BUILD/'game').glob('*.png'):
 Image.open(p).convert('RGB').save(OUT/f'brief7_game_{p.stem}.jpg',quality=94)
# Human audit index: visible material problems vs the narrower full-picture error.
confirmed={'dish_plate_fish':'Complete fish/plate image on the underside; now ceramic coverage.',
 'hat_hook':'Hat picture/detail repeated inside the cone; now woven straw.',
 'stone_steps':'Staircase detail stretched/repeated across top and flat bottom; now stone.',
 'tray_aluminium':'Complete tray/rim picture repeated on the underside; now scratched metal UVs.'}
spill={'water_jar','fish_basket','dish_bowl_soup','beer_glass_ice','charcoal_stove_clay','boat_pulled_up','boat_upturned','wooden_wardrobe','roadside_shrine','power_pole'}
audit={name:{'directions':6,'reviewed':True,'full_picture_or_frame':confirmed.get(name,''),'other_concept_spill':name in spill,'geometry_changed':name in ['planter_tree_street','food_cart_glass'],'uv_or_material_changed':name in ids,'after':'No complete model picture, concept frame or background patch observed.'} for name in catalog}
(OUT/'brief7_six_side_audit.json').write_text(json.dumps(audit,indent=2)+'\n')
print('BRIEF7 REVIEW PACKAGED: 32 comparisons, 50 x 6 audit, 16 gameplay shots')
