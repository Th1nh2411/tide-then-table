# Horror brief 5 — trạng thái bàn giao

Ngày 03/11/2026. **Mục 0 hoàn tất. Mục 1 dừng ở quota theo yêu cầu brief; mục 2 chờ model.** Không có model mới nào được dựng thành công trong đợt này (0/25), không thêm primitive giả thay cho kết quả Hunyuan.

## 0. Chốt brief 4

- `b8be0c4` — 25 concept, 5 texture, sidecar, review, thoại nháp, ASSETS.
- `2ab0f64` — bỏ nền trắng của bốn concept/projection, provenance, fixture aim ổn định và sửa hình ghế bị chiếu lên tường nhà. Không sửa builder WORLD hay làm colour pass của STYLE.
- Bốn model trắng: đã xem 3 góc/model, [12 góc review](art_reviews/brief4_projection_whitefix_20261103.jpg). Ba nhà: [9 góc review](art_reviews/house_material_fix_20261103.jpg).
- `tools/run_tests.sh` → **ALL OK**, exit 0 (`build/brief5/tests0.log`).
- Bot lượt đầu hết giới hạn chờ cảnh khi waking; giữ log `bot0.log` để theo dõi, không coi là pass. Bổ sung chẩn đoán frame/paused/tween trong bot, không nới timeout hay đổi runtime wake. Chạy lại → **BOT OK**, tới true ending (`bot0_retry.log`); xác nhận cuối → **BOT OK** (`bot_final.log`). Hiện tượng timeout lượt đầu chưa tái hiện ở hai lượt sau, chưa khẳng định đã tìm được nguyên nhân riêng của lượt này.

## 1. Space từ chối job đầu tiên — đã dừng

Dùng `tools/art/hunyuan_job.py`, client 1.3.0, Space Tencent Hunyuan3D-2.1, anonymous (phiên không có HF_TOKEN). Input `dish_plate_fish.png`, budget 2.000, 20 steps, octree 192, seed 1234. Lỗi chính xác:

> You have exceeded your ZeroGPU quota (90s requested vs. 86s left). Try again in 0:53:44.

Không có raw hoặc reduced trả về. Không submit thêm ID, không đổi tài khoản để kéo quota. Log và provenance failed giữ ở `build/brief5/dish_plate_fish.log`, `build/brief5/generated/dish_plate_fish/hunyuan_provenance.json`. Thời gian trong thông báo là tại lúc gọi, không phải ETA cập nhật.

**Còn lại toàn bộ 25 ID** để chạy Windows local. Manifest máy đọc: [horror_brief5_models.json](../tools/art/horror_brief5_models.json).

| Budget tam giác/model | Số ID | Còn chờ |
|---|---|---|
| 2000 | 5 | `dish_plate_fish`, `dish_bowl_soup`, `beer_glass_ice`, `tray_aluminium`, `buoy_pile` |
| 3000 | 17 | `beer_tower`, `table_stall_folding`, `stool_plastic_stack`, `charcoal_stove_clay`, `food_cart_glass`, `ice_box_styrofoam`, `altar_tray_offerings`, `lamp_post_village`, `coconut_palm`, `motorbike_cub`, `fish_drying_rack`, `clothesline`, `boat_pulled_up`, `thung_boat`, `shed_tin`, `boat_upturned`, `planter_tree_street` |
| 5000 | 3 | `tube_house_a`, `tube_house_b`, `tube_house_c` |

Trần tổng của đợt mới: **76.000 tam giác** (5×2.000 + 17×3.000 + 3×5.000), không phải số đo mesh. Tam giác mới thực đo: chưa có. 25 model đợt đầu vẫn **68.998**; không thay mesh cũ. Chưa có ảnh review 3 góc cho model mới vì không có mesh, không dùng concept thay ảnh render.

### Batch Windows đã chuẩn bị

