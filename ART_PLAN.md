# Kế hoạch art với PixelLab MCP

Viết cho phiên Claude Code mới (đã nạp tool PixelLab) và cho chủ dự án. Đọc kèm `ASSETS.md` (tên file, kích thước,
bảng màu, giới hạn màu) và `CLAUDE.md` (cách game nạp art: `Art`, F7, `tools/pixelize.py`).

## Trạng thái

- PixelLab MCP đã cài cho dự án này (`claude mcp list` → pixellab ✔ Connected). Tài liệu tool:
  https://api.pixellab.ai/mcp/docs. Tool chạy **bất đồng bộ**: tạo → nhận id → `get_*` lấy kết quả (URL ảnh) →
  `curl` tải về.
- Bảng màu "Xóm Đèn" 37 màu: `assets/palette/xom_den.hex` (mỗi dòng RRGGBB). Ảnh mẫu màu: `xom_den.png`.
- Game tự dùng PNG nào có trong `assets/sprites/` (thiếu thì vẽ hình tạm). F7 (bản debug) xem cả game bằng bảng màu.
- Bước 1 + 2 xong (2026-10-13), **chờ duyệt**: `characters/rin.png`, `portraits/rin.png`, `fish/muc.png`.
  Ảnh chụp trong game: `build/shots/` (không commit).
- Gói trial: tối đa **1 job cùng lúc** (animate từng hướng một: `directions=["south"]`, rồi north, west với
  cùng `animation_group_id`). Đã dùng 26/40 lượt.
- Bài học bước 2:
  - `create_image_pro` ở đúng cỡ game (64x64, 40x20) đẹp hơn hẳn pixflux + thu nhỏ; cỡ ≤ 42 px cho 64 ứng viên.
    Tốn 10 lượt mỗi lần → dùng cho chân dung + hải sản, chọn nhiều thứ trong một lần nếu được.
  - `create_image_pixflux` cho con mực kém (2 lần, hình lạ) → bỏ cho hải sản.
  - `create_character` size 48 → người cao ~53 px, thu về 32 px thì mờ chi tiết mặt nhưng vẫn đọc được (nón lá,
    áo xanh). Muốn nét hơn: thử `size` ~30 để khỏi thu nhỏ.
  - Ứng viên mực khác màu (#39 xanh, #63 trắng phát sáng) có thể dùng cho cá dị biến.

## Bước 1 — `tools/pixellab_import.py`

Đã có. `character <zip> <tên> [--walk walk] [--busy <anim>]` (zip tải từ `get_character` → "download"),
`image <png> <loại/tên> --size WxH [--max-colors N] [--center]` (ảnh đã đúng cỡ thì giữ 1:1, chỉ ép màu).

Chuyển file PixelLab tải về thành đúng file game cần:

- **Nhân vật:** PixelLab cho từng hướng south / north / west / east (+ khung animation). Game cần **1 sheet 4 cột**,
  khung 16x32, hàng: 1 đi xuống (= south), 2 đi lên (= north), 3 đi sang trái (= west; phải game tự lật),
  4 (tuỳ chọn) đang bận. Cột 1 = đứng yên, cột 1–4 = bước đi. Nhân vật PixelLab chỉ chiếm ~60% chiều cao khung:
  cắt sát theo nội dung (bbox chung cho mọi khung để không bị nhảy), đặt chân sát đáy khung 16x32.
- **Mọi loại:** ép về bảng màu + `--max-colors` (dùng lại hàm trong `tools/pixelize.py`), nền trong suốt, ghi đúng
  `assets/sprites/<loại>/<tên>.png`, ảnh xem x8 vào `build/pixelize/`.

## Bước 2 — làm thử 3 thứ để chốt phong cách (rồi mới làm hàng loạt)

| Thứ | Tool | Tham số chính | File game |
|---|---|---|---|
| Chân dung Rin | `create_image_pro` | 64x64 (nếu không cho thì 128 rồi pixelize về 64), `palette` = 37 màu hex, `max_colors` 16, `no_background` true | `portraits/rin.png` (64x64, **quay mặt sang phải**, vai chạm đáy) |
| Rin đi bộ | `create_character` + `animate_character` (`template_animation_id` "walking-4-frames" hoặc "walk") | `view` "low top-down", `n_directions` 4, `size` ~48, `outline` "single color black outline" | `characters/rin.png` (64x128 hoặc 64x96 nếu chưa có hàng "bận") |
| Con mực | `create_image_pixflux` | 80x40 (tối thiểu 32x32 về diện tích), `no_background` true, `color_image` = `xom_den.png`, vẽ ngang **đầu quay sang phải** | `fish/muc.png` (40x20, tối đa 6 màu) |

Mô tả nhân vật cố định (dùng lại mọi lần):
- **Rin:** young Vietnamese man, early 20s, conical hat (nón lá), plain blue t-shirt, dark trousers, sandals,
  tired but kind face. Cựu sinh viên IT, giờ đi câu đêm + chạy bàn.
- **Bảo:** Vietnamese man, early 20s, a bit chubby, white cook shirt, orange apron, short black hair, cheerful.
- **Vy:** Vietnamese woman, early 20s, long dark hair, pink shirt, apron when working, gentle.
- **Cô Năm:** Vietnamese woman in her 60s, grey hair in a bun, green blouse, grocery seller.
- **Mèo (Mỡ):** chubby orange cat.

Sau khi tải + import: chạy game có cửa sổ, chụp màn hình (quán có Rin đi, hộp thoại có chân dung, khoang có con mực,
F7 bật/tắt) để chủ dự án duyệt. Chưa duyệt thì chưa làm tiếp.

## Bước 3 — làm hàng loạt (sau khi duyệt)

Thứ tự: chân dung (Bảo, Vy, Cô Năm, mèo) → hải sản trong khoang (`fish/`) → món ăn (`dishes/`, 16x16, ≤ 6 màu)
→ đồ trong quán (`create_map_object`, view "high top-down") → nhân vật còn lại + khách → hải sản trên vỉ
(`grill/`) → thuyền (`sea/`). Ô gạch / mặt nước để sau (game chưa dùng tile tự nối).

## Lưu ý chi phí

- Tính theo lượt tạo. Chế độ thường ~1 lượt; `create_image_pro` và mọi chế độ "pro" 10–25 lượt mỗi lần → chỉ dùng
  cho chân dung. Gọi `get_balance` trước khi làm hàng loạt và báo số dư cho chủ dự án.
- Đừng tạo lại cả loạt khi chỉ cần sửa một chỗ: dùng `edit_image` / `create_character_state`.
- Asset dùng thương mại được trong game theo nguồn bên thứ ba; chủ dự án tự kiểm tra Điều khoản PixelLab.
