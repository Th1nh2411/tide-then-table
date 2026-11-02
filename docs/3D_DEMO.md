# Xóm Đèn — bản 3D (nhánh `try-3d`)

Tài liệu tra cứu trạng thái **hiện tại** của bản 3D: chơi thế nào, nằm ở file nào,
chỉnh ở đâu. Việc còn lại: `PLAN.md` → "Việc còn lại". Art: `ART_PLAN.md`,
`docs/ART_PIPELINE.md`, `ASSETS.md`.

## Chạy

- **F5** trong Godot → menu chính (nhãn "3D"). Chơi mới: intro → biển 3D; Tiếp tục
  dùng điểm resume trong save. Menu, intro và rest card chuyển thẳng sang scene 3D.
- Biển: `scenes/sea3d/sea_scene_3d.tscn`. Quán: `scenes/restaurant3d/restaurant_scene_3d.tscn`.
- Minigame (câu, lưới, nướng, rót bia), hội thoại, điện thoại, khoang, Guide, HelpPanel
  dùng chung với bản 2D. Hướng dẫn: Esc → Hướng dẫn.
- Kiểm thử/bot luôn chạy với `-- --no-autosave` (xem "Kiểm thử").

## Vòng chơi

1. **Biển:** lái thuyền, câu ở đàn cá, thả lưới, ghé POI, về bến (E dỡ cá vào kho,
   R về nhà ngủ, F sửa thuyền). J điện thoại, M bản đồ lớn; ghim bản đồ có chỉ dẫn.
2. **Nghỉ:** thẻ sáng (mẻ cá, thời tiết, món mới) → quán.
3. **Trước ca:** Rin đi tự do. E ở bảng THỰC ĐƠN (hoặc nút Thực đơn) mở `MenuPanel3D`
   (ô món có ảnh/giá/HOT/số phần, phím 1-9, Q tự xếp, Esc đóng; chỉ món đã biết và bếp
   nấu được; nút Mua ở Cô Năm, Sửa quán, Mở cửa, Ra khơi khi hết hàng). E ở Cô Năm mua
   rau/bia, E ở tủ lạnh cất túi đồ. Sửa quán luôn có khi chưa phục vụ.
4. **Phục vụ:** Bảo tự nấu món thường; E ở bàn kê lấy đĩa, E ở bàn có đơn để đặt; E ở lò
   nướng / thùng bia làm món thủ công; E cạnh bàn bẩn để dọn.
5. **Hết ca:** nút Đóng sớm (bấm hai lần) hoặc T ngừng nhận khách, phục vụ nốt. Hoá đơn
   hiện một lần; sau đó Rin vẫn đi lại, có nút Sửa quán và Ra khơi. Đồ nghề biển và
   nhân viên trong điện thoại (J).

## Biển

- **Script:** `sea_scene_3d.gd` chỉ điều phối; dựng cảnh `SeaWorldBuilder3D`, địa điểm và
  sự kiện đêm `SeaPlaces3D`, câu/lưới/khoang `SeaCatch3D`, HUD/chỉ dẫn `SeaHud3D`
  (+ `SeaHudView3D`). Scene giữ các hàm bọc cũ (`_try_fish`, `_visit_poi`...) cho test/bot.
- **Bố cục:** `SeaLayout3D` dùng đúng bố cục 2D (160x107 đơn vị, 12 px/đơn vị: gần bờ,
  rạn, khơi, sương, bến, miếu, chòi, hải đăng, bè, xoáy, đá). Bản đồ điện thoại và ghim
  dùng tọa độ 2D.
- **Đàn cá:** `SeaShoals3D` sinh mỗi đêm (số đàn theo vùng, độ sâu, cá nổi bật, bóng lớn,
  giới hạn `max_depth`). Không phao/mũi tên: chỉ **bọt khí** (`BubbleSpot3D`) trong tầm
  đèn (co lại khi cạn dầu), nhiều cá nhiều bọt. Số cá trong minigame = số cá còn lại của
  đàn (tối đa 6); mỗi lượt đàn mất 1 con, hết thì bọt tan.
