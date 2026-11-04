# Xóm Đèn — bản horror 3D

Trạng thái nhánh `try-horror-1st`, cập nhật 2026-11-03. Thiết kế: `PLAN.md` §10.
Bản mô tả 3D trước khi chuyển sang horror được giữ ở
[archive/3D_DEMO_try3d_20261103.md](archive/3D_DEMO_try3d_20261103.md).

## Chạy và vòng chơi

F5 trong Godot mở menu chính. Chơi mới bắt đầu trong phòng Rin trên map làng liền:
phòng → mở cửa → xóm bến → hẻm → phố quán. Ra biển đêm là cảnh riêng.

- WASD đi / chèo, chuột nhìn, E tương tác. Đến phố lần đầu thì ca quán mở.
- Ở quán: lấy món ở bàn kê, đem tới bàn khách, dọn bàn; thùng bia dùng E.
- Hết ca: không có điềm thì ra biển câu ít nhất ba con; có điềm thì về ngủ.
- Câu: chuột trái quăng, bấm lúc phao chìm để móc, giữ để kéo / thả để chùng.
  Cá lên tay: nhìn giỏ rồi E bỏ vào. Cần cong và dây đổi màu theo lực căng.
- Về bến xuất hiện ở cầu tàu ban đêm; về giường ngủ để phán đêm và sang sáng.
- Sai thì lịch về mùng 9; sổ tay vẫn nhớ. Đêm rằm có trà gừng của anh Út và các kết.
- Esc: tạm dừng / cài đặt. F8 debug đổi PS1 look; F10 debug so góc nhìn game cũ.
  Phím đầy đủ và độ nhạy chuột nằm trong Cài đặt.

HUD quán chỉ hiện trong ca, không còn hiện ngày/giờ quán khi Rin vừa tỉnh ở nhà.
Autosave chỉ ở buổi sáng; mọi test/bot dùng `-- --no-autosave`.

## Scene và hệ thống hiện hành

| Phần | File / lớp |
|---|---|
| Map liền | `scenes/village3d/village_scene_3d.tscn`, `VillageLayout3D`, `VillageBuilder3D` |
| Phòng / cửa | `BedroomBuilder3D`, `VillageHouse3D`, `VillageDoor3D`, `VillageSpots3D` |
| Hẻm | `VillageLaneBuilder3D` |
| Sáng / ca / đêm | `VillageLighting3D`; trong nhà dùng ambient tối hơn |
| Vòng ngày | `VillageDay3D`, `LoopCalendar`, `OmenPicker` |
| Phục vụ | `RestaurantScene3D`, `RestaurantService3D`, `RestaurantSeating3D` |
| Biển / câu | `scenes/sea3d/sea_scene_3d.tscn`, `Fishing3D`, `Rod3D`, `FishBasket3D` |
| Điềm / kết | `scenes/omens3d/`, `scenes/ram3d/`, `RamNight` |
| Góc nhìn / PS1 | `FirstPersonView3D`, `PsxLook3D` |
| NPC | `PsxCharacterVisual`; gói PSX đã có rig, không thay bằng concept anh Út / ông Tư / Chú Hai |

## 25 model horror đã tích hợp — đợt đầu

Model inference và provenance ở `assets/models/ready/<id>/`; bản dùng là `<id>_reduced.glb`.
Bản gốc `<id>_raw.glb` và license được giữ cùng thư mục. Bản reduced có thêm normals
để nhận ánh sáng; vertices/tam giác giữ nguyên so với nguồn online. Tổng bản reduced: **68.998 tam giác**.

- Cá: `fish_ca_thu`, `fish_ca_mu`, `fish_muc`, `fish_cua`, `fish_tom`, `fish_oc_huong`,
  `fish_glowing`; cùng một renderer cho cá trên tay, trong giỏ và mâm cá ở quán.
- Đồ câu: `fish_basket`, `fishing_rod`, `fishing_bobber`. Cần dùng mesh thật với shader
  uốn cong; đầu dây đi theo đầu cần. Cá dị biến có glow nhẹ.
