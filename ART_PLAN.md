# Kế hoạch art — Xóm Đèn

Cập nhật: 2026-10-20. Kích thước và tên file từng loại xem `ASSETS.md`;
code nạp art và chạy game xem `CLAUDE.md`.

## Chân dung

- Chuẩn **128x128**, nền trong suốt, bán thân 3/4 quay phải, vai chạm đáy.
- **Rin và Vy đã duyệt và đang dùng:** `assets/sprites/portraits/rin.png`, `vy.png`.
  Đây là mẫu phong cách cho các chân dung tiếp theo; giữ màu và alpha của ảnh đã duyệt.
- Game hiển thị trong khung 128x128, tự lật nhân vật bên phải.
  File thường: `<id>.png`; biểu cảm: `<id>_<mood>.png`. Thiếu biểu cảm thì dùng ảnh thường.
- **Bảo:** đang dùng portrait 128 tại `assets/sprites/portraits/bao.png`, tóc ngắn mái ngố
  theo sprite, phong cách theo Rin. Prompt tham khảo: `tools/ref/bao_rin_style_v2_prompt.txt`.
- **Biểu cảm Rin:** cần làm lại `vui`, `buon`, `lo`, `ngac_nhien` từ base 128,
  giữ nhất quán tóc, thân và bố cục. Bản 64 đã cất khỏi game; các bản 128 `*_raw` còn là nháp.
- Chân dung mới được so cạnh Rin/Vy và xem trong hội thoại để kiểm tra phong cách, tỉ lệ và hướng mặt.

## Việc tiếp theo

1. Biểu cảm Rin/Vy/Bảo; chân dung Cô Năm, mèo.
2. Hải sản trong khoang (`fish/`), rồi món ăn (`dishes/`).
3. Đồ trong quán, nhân vật còn lại và khách.
4. Hải sản trên vỉ (`grill/`), thuyền (`sea/`); ô gạch và mặt nước làm sau.

## Nhân vật

- **Rin:** young Vietnamese man, messy fluffy black hair with bangs, black rectangular glasses, tanned skin, small
  silver earring, white tank top (singlet), thin black chain necklace with a small silver fish-hook pendant, dark shorts, sandals, kind face. Cựu sinh viên IT, giờ đi câu đêm + chạy bàn.
  Tính: dễ dãi, thuận theo ý trời, chưa biết mình muốn gì → dáng thả lỏng, vai hơi xuôi, mắt sau kính hơi lờ đờ,
  cười nửa miệng kiểu "sao cũng được"; không vẽ Rin tự tin / quyết liệt (để dành cho hồi cuối, có thể thêm mood
  `quyet` sau).
- **Bảo:** Vietnamese man, early 20s, a bit chubby, round cheerful face, short black hair with a blunt fringe matching the gameplay sprite, no hat,
  orange short-sleeve t-shirt, cream apron, dark trousers (áo cam, tạp dề, không đội mũ — chủ dự án bỏ mũ đầu bếp).
- **Vy:** young Vietnamese woman, early 20s, long glossy dark hair with soft waves and a small pastel hair clip,
  fair skin, light makeup, pastel pink fitted blouse, cream mini skirt, spotless white sneakers, tiny crossbody bag,
  slightly raised chin, a bit haughty (tiểu thư: nhà khá giả, hết tiền đi chơi nên đi làm thêm; ghét dơ, ghét mùi cá).
  - **Diễn tiến ngoại hình theo arc (cùng một bộ, đổi chi tiết, không vẽ lại cả nhân vật):**
    - *Đầu (ngày 4–5):* đồ như trên, đeo găng tay cao su hồng khi dọn bàn, tạp dề mặc gượng (buộc lỏng, lệch),
      tay cầm đĩa xa người. Sprite: dáng đi nhón, hai tay hơi giơ (sợ dính dơ).
    - *Sau (từ khi mở lòng):* tóc buộc cao gọn bằng dây thun, xắn tay áo, tạp dề buộc chặt có vết bẩn nhỏ,
      đổi giày trắng sang dép tổ ong; bỏ găng tay. Sprite: đi nhanh, bê đĩa sát người.
  - **Nét mặt chân dung** (`portraits/vy_<mood>`): thường (cằm hơi hếch, mắt lim dim chán), `che` (nhăn mũi,
    mím môi — ghét dơ / chê), `kieu` (khoanh tay, liếc ngang), `boi_roi` (đỏ mặt, nhìn đi chỗ khác), `vui`
    (cười thật, mắt cong — chỉ dùng nhiều ở nửa sau arc), `lo`. Bản "sau" (`vy_sau`, `vy_sau_vui`...) tóc buộc
    cao, có thể làm sau, thiếu thì dùng bản đầu.