- **Quăng cần:** giảm tốc rồi E → `CastCinematic3D` (~1,5 s, khóa input, phím bất kỳ để
  tua; Rin chạy clip `Cast`, cần bám cổ tay) → camera cúi xuống nước, ripple-wipe sang
  minigame 2D; xong thì wipe ngược. Tab mở khoang giữa trận (trận câu tạm dừng); choáng
  giữ giữa các lượt, bất tỉnh → cứu về bến. Chờ nhả phím rồi mới trả lái.
- **Đá ngầm:** 12 viên `SubmergedRock3D`, collider luôn có, đá + bọt chỉ hiện trong tầm đèn.
  Sương mở thì có mây trôi (`SeaFog3D`). F2 (debug) mở sương.
- **Thoại:** câu đầu đêm như 2D (cá hư, NEO chào, món HOT, sương); câu được cá thu phát
  sáng thì NEO báo `[WARN]`. Lời Rin/NEO trên dải giấy (`SpeechStrip`) góc dưới trái,
  xếp hàng, mỗi câu chờ câu trước. Rin ở biển không đội nón.
- **Thuyền thúng chèo** (`BoatData.rowed`, logic `RowStroke`): giữ W/S/A/D thì chèo từng
  nhịp; mỗi nhịp `stroke_seconds` chỉ đẩy trong khúc kéo nước (pha 0,15–0,6), cộng đúng
  `stroke_push`; nhịp đã bắt đầu luôn chèo hết, rồi trôi chậm dần theo `glide_drag`.
  A/D chèo một bên, xoay `stroke_turn` mỗi nhịp; S chèo lùi yếu hơn. Ghe chèo/ghe máy lái
  kiểu cũ. Thông số: `data/boats/thuyen_thung.tres`. Rin đứng mạn phải chạy clip `Row`
  theo pha nhịp; mái chèo đặt qua hai bàn tay mỗi khung hình.
- **Camera:** offset theo thuyền `CAMERA_OFFSET` (0, 6.2, 8.4), FOV 56° (`sea_scene_3d.tscn`),
  bám theo hàm mũ (không phụ thuộc FPS).
- **Mặt nước:** `SeaWater3D` (một plane chia lưới ~0,8 m ở `WATER_Y` 0,1) +
  `sea_water.gdshader` procedural: ba sóng dài nhấp nhô, gợn nhỏ bẻ normal, đường gợn
  sáng (thay vạch box cũ), màu vùng khơi → rạn → gần bờ (+ sương) chuyển mềm theo
  `SeaLayout3D`, bọt ở chỗ vật cắt mặt nước (đá, cầu tàu, bờ; đọc depth), vòng nước quanh
  thúng + bóng dưới thuyền tự vẽ (decal không in lên nước trong suốt), ánh trăng lấp lánh
  theo hướng `DirectionalLight3D`. Màu và độ cao sóng là uniform của shader. Nước bị khoét
  trong lòng thân thuyền (`hull_hole`); bóng + vòng bọt xoay theo thuyền, ghe dài hơn thúng.
- **Nền trời + đảo xa:** `SeaBackdrop3D`: panorama `assets/textures/sea3d/night_sky_panorama_v1.png`
  (xoay `sky_rotation` để trăng vẽ trùng hướng đèn trăng; `fog_sky_affect` 0,25), ba dải
  silhouette `distant_islands_night_v1.png` ở bắc / đông / tây (unshaded, không sương).
  Camera biển `far` 300 để thấy đảo.
- **Va chạm địa điểm:** Miếu Cá Ông, hải đăng Đá Canh Đêm, Gò Vỏ Ốc có collider ẩn đúng hình
  model ở mặt nước (`_solid_footprint`: bao lồi các đỉnh thấp hơn `FOOTPRINT_TOP` 1,2 m,
  dựng thành lăng trụ; mái hiên không tính); thuyền vẫn vào được tầm ghé 4 m.

