# Horror build: Codex brief 7 (white / pale patches on the other models)

Same rules as earlier briefs. Fresh 3-view render of all 50 catalog models (`tools/art/review_horror_models.gd`
at `7b9d0f6`): [sheet 1](art_reviews/brief7_white_check_1.jpg), [2](art_reviews/brief7_white_check_2.jpg),
[3](art_reviews/brief7_white_check_3.jpg), [4](art_reviews/brief7_white_check_4.jpg),
[5](art_reviews/brief7_white_check_5.jpg). Many models still show flat pale white / lavender areas where the
projection has no real colour (back, underside, ends, thin parts). It looks like the concept's light
background or an unpainted area being sampled. Treat it like brief 6 (own UVs / tiled material on the faces
the concept doesn't cover), or fix it once in the projection if one cause covers most of them.

## 1. Models with clear patches (worst first)

| Model | Where |
|---|---|
| `charcoal_stove_clay` | grill rim and most of the body |
| `boat_upturned`, `boat_pulled_up` | keel / ends / inner hull |
| `coconut_palm` | trunk and half the fronds |
| `fish_cua`, `fish_tom`, `fish_muc`, `fish_oc_huong`, `fish_ca_mu`, `fish_glowing` | claws, bodies, heads / tails, fins (these are held in Rin's hand, seen close) |
| `fishing_bobber` | whole stick + top |
| `hat_hook` | the hat's inside and the hook |
| `stone_steps` | top and sides |
| `wooden_bed` | the mattress is flat white (should be a worn chiếu / mat) |
| `ice_box_styrofoam` | only the front is painted; sides / lid plain white (styrofoam is white, but give it dirt, tape, stains) |
| `motorbike_cub` | front fork, underside |
| `water_jar`, `fish_basket`, `wooden_wardrobe`, `shed_tin` | bottoms / feet |
| `banana_clump` | stems |
| `buoy_pile`, `altar_ong_tu`, `beer_tower`, `beer_glass_ice`, `dish_bowl_soup`, `dish_plate_fish`, `food_cart_glass` | rims, bases, wheels, candles, glass panel |
| `roadside_shrine`, `power_pole` | vertical streaks on the pillar (stretch, like the old house sides) |

Clean, leave them: altar_tray_offerings, bamboo_fence, clothesline, fish_drying_rack, fishing_nets_drying,
fishing_rod, lamp_post_village, low_table_tea, neighbour_house_a/b, rin_house, stool_plastic_stack,
table_stall_folding, thung_boat, tray_aluminium, tube_house_a/b/c, fish_ca_thu.

## 2. Also from the brief-6 game shots

- `planter_tree_street` still reads as a thin pine / antenna: a street bàng has a short thick trunk and
  2-4 wide flat tiers of dense big leaves, crown wider than tall-ish, not small tufts on a pole.
- `food_cart_glass`: the glass case is a pale solid block; show glass (dark, slightly see-through or
  reflective look) with food / bowls inside.
- Several street houses share one model and so the same "TIỆM MAY M…" sign. Give the tube houses 2-3 sign
  variants (invented names, rural, e.g. tạp hoá, sửa xe, tiệm thuốc bắc) or a sign-free variant, chosen
  per instance (tell me the hook; placement code is ours).

## 2b. Picture-in-picture (added by the user)

Some models show, on one of their faces, the concept picture itself: a small copy of the whole model
(and its background) painted onto the surface, like a photo stuck on the object, instead of the material.
Likely causes: the projection frame is bigger than / offset from the mesh, flat bases, plinths, lids or
backs facing the projection, or a face that takes the full concept frame. Check every one of the 50
models from all sides (not only the 3 review angles: also top, bottom, back) for any face that shows a
mini drawing of the model, the concept's background colour or its frame edge, and fix those (own UVs /
tiled material, or tighten the projection). List in the delivery which models had it.

## 3. Done when

The same 3-view sheet shows no flat white / lavender regions on any model in table 1, plus an in-game shot
of the fish in hand, the stove, the boats on the beach and the palm. Budgets and StyleGuide unchanged.
`tools/run_tests.sh` ALL OK, `tools/run_bot.sh` BOT OK, commit, report in
`docs/HORROR_CODEX_DELIVERY_7.md` with before / after. `-- --no-autosave`, `git checkout project.godot`
after `--import`, no push.