- **Cô Năm:** Vietnamese woman in her 60s, grey hair in a bun, green blouse, grocery seller.
- **Mèo (Mỡ):** chubby orange cat.

## Sprite gameplay — giữ phần sửa tay

- Khung **16x32**, sheet 4 cột; hàng xuống, lên, trái, tùy chọn hàng bận.
  Hướng phải dùng ảnh lật. Cột 0 đứng yên, bước đi dùng chu kỳ 1–2–3–2.
- Tỉ lệ hiện tại theo Rin: đầu khoảng 13 dòng, chẻ chân dòng 25,
  ống chân 25–29, bàn chân 30–31; riêng Rin giữ tóc/đầu 14 dòng đã sửa.
- Rin có kính kiểu gọng mày trên sprite: thanh trên và sống mũi, tròng 2x2;
  chân dung giữ kính gọng đen. Script tham khảo: `tools/rin_glasses.py`, biến thể `e`.
- Rin đã sửa tay: chạy lại `pixellab_import.py` trên sheet này sẽ mất phần sửa.
- Vy đã sửa tay hàng 1–2 và tóc: chạy lại `make_vy_sheet.py` sẽ ghi đè.
  Hàng ngang từng xử lý bằng `tools/vy_third_row.py` và `tools/pixellab_walk.py`.
- Sau khi sửa sheet, cập nhật idle bằng `tools/make_idle.py`; kiểm tra `BLINK` / `WAIST`
  nếu vị trí mặt hoặc eo thay đổi. Mốc eo đã ghi nhận: Rin 20, Bảo 20, Vy 19.
  Xem bằng `scenes/test/sprite_viewer.tscn`.
- Vy chưa có hàng bận; bản tóc buộc cao theo arc làm sau.
- Nguồn sheet Vy `tools/ref/vy_spritesheet.webp` chưa rõ giấy phép:
  cần kiểm tra hoặc thay trước khi phát hành công khai.

## Công cụ và tích hợp

- PixelLab đã được dùng cho sprite và animation; chọn công cụ theo asset đang làm.
  Kiểm tra kết nối và số dư thực tế trước khi tạo, thay vì dùng số lượt trong lịch sử.
- `tools/pixellab_import.py`: import nhân vật mới hoặc ảnh đơn.
  `tools/pixellab_walk.py`: ghép animation vào sheet, có tùy chọn giữ đầu đã sửa.
- `tools/pixelize.py`: xử lý kích thước/bảng màu khi cần; mặc định đầu ra 64x64.
  Hai portrait 128 đã duyệt được dùng trực tiếp.
- Bảng Xóm Đèn: `assets/palette/xom_den.hex`; giới hạn màu các loại asset xem `ASSETS.md`.
  Chân dung theo màu của mẫu 128 đã duyệt.
- Game đọc PNG từ `assets/sprites/`; thiếu ảnh thì dùng hình tạm.
  F7 trong bản debug xem thử bảng màu Xóm Đèn.

## File làm việc và bản sao

- `build/portraits/128/`: nguồn Rin/Vy đã chọn cùng các bản nháp 128.
- `build/portraits/64/`: các bản cũ; bản ngay trước chuyển đổi ở
  `build/portraits/64/before_128_20261020_154215/`.
- `build/portraits/ref/`: nguồn lớn, JSON, ảnh so sánh và preview.
- `tools/ref/`: prompt và nguồn tham khảo các lần làm trước.
- `build/shots/`: ảnh chụp trong game. Các thư mục `build/` không commit.