## Quán

- **Script:** `restaurant_scene_3d.gd` điều phối; dựng phòng `RestaurantRoomBuilder3D`
  (đèn: `_lighting()` / `_shop_light()`), vị trí `RestaurantLayout3D`, phục vụ
  `RestaurantService3D`, ngồi `RestaurantSeating3D`, khách + xe máy `CustomerTraffic3D`,
  nhân viên `RestaurantCrew3D` (+ `StaffPathing3D`), HUD `RestaurantHud3D`, bảng
  `RestaurantPanels3D`, mục tiêu `RestaurantGoals3D`, social `RestaurantSocial3D`.
- **Bố cục:** bàn xoay dọc (`TABLE_YAW`), bốn bàn đầu trước xe/tủ quán (hai cột × hai
  hàng); hai ghế mỗi bàn ở X ±0,95 nên **hai khách ngồi đối diện qua chiều rộng**. Mỗi bàn
  một order/bill; điểm phục vụ ở cạnh trước (`TABLE_SERVICE_OFFSET` Z+1,25). Collider và
  A* theo `TABLE_COLLISION_SIZE` / `TABLE_NAV_SIZE`; helper `table_offset()`. Bảo đứng mép
  trái xe bếp, Cô Năm mép trái quầy; bảng thực đơn cạnh lối vào.
- **Mặt bằng:** nâng cấp `seats` hiện tên "Mặt bằng" (450k/1.200k, 4 → 6 → 8 bàn, giữ ID
  save). Gian chưa thuê là vỉa hè công cộng bình thường (không rào, đi qua được); mỗi cấp
  thêm 2 bàn ở gian bên trái và cập nhật A*. Hủy preview không trừ tiền. Ô xanh xem trước:
  `RestaurantLease3D.preview`. Cây vỉa hè và cột đèn dây đứng ở mép vỉa hè
  (`RestaurantLayout3D.CURB_PROP_Z`), không dưới lòng đường.
- **Sửa quán:** `RenovationPreview3D` xem trước bàn/gian thuê, trang trí (đèn lồng, chậu
  cây), bếp (xe đẩy cấp 0–2) và tủ lạnh (cấp 0–2) dạng bóng mờ; Xác nhận mới giữ.
- **Khách ngồi:** SitDown → SitIdle → StandUp đúng ghế (clip tạo lúc chạy,
  `SeatedAnimation3D`); hủy lượt lúc đang ngồi vẫn đứng dậy rời đi và trả chỗ đậu xe.
- **Bảng thực đơn ngoài quán:** `WorldMenuBoard3D` hiện ảnh + tên món đã chọn và món bán
  kèm, cập nhật qua `MenuPlan.changed`; SubViewport chỉ vẽ lại khi thực đơn đổi.
- **Ít chữ trong thế giới:** không còn nhãn nổi trên bàn/bếp; chỉ phím "E" khi đứng đúng
  chỗ (`RestaurantPrompt3D`) và hai bảng hiệu thật ("HẢI SẢN XÓM ĐÈN", "TẠP HOÁ CÔ NĂM").
  Việc kế tiếp nhấp nháy vàng ấm (`TargetPulse3D`, chọn bởi `RestaurantGoal3D`): bàn đang
  bưng tới → bàn kê có món → lò nướng → thùng bia → bàn bẩn → (trước ca) bảng thực đơn.
  Chỉnh `strength` (0,4) / `period` (1,4 s).
- **Ghế và ánh sáng:** ghế nhựa runtime 85% (`WorldPresentation3D.RESTAURANT_STOOL_SCALE`,
  mặt ghế cao ~0,44), collider theo mesh. Ánh nền xanh xám, ánh chính ấm từ phố, sáu đèn
  rọi bàn/bếp/quầy có bóng; Forward+ thêm SSAO, Compatibility dùng bóng thật. Người, mèo,
  bàn ghế, prop đổ bóng; sàn chỉ nhận bóng. Bóng tiếp đất mềm `ContactShadow3D`
  (`STRENGTH` 0,45) dưới người, mèo, bàn ghế, thuyền.
