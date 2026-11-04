# Horror brief 5 — bàn giao 04/11/2026

**Đủ 25/25 model mới**, tổng **74,761 tam giác**. Metadata giữ nguyên 25 ID cũ, thêm 25 ID mới (50 ID, tổng hai đợt 143,759 tam giác). Đã nối food/drink và mâm cúng theo scope brief. Furniture quán chưa thay; còn việc hoàn thiện material/UV như ghi bên dưới.

## 0. Brief 4 đã commit

- `b8be0c4`: concepts, textures, sidecar, review và thoại nháp.
- `2ab0f64`: bỏ nền trắng của 4 model/projection, sửa ghế bị chiếu lên tường nhà, fixture aim ổn định và log chờ wake của bot.
- `e7bbaed`: ghi lần dừng quota anonymous và chuẩn bị batch Windows. Sau đó người dùng cho phép dùng hai token đã gửi để tiếp tục.

Đã xem 12 góc của bốn model trắng và 9 góc nhà. Backup giữ trong `.art_backups/brief4_projection_20261103/` và `.art_backups/house_material_20261103/`.

## 1. Dựng, giảm mặt và kiểm model

Dùng `tools/art/hunyuan_job.py`, Tencent Hunyuan3D-2.1 Space miễn phí với HF_TOKEN. Đã dùng cả hai token theo chỉ dẫn; không ghi giá trị token vào repo hay log. Lượt anonymous ngày 03/11 bị quota không đại diện cho quota của hai tài khoản. Ngày 04/11, token thứ nhất đến quota khi dựng nhà C; token thứ hai hoàn tất các ID còn lại và các lượt sửa hình. Không dùng dịch vụ trả phí.

Mỗi ID trong `assets/models/ready/<id>/` có raw, reduced, provenance và license. Raw là mesh Hunyuan. Space đôi lúc xuất bản reduced vượt ngân sách: `prepare_horror_models.py` giảm thêm bằng CPU/fast-simplification, giữ bản Space trong build và ghi source/runtime hash cùng số mặt trước/sau. Nhà C đã có raw hợp lệ nhưng export Space lỗi kết nối hai lần, nên dùng CPU giảm trực tiếp raw xuống 5.000 mặt; việc này ghi trong `reduction` của provenance.

Tool staging hỗ trợ `--manifest` / `--ids`, merge metadata thay vì ghi đè catalog cũ. Sửa normal thiếu/zero bằng hướng mặt kề, giữ vị trí/index khi chỉ sửa normal; nếu decimate thì ghi rõ geometry đã đổi. Backup trước overwrite tại `.art_backups/horror_prepare/` (manifest SHA) và `.art_backups/brief5_inference_retry_20261104/` (các bản bị loại).

Cây bàng bị suy ra thành tấm phẳng ở cả hai lượt (seed 1234 và 5678). Đã giữ bồn Hunyuan, dựng lại thân/cành có thể tích và lá polygon gấp theo concept bằng `tools/art/repair_horror_planter_tree.py`. Nguồn chỉnh sửa: `art_source/horror/planter_tree_street_repair.blend`; raw vẫn là inference gốc. Phần sửa hình học được ghi riêng trong `artist_repair`, không coi là mesh Hunyuan nguyên dạng. Ly bia đã dựng lại với seed 5678 / 30 steps / octree 256 sau bản đầu bị hình chóp. Concept PNG giữ nguyên.

Client nay lưu remote shape reference trước khi tải, cho phép resume download mà không gọi lại GPU; retry tải file và timeout mạng 120 giây. `--direct-space` nối đúng backend chính thức khi Hub runtime lookup gặp timeout. Model input/seed và hash vẫn ghi provenance, cùng provider gốc.

| ID | Trần tam giác | Runtime | Bản giảm ban đầu* |
|---|---:|---:|---:|
| `dish_plate_fish` | 2,000 | 2,000 | 5,818 |
| `dish_bowl_soup` | 2,000 | 2,000 | 2,000 |
| `beer_glass_ice` | 2,000 | 2,000 | 2,000 |
| `tray_aluminium` | 2,000 | 2,000 | 2,000 |
| `buoy_pile` | 2,000 | 2,000 | 2,000 |
| `beer_tower` | 3,000 | 3,000 | 3,000 |
| `table_stall_folding` | 3,000 | 3,000 | 3,000 |
| `stool_plastic_stack` | 3,000 | 3,000 | 3,000 |
| `charcoal_stove_clay` | 3,000 | 3,000 | 3,000 |
| `food_cart_glass` | 3,000 | 3,000 | 3,000 |
| `ice_box_styrofoam` | 3,000 | 3,000 | 3,000 |
| `altar_tray_offerings` | 3,000 | 3,000 | 3,000 |
| `lamp_post_village` | 3,000 | 3,000 | 3,000 |
| `coconut_palm` | 3,000 | 2,998 | 5,338 |
| `motorbike_cub` | 3,000 | 3,000 | 3,000 |
| `fish_drying_rack` | 3,000 | 3,000 | 3,000 |
| `clothesline` | 3,000 | 3,000 | 3,000 |
| `boat_pulled_up` | 3,000 | 3,000 | 3,000 |
| `thung_boat` | 3,000 | 3,000 | 3,000 |
| `shed_tin` | 3,000 | 3,000 | 3,000 |
| `boat_upturned` | 3,000 | 3,000 | 3,000 |
| `planter_tree_street` | 3,000 | 1,763 | 1,763 |
| `tube_house_a` | 5,000 | 5,000 | 5,000 |
| `tube_house_b` | 5,000 | 5,000 | 5,000 |
| `tube_house_c` | 5,000 | 5,000 | 5,000 |

