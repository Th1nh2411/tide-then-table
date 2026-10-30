# Brief vẽ art UI — giao cho Codex

Đây là việc **vẽ art thay placeholder** cho UI mới của "Rin The Fisher" (Xóm Đèn).
Code đã sẵn: mỗi file PNG đặt đúng đường dẫn là game tự dùng, **không sửa code**.
Không file nào có thì game vẫn chạy bằng placeholder.

## Danh sách việc (theo khu vực)

| File danh sách | Khu vực |
|---|---|
| `docs/ui_art_needed_menus.md` | menu chính, tạm dừng, lên món, chợ Cô Năm, hướng dẫn, khung theme |
| `docs/ui_art_needed_goals.md` | thử thách ngày, thành tựu (icon + huy hiệu) |
| `docs/ui_art_needed_social.md` | Xóm Đèn Review: khung app, avatar, huy hiệu hạng quán, logo quán đối thủ |
| `docs/ui_art_needed_hud.md` | HUD quán + biển, phiếu gọi món, điện thoại, hoá đơn cuối ca |
| `docs/ui_art_needed_misc.md` | lời dẫn truyện, khoang thuyền, gợi ý lần đầu, các tab điện thoại, thẻ cá mới, thẻ buổi sáng, địa điểm, kết thúc, khung nấu/câu |

Cùng một đường dẫn có thể xuất hiện ở nhiều danh sách (vd. `icons/money.png`):
**vẽ một lần**, đọc mô tả ở mọi chỗ để hình hợp cả các chỗ dùng.

## Phong cách (bắt buộc)

- Tham khảo **Dave the Diver** (UI pixel chắc nét, viền mực dày, màu phẳng,
  sticker nghiêng, mộc đóng) và **DREDGE** (đồ vật thật, giấy cũ, mực).
- Bối cảnh: quán hải sản vỉa hè Việt Nam ban đêm + một vùng biển nhỏ. UI là
  **đồ vật thật**: bảng phấn, bảng gỗ sơn tay, giấy ngà mép xé + băng keo,
  thùng các-tông + bảng giá viết tay, bảng hiệu đỏ + đèn tuýp, hoá đơn giấy +
  mộc đỏ, điện thoại có viền máy.
- **Chỉ dùng bảng màu "Xóm Đèn"**: `assets/palette/xom_den.gpl` (38 màu Apollo +
  5 màu riêng; bảng hex trong `assets/palette/xom_den.hex`). Không gradient,
  không phát sáng mờ, không bóng đổ mờ.
- Pixel art sắc: viền mực 1 px (icon) / 2 px (khung) `#090a14`, bevel sáng 1 px
  trên-trái, bóng cứng lệch (2,2). Góc vuông hoặc bậc 1 px. Nền trong suốt.
- Icon 16x16 (hiển thị 1x-2x), huy hiệu 24x24, avatar 24x24 — vẽ đúng kích
  thước gốc, không vẽ to rồi thu nhỏ. Game hiển thị bằng nearest filter.
- Khung (frames) là **nine-patch**: giữ nguyên kích thước và độ dày mép của
  placeholder hiện có trong `assets/sprites/ui/frames/` (mỗi danh sách ghi rõ
  margin); phần giữa phải lặp/kéo giãn được.
- Trạng thái (khoá xám, mở vàng, disabled...) phần lớn do code tô; chỉ vẽ thêm
  khi danh sách ghi rõ.

## Quy trình gợi ý

1. Đọc `ART_PLAN.md` (quy ước art của dự án) và danh sách khu vực.
2. Vẽ bằng tool pixel (hoặc PixelLab MCP nếu có); ảnh AI nháp thì làm sạch bằng
   `tools/pixelize.py` để về lưới pixel + bảng màu.
3. Lưu PNG đúng đường dẫn, đúng kích thước.
4. Riêng khung theme: sau khi thay PNG trong `assets/sprites/ui/frames/`, chạy
   `Godot --headless --path . --script res://tools/ui/build_game_theme.gd`.
5. Kiểm tra: `tools/run_tests.sh` (phải ALL OK), mở game xem từng màn.
6. Ghi lại file nào đã thay (đánh dấu trong danh sách khu vực).