- **Camera:** `RestaurantCamera3D` orthographic `VIEW_SIZE` 12, `OFFSET`, vùng chết nhỏ
  quanh Rin, giới hạn trong quán; nhường camera khi cutscene chạy.

## Nhân vật & animation

- **Rig:** `PersonRig3D` dùng chung cho gameplay và cutscene (đi, bưng đĩa, emote = biểu
  tượng). Rin: `assets/models/ready/rin/rin_pilot.glb` (base `rin_pilot2`, 62 xương, các
  clip `CharacterArmature|*` gốc + `Carry`, `CarryWalk`, `Cast`, `Faint`, `Row`; dùng
  `Idle`, `Walk`, `Run`, `Roll` gốc). 11 người batch: 20 xương, `Idle` / `Walk` / `Carry`.
  Mèo: không rig, chỉ bob/sway.
- **Tốc độ** (`restaurant_scene_3d.gd`): `walk_speed` 1,8, `carry_speed` 1,6 m/s (gần nhịp
  clip Walk nên chân khớp nền; trên ~2,25 m/s chuyển Run). Shift = lăn
  (`CharacterArmature|Roll`): `roll_seconds` 0,6, `roll_speed` 4,0, `roll_cooldown` 0,8.
  Khách 1,1 m/s (`CustomerTraffic3D.WALK_SPEED`), nhân viên ~0,9–1,6 m/s (tốc độ trong
  `data/staff/` chia `RestaurantCrew3D.STAFF_UNITS_PER_METRE`). Nhịp Sóng bù thời gian riêng cho Rin.
- **Bám đất:** nhịp chân theo **quãng đường thật** (`GroundGait3D` đo tốc độ chân trụ của
  clip, cache theo resource); đụng tường thì dừng chân. `GroundFootPlant3D` giữ điểm tiếp
  đất (IK hai xương), nhả khi nhấc chân/đổi trạng thái/quá xa. NPC bưng đĩa dùng
  `GroundCarryWalk` tạo trong RAM (chân Walk + tay Carry). Đường A* được rút gọn theo tầm
  nhìn có kiểm clearance, tăng/giảm tốc, xoay mềm, cache theo đích.
- **Va chạm người:** mọi `PersonRig3D` trừ Rin và mèo có `StaticBody3D` capsule
  (`PersonBlocker`, r 0,24) nên Rin không đi xuyên Bảo, Cô Năm, khách, nhân viên; tắt khi
  người đó bị ẩn (ghế trống, cutscene). Rig chỉ về Idle khi cả physics frame lẫn idle frame
  đều không còn đẩy nó (cutscene đi bằng tween idle, gameplay bằng physics).
- **Góc nhìn thứ nhất thử (F10, debug):** `FirstPersonView3D` đặt camera ở mắt Rin, chuột
  xoay (Alt hoặc mở bảng = hiện con trỏ). Quán: thành `demo_camera` nên WASD đi theo hướng
  nhìn, E vẫn theo khoảng cách. Biển: nhìn xoay theo thúng, đèn thuyền thành đèn cầm tay
  rọi theo hướng nhìn, cột đèn ẩn. Thân Rin ẩn khỏi camera này (layer 20) nhưng vẫn đổ
  bóng. Cutscene và cảnh quăng cần trả lại camera game. Tắt là trả lại như cũ.
- **PSX thử (F8, debug):** `PsxLook3D` vẽ thế giới 3D thẳng ở `pixel_res` 640x360 bằng
  SubViewport theo camera game, phóng nearest dưới UI; material thường thành
  `psx_vertex.gdshader` (rung đỉnh `snap_res` 320x180, texture nearest). Tắt là trả lại như cũ.
- **Bưng đĩa:** đĩa theo vị trí hai cổ tay (Rin và NPC). Hướng cần câu (`hand_basis`) tính
  so với tư thế Idle vì rest pose pilot2 là T-pose.