- Nội thất: `wooden_bed`, `wooden_wardrobe`, `low_table_tea`, `altar_ong_tu`, `hat_hook`;
  `water_jar` đặt cạnh cửa nhà.
- Đường làng / bến: `bamboo_fence`, `banana_clump`, `power_pole`, `roadside_shrine`,
  `fishing_nets_drying`, `stone_steps`, `neighbour_house_a`, `neighbour_house_b`.
- `rin_house` là nhà kín dùng trong epilogue; nhà Rin trên map chơi vẫn là vỏ kiến trúc
  có phòng, cửa và collider thật để đi vào được. Không đặt mesh nhà kín chặn lối này.

`ConceptModel3D` tô màu từ ảnh concept bằng shader có nhận ánh sáng. Mái / mặt bên nhà
và tủ dùng texture lặp để giảm kéo sọc. Đây là material runtime, không phải bộ UV/PBR
bake riêng từ dịch vụ online. Các đạo cụ tĩnh không cần rig nhân vật.

Metadata tỷ lệ, trục dài và crop nguồn nằm ở `assets/models/ready/horror_models.json`;
`horror_models.gd` chứa cùng dữ liệu để preload và đóng gói được trong bản export.
Cá/cần được căn theo trục dài; nhà và đồ nội thất được đặt vừa bố cục/collider hiện có.

Ảnh nhiều góc, ảnh ở kích thước chơi, backup và giới hạn:
[HORROR_MODEL_INTEGRATION.md](HORROR_MODEL_INTEGRATION.md).

## Kiểm thử và review

```bash
bash tools/run_tests.sh
bash tools/run_bot.sh
```

Đã chạy bộ test + smoke và bot tới kết thật. `horror_models_test` kiểm 25 model import,
chiều cao / bám đất, cá trên tay, độ cong cần, HUD trong/ngoài ca và lối đi hẻm.

Tạo lại ảnh review bằng Godot có renderer (không dùng `--headless`):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --rendering-method gl_compatibility --script res://tools/art/review_horror_models.gd -- --no-autosave
/Applications/Godot.app/Contents/MacOS/Godot --path . --rendering-method gl_compatibility res://tools/art/capture_horror_integration.tscn -- --no-autosave
```

Ảnh làm việc ở `build/horror_integration/`, ảnh bàn giao ở `docs/art_reviews/`.

## Brief 5 — 25 model mới, 04/11/2026

Đã dựng đủ 25 concept của brief 4 bằng Hunyuan, thêm vào metadata (tổng 50 ID).
Đợt mới **74.761 tam giác**, tổng hai đợt **143.759**. Có raw/reduced,
provenance và license theo từng ID. Kết quả Space vượt budget được giảm tiếp
bằng CPU; nhà C dùng mesh gốc Hunyuan rồi giảm bằng CPU do export Space lỗi mạng.

Đĩa cá/tô canh/tháp bia trên tay Rin và Vy, món trên bàn khách, khay ở bàn kê và
ly cạnh tháp bia đã dùng model mới. Mâm cúng bình thường dùng
`altar_tray_offerings`; mâm bị ăn dở vẫn giữ model/state riêng và dấu chân ướt.
Furniture bàn, chồng ghế, xe, lò, thùng xốp mới chỉ bàn giao asset; chưa thay
visual quán. Prop ngoài làng do builder hiện hành tự nhận khi model có sẵn.

Chi tiết, số tam giác, giới hạn material và ảnh review:
[HORROR_CODEX_DELIVERY_5.md](HORROR_CODEX_DELIVERY_5.md).
Source raw/reduced đã nằm trong `assets/`, không còn chỉ tồn tại trong `build/`.

Cây bàng có sửa hình học sau inference: giữ bồn, dựng lại thân/cành/lá 3D theo concept;
recipe và nguồn Blender được lưu, chi tiết trong provenance `artist_repair`.