*Cột cuối là bản Space export trước khi ép budget; riêng nhà C là bản CPU giảm từ raw, cây bàng là bản sửa hình học trước khi chuẩn hoá normal. Không phải số mặt của raw dense. Manifest budget: `tools/art/horror_brief5_models.json`. [Hash và số đo](art_reviews/brief5_model_validation_20261104.json). Tổng runtime 74,761, thấp hơn trần 76.000.

### Review 3 góc/model (75 ảnh)

- [Nhóm 1](art_reviews/brief5_models_1_20261104.jpg)
- [Nhóm 2](art_reviews/brief5_models_2_20261104.jpg)
- [Nhóm 3](art_reviews/brief5_models_3_20261104.jpg)
- [Nhóm 4](art_reviews/brief5_models_4_20261104.jpg)
- [Nhóm 5](art_reviews/brief5_models_5_20261104.jpg)

Tool `review_horror_models.gd` đọc catalog hiện hành, dùng SubViewport để capture không bị đứng khi cửa sổ mất focus; không thay renderer game.

Giới hạn còn lại: đây là model prototype tô màu bằng concept projection, chưa UV/PBR bake. Mặt bên các tube house kéo texture thành vệt; chữ BẢO trên mặt sau xe đẩy bị chiếu ngược. Mâm cúng và các chi tiết mảnh còn thô. Các việc sửa UV/material thuộc pass STYLE; chưa coi art approved. Không sửa shader/material/placement của các agent khác trong đợt này.

## 2. Food/drink và mâm cúng

`ServedFoodVisual3D` giữ attachment có sẵn, cache mesh theo variant và dùng chung cho Rin, Vy, món chờ/bàn khách:

- `canh_chua_ca_thu` → `dish_bowl_soup`; món khác dùng `dish_plate_fish` làm visual chung.
- `instant_serve` → `beer_tower`; thêm `beer_glass_ice` trên bàn khách.
- `tray_aluminium` đặt dưới món ở bàn kê; không đổi điểm tương tác, order hay collider.
- Bàn bẩn giữ món vừa ăn cho tới khi dọn. Các lần sync không sinh lại mesh.
- Mâm cúng bình thường dùng `altar_tray_offerings`; state eaten vẫn dùng `offering_tray_eaten`, giữ dấu chân ướt và chỉ bật đèn khi normal.

Không sửa shell/street ends, village/home/sea builders hoặc HUD. Builder WORLD hiện hành tự dùng model ngoài làng khi file sẵn.

Review tỷ lệ với rig Rin và bàn mẫu: [đĩa cá](art_reviews/brief5_serving_dish_plate_fish_20261104.png), [tô canh](art_reviews/brief5_serving_dish_bowl_soup_20261104.png), [bia](art_reviews/brief5_serving_beer_tower_20261104.png). Đây là scene review, không phải ảnh gameplay của một ca đang chạy. Tool: `tools/art/review_served_food.tscn`.

### Furniture bàn giao, để pass tiếp theo

| ID | Cách thay visual sau pass STYLE |
|---|---|
| `table_stall_folding` | Giữ mặt bàn, vị trí plate, collider, ghế và lối đi; chỉ thay mesh. |
| `stool_plastic_stack` | Prop chồng 4 ghế dự trữ; không thay một ghế khách bằng cả chồng. |
| `food_cart_glass` | Giữ bếp/pass marker và tương tác; sửa UV chữ mặt sau trước khi dùng. |
| `charcoal_stove_clay` | Thay hình lò, giữ marker/collider; không khôi phục cơ chế grill đã bỏ. |
| `ice_box_styrofoam` | Thay mesh thùng, giữ điểm tương tác/collider. |

Không còn ID chờ generation. Tool Windows `stage_horror_brief5.py` xác nhận **0 pending**; vẫn giữ để rebuild/resume khi cần.

## Kiểm tra

- Hash raw/reduced/input, license, số tam giác theo budget, vertex/normal hữu hạn và normal đơn vị: đủ 25; metadata cũ không đổi.
- `tools/run_tests.sh`: **ALL OK**, log `build/brief5/tests_final_all25.log` (đủ catalog 50 ID).
- Sau các lượt sửa art cuối: chạy lại `horror_models_test` và bot; kết quả ghi trong phần chốt bên dưới.
- HTTP retry/file reference được kiểm bằng server local: lỗi 503 lần đầu, tải lại thành công, không gọi inference.
- Source PNG approved và sprite không đổi. `project.godot` khôi phục sau import, không push.

### Chốt sau sửa art

`model_test_final.log` → **HORROR MODELS TEST PASS**; `bot_final.log` → **BOT OK**, qua reset và true ending. Log nằm trong `build/brief5/`. `review_final.log` render đủ 50 model × 3 góc; 75 góc của đợt mới đã được xem, gồm cây/ly sửa cuối. Validator giữ hash/budget/normals đủ 25, tổng 74.761; staging Windows xác nhận 0 pending. Recipe và Blender source của cây được lưu cùng commit. Whitespace code/docs sạch; license upstream giữ nguyên byte.