## Cutscene

- `StoryBridge3D` chạy cutscene `.tres` có sẵn với `CutsceneStage3D`: marker trong
  `CutsceneMarkers3D`, actor đi bộ, camera, emote, `rain`, `slow`, `remove`, `tint dawn`
  (nhuộm thế giới 3D, không nhuộm UI).
- Actor rin/bao/vy/co_nam/guest/cat dựng bằng `PersonRig3D`; nhân vật gameplay cùng loại bị
  ẩn trong cảnh và hiện lại khi hết (Rin trên thuyền cũng thuộc `person_rin`, diễn viên
  đứng đúng độ cao sàn thuyền).
- `rin_faint` = model Rin chạy clip `Faint` (khuỵu gối, ngả ra sau, nằm gọn trong thúng;
  `Faint`, `Death`, `Cast` không loop). Dùng ở `wave_faint` và nhánh dự phòng của `fog_omen`.
- Kiểm marker: `story3d_stage_test`.

## UI, font, theme

- **Phong cách "đồ thật ngoài phố":** bảng hiệu đỏ + đèn tuýp (menu chính, tạm dừng),
  bảng phấn khung gỗ (lên món, hướng dẫn), thẻ giấy (món, ghi chú, lời thoại), quầy gỗ +
  thùng các-tông + thẻ giá (Cô Năm), giấy da xé (lời dẫn), bảng tên giấy vàng (thoại).
- **Theme:** nine-patch trong `assets/sprites/ui/frames/` (placeholder vẽ bằng code); thay
  bằng art cùng tên rồi chạy lại `tools/ui/build_game_theme.gd`. Chọn chất liệu bằng
  `theme_type_variation` (`PaperPanel`, `ChalkPanel`, `WoodPanel`, `SignPanel`,
  `CardboardPanel`, `PhoneScreen`, `SignButton`, `PaperButton`...; danh sách đầu file builder).
- **Font:** Paytone One (tiêu đề), Be Vietnam Pro (chữ thường), VT323 (NEO, số kiểu máy)
  trong `assets/fonts/` (OFL). Chưa chốt — ảnh so sánh `build/shot/fontcmp/`.
- **Ít chữ:** icon `UiIcons` (sticker từ game-icons.net, `assets/icons/CREDITS.md`; art thật
  `assets/sprites/ui/icons/<id>.png` tự thay), chấm `PipBar`, biểu đồ `MiniChart`, hiệu ứng
  `UiFx` (pop, nghiêng khi rê chuột, giấy trượt vào, đóng dấu). Chữ đầy đủ nằm ở tooltip.
- **HUD quán:** ván gỗ trên-trái (lịch + ngày, đồng hồ, trạng thái ca, tiền đếm lên), thẻ
  giấy dưới nó (khách, bỏ về, thu, chợ, sao); phiếu order treo dây (`TicketRail3D` +
  `OrderTicket3D`: số bàn, hình món, kiên nhẫn xanh→đỏ, lửa = Rin nướng, bia, ✓, rung khi
  sắp bỏ về); ghi chú nhiệm vụ = mẩu giấy ghim, ẩn khi mở bảng.
- **HUD biển:** ván gỗ (thuyền, giờ, tiền; dầu, thân thuyền, khoang, 2 lưới), phím E/R +
  icon góc dưới phải, đêm đầu có thẻ phím góc phải.
- **Điện thoại:** khung máy thật (viền, camera, thanh trạng thái), tab là icon ở thanh dưới;
  các tab Kho/Menu/Dex/Thuyền/Sổ sách/Nâng cấp/Nhân viên là thẻ app (Dex lưới ảnh, "?"
  cho loài chưa gặp). Tab Bản đồ chưa theo phong cách mới.
- **Hoá đơn hết ca:** `ShiftReceipt3D` + `ShiftReceiptRows` in từng dòng, tiền đếm lên,
  biểu đồ 7 ngày, con dấu sao. Không chặn input.
