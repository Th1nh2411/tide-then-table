# Art 3D — flow và pilot hiện hành

Chốt ngày 2026-10-28: gen-image → Hunyuan image-to-shape → giảm mesh/làm sạch →
material phẳng → rig/animation cho nhân vật → kiểm Godot. Không dùng Blender
cho ba pilot mới; không thay inference bằng mesh code-native tự dựng.

## Dọn trước khi triển khai

Đã archive bốn nhóm Rin study không chọn, preview, builder và render/vendor cũ:
`.art_backups/art_studies_20261028_143130/` (local, ignored by Git và Godot).
`manifest.json` ghi từng đường dẫn gốc, kích thước và SHA-256; snapshot các plan
trước dọn nằm trong `documents/`. Di chuyển lại theo manifest để khôi phục.
Không xóa dữ liệu khỏi máy. Đã kiểm hash sau di chuyển.

Giữ portrait/sprite approved, gameplay, PersonRig3D, mẫu quán PSX, Hunyuan trial,
`tools/mesh/add_glb_normals.py`. Concept Rin chuyển sang `assets/concepts/rin/`.
Lịch sử tài liệu cũ: `docs/archive/ART_STUDIES_20261028.md`.

## Ba pilot

| Pilot | Phạm vi | Tiêu chí |
|---|---|---|
| Rin | Hunyuan shape đã tạo, palette từ concept, rig/skin và Idle/Walk/Carry | Cao ~1.84 m; giữ API đi/bưng/giơ tay/cần câu; kiểm vai/gối và nhiều góc |
| Bàn + ghế đẩu | Gen từng vật riêng, Hunyuan, giảm mesh/material, ráp wrapper | Bàn 1.5×1.2 m cao .86 m; ghế .55×.55 m cao .52 m; giữ marker/collider/logic |
| Thuyền thúng | Gen/Hunyuan hull, material gọn, thay visual | Đường kính ~2.4 m; giữ BoatVisual, đèn, actor, controller, collider và cinematic |

Chỉ chỉnh renderer khi đã có mesh cụ thể để review; backup file active trước
khi thay. Lưu input, prompt, output gốc, tham số, license/checksum cùng artifact.
Không để license chặn demo theo chỉ đạo người dùng. Không phát sinh dịch vụ trả phí.

## Kiểm tra và mở rộng

Mỗi pilot cần ảnh trước/ngang/sau, cỡ gameplay và kiểm import; nhân vật cần kiểm
skin thực sự biến dạng theo animation. Kiểm regression quán/biển/cutscene theo
phạm vi tích hợp, luôn dùng `-- --no-autosave` để giữ save thật.
Sau ba pilot mới mở rộng Bảo/Vy/Cô Năm/khách và các nhóm prop khác theo ASSETS.md.
