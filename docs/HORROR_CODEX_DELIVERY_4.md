# Horror brief 4 — bàn giao

Thực hiện theo thứ tự 0 → 4, ngày 03/11/2026. Asset mới là bản concept/texture và thoại nháp; chưa đưa vào builder, scene hay model mới.

## 0. Hoàn tất phần đang dở

Đã fetch và merge `origin/try-horror-1st` (Already up to date), giữ thay đổi paper/notebook/subtitles/Vy và cả nội dung PLAN hiện hành.

Bot kẹt vì chuyển về Village khi fade xong nhưng `NightmareWake3D` vẫn đang `waking`. Bot phục vụ quá sớm rồi gửi tương tác ra biển trong lúc input bị khóa. `GameBot3D.ready_to_drive()` nay đợi quyền điều khiển; regression trong `ghost_visit_test.gd` kiểm tra cả trước và sau khi thức dậy. Không phải lỗi dây câu hay âm thanh.

Hai commit theo yêu cầu:

- `0710cd0` — models, code, docs và sửa bot.
- `de6de0a` — giảm nền ambience/noise.

Kiểm tra trước hai commit: `build/horror_integration/brief4_tests0_final.log` → **ALL OK**; `brief4_bot0_final.log` → **BOT OK**, có “waiting for control after reset” rồi “control restored”, đi tới true ending. Kiểm tra cuối đợt ghi ở cuối tài liệu này. Không push.

Lượt kiểm tra cuối phát hiện test aim đôi lúc lấy bầy cá ngẫu nhiên sát biên độ sâu: cú ném xa bị clamp hợp lệ, khiến assertion khoảng cách sai. Fixture `fishing3d_test._check_aim()` nay dùng điểm nước cố định và hướng song song bờ; vẫn kiểm tra cả cast_min và cast_max, không sửa luật ném runtime.

## 1. Bỏ nền trắng khỏi projection

Bốn concept `bamboo_fence`, `power_pole`, `roadside_shrine`, `fishing_nets_drying` giữ tên và 1024², chuyển RGBA. Cắt màu nền trung tính theo màu biên; giữ RGB nguồn. Shader đọc alpha và dùng sample phía trong hoặc màu fallback khi sample là nền. Không cắt lỗ mesh theo alpha. Provenance phân biệt SHA nguồn inference gốc với SHA concept dùng material hiện tại.

Backup trước sửa: `.art_backups/brief4_projection_20261103/manifest.json` (PNG, sidecar, shader, provenance). Đã xem đủ **12 góc**, không còn dải nền trắng/halo; mặt khuất vẫn dùng fallback đơn giản, chưa phải UV/PBR bake.

[Review 3 góc × 4 model](art_reviews/brief4_projection_whitefix_20261103.jpg).

## 2–3. Asset mới

Mỗi PNG có sidecar cùng tên: prompt thực tế, built-in `image_gen`, ngày, nguồn, kích thước native/delivered, hậu kỳ, SHA-256. Không dùng nhãn hiệu thật. Xe máy không logo; xe đồ ăn chỉ “BẢO”; nhà B dùng tên hư cấu “TIỆM MÂY MUỐI”. Concept nền xám opaque, trọn vật thể, chưa chạy image-to-3D cho 25 asset mới.

#1–25 nằm trong `assets/concepts/horror/`; #26–30 nằm trong `assets/textures/horror/`.