- **Màn khác:** khoang = thùng gỗ ướt (biển % đầy, khay "cá mới", đĩa Bỏ/Bán, dấu "ĐẦY!"),
  gợi ý lần đầu = thẻ giấy ghim, thẻ cá mới = ảnh dán + sticker NEW!, màn sáng = trang
  vở, địa điểm = tờ giấy ghim + phím số, kết thúc = mẩu báo + dấu "CÒN TIẾP", khung
  nấu = ván gỗ, khung câu = thùng gỗ.
- **Art UI cần vẽ:** `docs/UI_ART_BRIEF_CODEX.md` + `docs/ui_art_needed_{menus,goals,social,hud,misc}.md`.

## Mục tiêu: thử thách, thành tựu, Review, xếp hạng

Chỉ có ở quán 3D (`ShiftCloser` 2D chưa nối).

- **Thử thách ngày:** lúc mở cửa `DailyChallenges` chọn 3 trong 8 mẫu `data/challenges/`
  (seed theo ngày, chỉ mẫu làm được: nướng khi có món nướng, bia khi đã bán bia, HOT khi
  món HOT có trên thực đơn). Lưu ở flags `challenge_day` / `challenge_ids`. Thẻ giấy
  `ChallengeCard3D` (icon + thanh + "2/5" + tick, câu đủ ở tooltip); NEO báo khi xong,
  thưởng trả lúc hết ca (một lần/ngày). Guide lần đầu: `challenges3d`.
- **Thành tựu:** 11 mẫu `data/achievements/`, so với `GameState.stats` (đếm cả đời, có lưu)
  lúc hết ca; mở = flag `ach_<id>`, thưởng một lần, toast `AchievementToast`. Tab "Thành
  tựu" trong điện thoại (`PhoneAchievements`).
- **Icon:** `GoalIcons.icon(id)` đọc `assets/sprites/ui/icons/<id>.png` (16x16), huy hiệu
  `ui/badges/<id>.png` (24x24); thiếu thì placeholder.
- **Xóm Đèn Review:** hết ca `XomDenReview` (`systems/social/`) cho 2–4 khách đăng bài:
  avatar + tên (`data/social/review_pool.tres`), ảnh món, sao (theo kiên nhẫn còn lại,
  −1 món ôi < 50, +1 món HOT), câu ≤ 6 chữ theo tâm trạng, lượt thích. Luôn có bàn tốt
  nhất và, nếu có khách bỏ về, một bài bực. Cùng seed → cùng bài.
- **Follower + hạng quán:** theo sao, lượt thích, HOT, thử thách, khách bỏ về
  (`data/social/social_tuning.tres`). 4 hạng: Quán vỉa hè → Quán quen (40) → Quán có tiếng
  (120) → Quán nổi tiếng (300); lên hạng = thưởng + toast + NEO, khách tới nhanh hơn chút
  (`tier_spawn_scale`, `RestaurantSocial3D.spawn_scale()`). Không tụt hạng. Lưu ở
  `GameState.social` (followers, tier, 20 bài mới nhất).
- **Xếp hạng tuần:** `RivalRanking` so tổng 7 ngày của Rin (`day_history`) với 3 quán bịa
  (`data/social/rivals/`: Ốc Thâm Lam, Lẩu Bến Gió, Nướng Chú Hên; doanh thu theo đường
  cong cố định). Lần đầu vượt: flag `rival_beat_<id>`, thưởng, NEO.
- **Tab "Review"** (`PhoneReview`): thanh tiêu đề follower, huy hiệu hạng + thanh tới hạng
  sau, nút bài đăng / xếp hạng; bài = thẻ giấy, xếp hạng = sticker "#3", cột 4 quán,
  biểu đồ tiền mỗi ngày. Kiểu dáng gom ở `SocialStyle`.