[stage_horror_brief5.py](../tools/art/stage_horror_brief5.py) dùng Python stdlib, không network/inference, copy ảnh pending theo ba nhóm và sinh `run_pending.ps1`. Script sinh ra dùng tool local hiện có, tuần tự; retry riêng một lần mỗi ID lỗi, kiểm hash/status trước khi kết luận xong. Xử lý riêng trường hợp nhóm chỉ còn một ảnh để output không rơi vào sai thư mục.

Đã chạy stage tại Mac, kiểm đủ 25 ID không trùng, copy ảnh giữ nguyên byte và thử nhánh nhận diện output đã xong bằng `fish_ca_thu`. Chưa chạy PowerShell/Hunyuan CPU trên Windows từ máy Mac này. Hướng dẫn tiếp tục: [LOCAL_HUNYUAN_TONIGHT.md](LOCAL_HUNYUAN_TONIGHT.md). Stage local nằm dưới `build/hunyuan_brief5/`, sinh lại được trên Windows; không commit bản copy tạm.

Sau khi có mesh: kiểm finite geometry và budget từng model, normals, license, raw/reduced hash; merge metadata vào hai file horror_models thay vì ghi đè ID cũ; xem 3 góc từng model trước khi ghi số đo vào integration doc. Không sửa colour/material của STYLE trong bước dựng mesh.

## 2. Tích hợp chờ kết quả model

Chưa đổi visual game sang ID mới khi chưa có mesh để import/kiểm kích thước. Không sửa các builder WORLD, HUD hay màu props của STYLE. Các điểm nối đã xác định:

| Phần | Điểm hiện tại | Cách nối sau review |
|---|---|---|
| Đồ Rin/Vy cầm | `person_rig_3d.gd` tạo plate bằng box; `restaurant_service_3d.gd.sync_food_visuals`, `vy_staff_3d.gd` chọn bia | Dùng helper visual món tại attachment plate, giữ anchors tay. Món `canh_chua_ca_thu` dùng bowl, món cá dùng plate; instant_serve dùng tower. Đồng bộ cả Rin và Vy. |
| Món chờ/bàn khách | `RestaurantRoomBuilder3D.plate_model` tạo placeholder; service sync visibility | Thay child visual trong service khi sync lần đầu để không sửa shell/street builder. Thêm tray ở bàn kê, glass bên tower trên bàn khách; giữ order/dirty/ready logic và collider. |
| Mâm cúng | `omens3d/omen_offering_3d.gd` hiện đã dùng hai model cũ normal/eaten | Model mới `altar_tray_offerings` chỉ thay normal sau review; giữ eaten model riêng, dấu chân ướt và đèn theo đúng state. Không dùng mâm còn đầy cho state eaten. |

### Furniture để sau khi STYLE merge

- `table_stall_folding`: thay visual của bàn, giữ cao mặt bàn/vị trí plate, ghế, lối đi và collider.
- `stool_plastic_stack`: asset là **chồng 4 ghế**, đặt như prop dự trữ; không dùng nguyên chồng làm một ghế khách đang ngồi.
- `food_cart_glass`: thay visual xe, giữ marker bếp/lấy món và tên BẢO; không thêm text/brand khác.
- `charcoal_stove_clay`: thay visual lò, giữ điểm tương tác và mặt đặt cá; theo scope sau STYLE merge, không khôi phục cơ chế grill đã bỏ.
- `ice_box_styrofoam`: thay visual thùng, giữ điểm tương tác/collider.

Các prop ngoài làng nằm trong scope WORLD và chỉ được agent đó dùng tự động khi model ready. Chưa tạo model, chưa thêm metadata hay gọi chúng từ scene. Không có merge WORLD/STYLE trong đợt bàn giao này.

## Kiểm tra và commit cuối

Chỉ thêm batch staging/manifest và tài liệu sau bước 0; không có thay đổi runtime mới. `git diff --check` sạch. Không push. Giới hạn còn lại là quota và mesh chưa có; phần dựng/3-view/tam giác/tích hợp 25 model **chưa hoàn tất**.
