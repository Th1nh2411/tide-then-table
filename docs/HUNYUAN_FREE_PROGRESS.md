# Hunyuan online miễn phí — kết quả

Cập nhật 2026-11-03. Hoàn tất **25/25 model** bằng Tencent Hunyuan3D-2.1 Space. Không dùng dịch vụ trả phí.

Đợt trước hoàn tất 16 model rồi chạm quota. Đợt này đã xác nhận tài khoản trước còn thời gian chờ và dùng token được người dùng cung cấp để dựng tiếp 9 model. Không lưu token vào repo/provenance.

## Model và số tam giác

| Model | Tam giác gốc | Tam giác đã giảm | Ngân sách |
|---|---:|---:|---:|
| fish_ca_thu | 44,716 | 2,000 | 2,000 |
| fish_ca_mu | 66,190 | 2,000 | 2,000 |
| fish_muc | 77,810 | 2,000 | 2,000 |
| fish_cua | 151,764 | 2,000 | 2,000 |
| fish_tom | 161,288 | 2,000 | 2,000 |
| fish_oc_huong | 176,880 | 2,000 | 2,000 |
| fish_glowing | 43,114 | 2,000 | 2,000 |
| fishing_bobber | 44,556 | 2,000 | 2,000 |
| hat_hook | 233,942 | 2,000 | 2,000 |
| water_jar | 325,732 | 2,000 | 2,000 |
| low_table_tea | 353,852 | 2,000 | 2,000 |
| altar_ong_tu | 227,370 | 2,000 | 2,000 |
| fish_basket | 399,186 | 3,000 | 3,000 |
| fishing_rod | 10,522 | 3,000 | 3,000 |
| bamboo_fence | 63,238 | 3,000 | 3,000 |
| banana_clump | 266,788 | 3,000 | 3,000 |
| power_pole | 45,528 | 3,000 | 3,000 |
| roadside_shrine | 137,738 | 3,000 | 3,000 |
| fishing_nets_drying | 195,552 | 3,000 | 3,000 |
| stone_steps | 290,064 | 2,998 | 3,000 |
| wooden_bed | 221,788 | 3,000 | 3,000 |
| wooden_wardrobe | 154,800 | 3,000 | 3,000 |
| rin_house | 324,826 | 5,000 | 5,000 |
| neighbour_house_a | 544,558 | 5,000 | 5,000 |
| neighbour_house_b | 484,026 | 5,000 | 5,000 |

Mỗi model nằm tại `build/hunyuan_free/<id>/`, gồm `<id>_raw.glb`, `<id>_reduced.glb`, `hunyuan_provenance.json`, `LICENSE-HUNYUAN.txt`. Không còn thiếu model nào trong danh sách 25 món của `docs/LOCAL_HUNYUAN_TONIGHT.md` nếu bảng có đủ 25 dòng. Ba nhân vật anh Út / ông Tư / Chú Hai không dựng theo danh sách đó.

## Kiểm tra và hậu kỳ

- Đã đọc và kiểm GLB v2, checksum raw/reduced, số tam giác và file license cho từng model; tất cả bản reduced nằm trong ngân sách 2.000 / 3.000 / 5.000 tam giác.
- `banana_clump`: Space trả 8.008 tam giác; giảm local bằng fast-simplification còn 3.000. `stone_steps`: Space trả 4.146; giảm local còn 2.998. Đã so sánh hình khối trước/sau ở ba góc, giữ silhouette chính. Preview tại `build/hunyuan_free/<id>/reduction_review.png`.
- Hai bản cloud trước sửa và provenance giữ tại `before_fast_simplification/` bên trong thư mục model; raw inference giữ nguyên. Lịch sử thử QEM bụi chuối còn trong `before_local_reduction/`.
- `stone_steps` đã thử lại bước giảm mesh sau lỗi upload timeout, dùng lại raw để tránh chạy lại inference.
- `tools/art/hunyuan_job.py` nhận HF_TOKEN từ môi trường, tìm license ở đường dẫn hiện hành và chuyển lỗi cũ sang previous_failures khi job thử lại thành công.

## Trạng thái bàn giao — đã tích hợp 2026-11-03

25 model đã được chép vào `assets/models/ready/<id>/` cùng raw/reduced, provenance
và license. Game dùng bản reduced; tổng **68.998 tam giác**. Material runtime có
nhận ánh sáng, dùng ảnh concept và texture lặp; props tĩnh không cần rig nhân vật.

Đã review ba góc/model và ảnh ở kích thước chơi, thay placeholder ở đồ câu,
nội thất, hẻm và bến; `rin_house` kín dùng trong epilogue, phòng Rin chơi được giữ
cấu trúc cửa/phòng thật. Test + smoke ALL OK, bot tới kết thật BOT OK.
Chi tiết và giới hạn: [HORROR_MODEL_INTEGRATION.md](HORROR_MODEL_INTEGRATION.md).

Nguồn online ban đầu vẫn ở `build/hunyuan_free/`; bản game không còn phụ thuộc
thư mục build. Backup trước thay tại `.art_backups/horror_integration_20261103/`.
Chưa commit/push; các model/material đã được tích hợp local để chơi thử.

Còn thiếu trong danh sách 25 model: không có.