- **Lúc hết ca:** góc phải hiện sticker "+12" follower và tối đa 3 bài mới (tự ẩn, không chặn).
- **Dữ liệu cho bảng điểm:** `ShiftLog` (`host.shift_log`, reset khi mở ca) ghi từng món/bàn/
  khách bỏ về; `host.shift_results` có `challenges`, `achievements`, `bonus`, `social`
  (`followers_before/after`, `tier_before/after`, `reward`, `posts`), `rank`
  (`rank_before/after`, `beaten`, `reward`, `board`).

## Kiểm thử

- `tools/run_tests.sh`: mọi `scenes/test/*_test.tscn` (cả 2D và 3D), smoke biển/quán 3D và
  các `scenes/restaurant3d/*check.tscn` (`restaurant_flow_check`, `traffic_check`).
- `tools/run_bot.sh`: bot 3D (`tools/bot/game_bot_3d.tscn`) chạy nhiều ngày tới ending, mua
  nâng cấp (mặc định ưu tiên thuyền; `POLICY=balanced` ưu tiên bếp), kiểm save/load trên
  save tạm. Bot dịch chuyển nhanh và cho minigame thắng có chủ đích: **kiểm tích hợp,
  không đo độ khó**.
- Test 3D chính: `game3d_loop_test` (vòng liên cảnh + save), `fishing3d_inventory_test`
  (pause lồng nhau, choáng, ngất), `cast_cinematic_3d_test`, `sea3d_parity_test`,
  `sea3d_hazards_test`, `thung_rowing_test`, `story3d_stage_test`, `menu_panel_3d_test`,
  `receipt_test`, `challenges_test`, `social_test`; `restaurant_flow_check` (nấu → phục
  vụ → trả tiền → dọn, Đóng sớm, chống thanh toán trùng, thuê Vy, ShiftLog → thưởng).
- Kiểm chạy tay (không nằm trong runner): `scenes/test/ground_motion_check`,
  `world_presentation_check`, `world_composition_check`, `restaurant_lease_check`,
  `restaurant_seating_check` (`.tscn`).

## Công cụ art & scene review

- Flow model và cách rebuild batch: `docs/ART_PIPELINE.md`. Nguồn `assets/models/batch/`,
  thành phẩm `assets/models/ready/<id>/<id>.glb` (+ provenance).
- **Không chạy lại** `build_rin_pilot.py` hay builder Walk/Blender cũ để ghi đè Rin: bản
  hiện hành là `rin_pilot2` + tóc/kính/màu + clip tay, patch thẳng trên GLB
  (`assets/models/ready/rin/provenance.json`). Script dựng các bước đó nằm ngoài repo.
- Tool trong `tools/art/`: `make_rin_faint.py`, `make_rin_row.py` (chạy bằng
  `/usr/bin/python3`, cần numpy), `recolor_cat_portrait.py`, mắt
  `match_character_eyes_to_rin.py` (Bảo: `match_bao_eyes_to_rin.py`), tóc
  `follow_manual_hair.py` (chạy trước bước mắt), `refine_character_faces.py` (nhận ra bản
  tô tay, chỉ sửa mắt), Walk hẹp `narrow_character_walk.py` + `check_lateral_walk.py`.
  Chạy lại bước mắt không chồng thêm mắt. Bản tô tay Bảo/Vy/Cô Năm là nguồn ưu tiên.
- Scene review (F6, trong `scenes/art_pilots/`): `rin_pilot_preview` (1 đứng, 2 Walk, 3 bưng,
  5 ném cần), `rin_pilot2_compare`, `character_faces_review` (1 trước, 2/6 nghiêng, 3 toàn
  thân, 4/5 Walk), `ground_motion_review`, `world_scale_lighting_review` và
  `world_composition_review` (chụp ảnh, chạy với `--no-autosave`).
- Giới hạn còn lại: mèo chưa đi bốn chân / chưa sọc vằn; tủ lạnh cấp 2 mặt trước kín;
  chưa rig mặt/ngón tay, mắt tĩnh; model màu phẳng, chưa texture chi tiết; Rin chưa có
  FishingIdle/Reel.