| # | ID | PNG bàn giao |
|---|---|---|
| 1 | `dish_plate_fish` | 1024×1024 RGB |
| 2 | `dish_bowl_soup` | 1024×1024 RGB |
| 3 | `beer_tower` | 1024×1024 RGB |
| 4 | `beer_glass_ice` | 1024×1024 RGB |
| 5 | `tray_aluminium` | 1024×1024 RGB |
| 6 | `table_stall_folding` | 1024×1024 RGB |
| 7 | `stool_plastic_stack` | 1024×1024 RGB |
| 8 | `charcoal_stove_clay` | 1024×1024 RGB |
| 9 | `food_cart_glass` | 1024×1024 RGB |
| 10 | `ice_box_styrofoam` | 1024×1024 RGB |
| 11 | `altar_tray_offerings` | 1024×1024 RGB |
| 12 | `lamp_post_village` | 1024×1024 RGB |
| 13 | `coconut_palm` | 1024×1024 RGB |
| 14 | `motorbike_cub` | 1024×1024 RGB |
| 15 | `fish_drying_rack` | 1024×1024 RGB |
| 16 | `clothesline` | 1024×1024 RGB |
| 17 | `boat_pulled_up` | 1024×1024 RGB |
| 18 | `thung_boat` | 1024×1024 RGB |
| 19 | `tube_house_a` | 1024×1024 RGB |
| 20 | `tube_house_b` | 1024×1024 RGB |
| 21 | `tube_house_c` | 1024×1024 RGB |
| 22 | `shed_tin` | 1024×1024 RGB |
| 23 | `boat_upturned` | 1024×1024 RGB |
| 24 | `buoy_pile` | 1024×1024 RGB |
| 25 | `planter_tree_street` | 1024×1024 RGB |
| 26 | `sky_dusk_pano` | 2048×1024 RGB |
| 27 | `village_far_strip` | 2048×512 RGBA |
| 28 | `sand_packed` | 512×512 RGB |
| 29 | `plaster_shopfront` | 512×512 RGB |
| 30 | `street_tiles_worn` | 512×512 RGB |

[Review 25 concept](art_reviews/brief4_concepts_20261103.jpg) · [Review 5 texture](art_reviews/brief4_textures_20261103.jpg) · [Texture lặp và mép panorama/strip](art_reviews/brief4_texture_repeats_20261103.jpg).

Đã xem riêng chồng đúng 4 ghế, nhà A hai tầng, chữ BẢO, cửa shed có ổ khóa. Khay cúng được edit bỏ đèn dầu thừa; bản trước edit được giữ ở `.art_backups/brief4_drafts_20261103/assets/concepts/horror/altar_tray_offerings.png`. Texture lặp được xem 2×2, panorama/strip xem hai bản cạnh nhau. Strip giữ alpha thật (0–255), chỉ loại hạt alpha≤1 rồi cắt lề trong suốt trước resize; không cắt silhouette. Panorama là nền trời, không thêm địa danh. Các bề mặt có họa tiết lặp nhìn thấy được ở diện tích lớn; người dựng cảnh cần đặt scale theo kích thước vật thể.

## 4. Thoại

[HORROR_TEXTS_DRAFT_2.md](HORROR_TEXTS_DRAFT_2.md): **35 câu ngày + 9 biến thể ông Tám + 6 cue = 50 hàng**. Có đánh dấu CLUE/OMEN, điều kiện không phát nhầm điềm, Út chỉ có mặt ca bình thường, chú Hai để lại giấy khi đã mất tích. U1/U2 lặp đúng nguyên văn; U3 gọi Rin là Tư; U4 không có người nói/voice. Không thêm lời kể Rin hay giải thích luật chơi. Chưa nối runtime.

## Kiểm tra bàn giao

- `tools/run_tests.sh` → **ALL OK**, exit 0; log `build/brief4/tests_final.log`.
- `tools/run_bot.sh` → **BOT OK**, exit 0; log `build/brief4/bot_final.log`. Chạy sau khi test hoàn tất để tránh import/cache đồng thời.
- 30/30 PNG đúng kích thước/mode, sidecar khớp SHA; strip alpha có cả 0 và 255. Bảng kết quả giữ tại [asset validation](art_reviews/brief4_asset_validation_20261103.json).
- Hash backup mục 1 khớp manifest; 35 hàng ngày đủ 7 ngày cho từng nhân vật; 9 ID reset khớp catalog; 6 cue và cặp lặp nguyên văn đủ.
- `git diff --check` sạch. Thay đổi mục 1–4 và fixture test nằm trong working tree để review; hai commit mục 0 đã tạo như trên.

### Chốt brief 4 khi bắt đầu brief 5

Chạy lại test và bot tại `build/brief5/tests0.log` / `bot0.log` trước khi commit phần còn lại. Bao gồm sửa ảnh ghế bị chiếu lên tường: ba nhà dùng texture bề mặt cho cả mặt trước/sau; review tại `art_reviews/house_material_fix_20261103.jpg`. Không thay mesh hay builder.
