# Art cần vẽ cho các màn còn lại (thoại, khoang, gợi ý, điện thoại, thẻ cá mới, sáng, kết thúc)

Cùng phong cách với `docs/ui_art_needed_hud.md`: pixel art sắc nét, chỉ bảng màu
"Xóm Đèn" (`assets/palette/xom_den.*`), đồ vật thật (giấy, gỗ thùng cá, sổ tay,
mẩu báo, ghim, băng keo, sticker). Viền mỏng 1 px hoặc không viền, gờ sáng 1 px
trên/trái, bóng cứng (2,2) không mờ, góc vuông hoặc bậc 1 px. Nền trong suốt,
nearest filter.

Cách thay: thả PNG đúng tên + kích thước, **không sửa code**. Placeholder vẽ bằng
code ở `tools/ui/ui_extra_frames.gd` (chỉ vẽ file còn thiếu). Khung nine-patch:
xoá file cũ, thả file mới cùng size + lề, chạy `--import` rồi
`tools/ui/build_game_theme.gd`. Sticker: thả thẳng vào `assets/sprites/ui/stickers/`.

## Khung / chất liệu (nine-patch, theme)

| File | Size (lề) | Dùng ở | Mô tả | Trạng thái |
|---|---|---|---|---|
| assets/sprites/ui/frames/journal.png | 48x48 (8) | Dải lời dẫn truyện (DialogueBox khi không có người nói, `JournalPanel`) | Giấy da cũ Đất đá 5, gờ Đất đá 6, hạt Đất đá 4; mép trên + dưới xé rách không đều (ô giữa phải lặp liền) — cảm giác trang nhật ký DREDGE | 1 |
| assets/sprites/ui/frames/crate.png | 48x48 (12) | Khoang thuyền (Tab, `CratePanel`) + khung minigame câu cá | Thùng gỗ Đất đá 2 (vân Đất đá 1, đinh ở 4 góc), lòng thùng tối ướt Xám 3 có lấm tấm xanh biển 5 mờ, viền mực 1 px giữa gỗ và lòng thùng (nằm trong lề) | 1 |
| assets/sprites/ui/frames/hold_slot.png | 20x20 (4) | Một ô khoang (vẽ lặp từng ô, không kéo giãn) | Ván gỗ ướt Đất đá 1, cạnh trên sáng Đất đá 2, 2 vân ngang mờ, 1–2 đốm phản sáng Xanh biển 6 | 1 |
| assets/sprites/ui/frames/notebook.png | 48x48 (10) | Thẻ buổi sáng (`NotebookPanel`, màn nghỉ) | Trang vở trắng Xám 8, dòng kẻ Xanh biển 5 mờ cách 5 px, lề đỏ Đỏ 3 ở x=8, lỗ gáy lò xo ở mép trên | 1 |
| assets/sprites/ui/frames/clipping.png | 48x48 (8) | Thẻ tổng kết cuối game (`ClippingPanel`, màn kết thúc) | Giấy báo Xám 7, hạt Xám 6 dày, mép trên/dưới xé | 1 |
| assets/sprites/ui/frames/app_card.png | 24x24 (6) | Thẻ app trong điện thoại: Kho, Menu, Dex, Thuyền, Sổ sách, Nâng cấp, Nhân viên (`AppCardPanel`) | Thẻ phẳng trắng Xám 8, gờ sáng trắng, gờ tối Xanh biển 6, viền mực 2 px | 1 |

## Sticker (không kéo giãn)

| File | Size | Dùng ở | Mô tả | Trạng thái |
|---|---|---|---|---|
| assets/sprites/ui/stickers/pin.png | 9x10 | Ghim thẻ gợi ý (Guide), ghim tờ giấy ở các địa điểm (PoiDialog) | Đinh ghim đỏ nhìn từ trên: đầu tròn Đỏ 3, viền mực, chấm sáng Đất đá 6, bóng kim 1 px | 1 |
| assets/sprites/ui/stickers/tape.png | 26x10 | Băng keo dán: dải lời dẫn (2 góc), thẻ cá mới, trang vở buổi sáng, mẩu báo kết thúc | Băng keo giấy Đất đá 6 trong mờ (~80%), hai đầu răng cưa | 1 |
| assets/sprites/ui/stickers/burst_new.png | 64x44 | Sticker "NEW!" đập lên góc thẻ cá mới (NewCatchCard; chữ NEW! vẽ đè bằng Paytone đỏ) | Ngôi sao nổ 12 cánh Vàng nón lá, viền mực, bóng cứng (2,2), 1 chấm sáng | 1 (có thể vẽ luôn chữ NEW! vào art; khi đó báo để bỏ chữ trong code) |

## Vẽ bằng code (giữ, hoặc thay sau)

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Khay "cá mới" (viền phấn đứt nét), ô Bỏ (đĩa đỏ + thùng rác), ô Bán (đĩa xanh + đồng xu + giá) | `scenes/ui/hold_grid_painter.gd` | Có thể thay bằng `frames/hold_tray.png`, `frames/hold_trash.png`, `frames/hold_sell.png` (60x30) nếu muốn — cần thêm 3 dòng code |
| Ảnh báo "thuyền đi vào sương" | `scenes/ending/run_clipping.gd` `_Photo` | Thay bằng `assets/sprites/ui/stickers/ending_photo.png` 96x72 (ảnh đen trắng sần) — cần 1 dòng code |
| Đĩa món tạm (khi chưa có `dishes/<id>.png`) | `scenes/rest/rest_card_view.gd` `DishIcon` | Art món đã có danh sách trong ASSETS.md |

## Icon dùng thêm (game-icons tạm, art cuối ở `assets/sprites/ui/icons/<id>.png`)

Không thêm id mới; các màn này dùng: crate, close, check, money, trash, fish,
sparkles, anchor, leave, moon, wave, info, star, trophy, shop, calendar, clock,
people, house, mouse, lamp, basket, boat, fire, help, cart, map, rod, hook,
hammer, oil, dex, ledger, menu, staff, follower, grill, beer, pot, lantern,
upgrade. Icon thời tiết mưa đang mượn `info` → nên có `rain.png` (16x16) và
`wind.png`; khi có thì sửa `RestCardView.WEATHER_ICONS`.
