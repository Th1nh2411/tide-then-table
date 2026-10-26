# Kế hoạch art — Xóm Đèn

> **Portrait framing rule (approved):** Runtime portraits must show the character from the navel/upper abdomen upward, ending around the elbows (not chest-up). Keep the same crop and shoulder placement used by the existing Rin, Bao, and Vy portraits; hands and lower torso should not be visible.

> **Cô Năm visual update (approved):** Cô Năm is approximately 40 years old, with a youthful modern appearance. Use a simple tied-back dark/gray hairstyle with limited gray highlights, a friendly face, and a green blouse. Match Rin's low-detail pixel-art treatment and restrained palette; avoid the older-woman/60s design and overly detailed rendering.

> **Restaurant prop perspective (approved):** Props use a top-down orthographic farming-sim view: primary edges stay horizontal/vertical, top surfaces are modest, and there is no isometric convergence. Add only a hard 1–2 px dark-navy contact shadow directly under feet, wheels, or the base so objects do not float; never use soft or long cast shadows.

Cập nhật: 2026-10-23. Kích thước và tên file từng loại xem `ASSETS.md`;
code nạp art và chạy game xem `CLAUDE.md`.

## Chân dung

### Quy chuẩn approved — 2026-10-22

- Runtime portrait quay về bộ **128×128 approved**, giữ nguyên màu, alpha, tỉ lệ và vị trí của ảnh trong `build/portraits/128/approved/`.
- Approved hiện có, đã cài lại ngày 2026-10-23: `rin_base.png` → `rin/base.png`, `rin_vui_extended_v1.png` → `rin/vui.png`, và `vy_base.png` → `vy/base.png`. File runtime giữ nguyên bytes của approved.
- Bổ sung `bao_base.png` → `bao/base.png` ngày 2026-10-23, giữ nguyên bytes approved. Các emotion và frame mở miệng Bảo cũ đã cất vào `build/portraits/before_bao_approved_20261023.*/`; game dùng base approved khi chưa có emotion mới.
- Rin approved là dáng mảnh, áo ba lỗ che kín rốn; Vy dùng mẫu approved hiện có. Không dùng sheet 512 emotion làm runtime.

### Quy ước hiển thị

- Portrait thoại dùng ảnh approved 128×128, nền trong suốt, bán thân 3/4 quay phải và hiển thị 2× trong khung portrait 256×256 theo yêu cầu thử kích thước lớn.
- Game dùng nearest, tắt mipmap, khung portrait 256×256 và vị trí nguyên pixel; cửa sổ phóng theo hệ số nguyên để giữ nét pixel. Nhân vật bên phải tự lật. File thường là `<id>/base.png`; emotion chỉ dùng khi có file approved tương ứng.
- Đồng bộ ảnh mới 2026-10-23: `bao_open.png` → `bao/base_open.png`, `bao_vui.png` → `bao/vui.png`, `rin_base_open.png` → `rin/base_open.png`, `vy_open.png` → `vy/base_open.png`. Giữ nguyên ảnh đã có trong assets.
- Hiện `bao_base.png` trong approved và `bao/base.png` trong assets đều vắng mặt; Bảo có `vui` và `base_open` nhưng còn thiếu base đóng miệng. Cần bổ sung bản approved để hoàn chỉnh trạng thái mặc định.

## Việc tiếp theo

1. Chân dung Cô Năm và mèo.
2. Hải sản trong khoang (`fish/`), rồi món ăn (`dishes/`).
3. Đồ trong quán, nhân vật còn lại và khách.
4. Hải sản trên vỉ (`grill/`), thuyền (`sea/`); ô gạch và mặt nước làm sau.

Tiến độ 2026-10-25: đã thêm mặt tiền cửa hàng, bảng menu, quầy/két tạp hoá, đủ ba cấp xe đẩy/bếp, lò than, bàn ghế, nền đường, thùng lạnh, thùng rác, vòi bia, chậu cây và dây đèn trong `restaurant/`. Các prop active đã được đồng bộ theo góc top-down orthographic và có bóng tiếp xúc cứng; khách thường đã tách sprite ngồi chờ/ngồi ăn. Nhóm prop và décor nhà hàng cốt lõi đã hoàn tất.

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
- **Cô Năm:** Vietnamese woman around 40, youthful modern appearance, simple tied-back dark/gray hair with a few silver strands, green blouse, grocery seller.
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
- Rin dùng `rin_carry.png` khi bưng món; đĩa nằm giữa hai tay ở ngang eo. Túi hàng mua ngoài quán đặt giữa, ngay dưới hông và không dùng tư thế bưng món.
- Khách thường dùng `guest_wait.png` khi ngồi chờ và `guest_eat.png` khi có món; mỗi file là một hàng 4 frame 16×32. Nếu biến thể khách chưa có file riêng thì game dùng hàng bận cũ.
- Nguồn sheet Vy `tools/ref/vy_spritesheet.webp` chưa rõ giấy phép:
  cần kiểm tra hoặc thay trước khi phát hành công khai.

## Công cụ và tích hợp

- PixelLab đã được dùng cho sprite và animation; chọn công cụ theo asset đang làm.
  Kiểm tra kết nối và số dư thực tế trước khi tạo, thay vì dùng số lượt trong lịch sử.
- `tools/pixellab_import.py`: import nhân vật mới hoặc ảnh đơn.
  `tools/pixellab_walk.py`: ghép animation vào sheet, có tùy chọn giữ đầu đã sửa.
- `tools/pixelize.py`: chỉ dùng cho asset cần pixel grid/palette; không dùng để ép portrait minh họa lớn về 128.
- Bảng Xóm Đèn: `assets/palette/xom_den.hex`; giới hạn màu các loại asset xem `ASSETS.md`.
  Chân dung theo màu của mẫu 128 đã duyệt.
- Game đọc PNG từ `assets/sprites/`; thiếu ảnh thì dùng hình tạm.
  F7 trong bản debug xem thử bảng màu Xóm Đèn.

## File làm việc và bản sao

- `build/portraits/128/`: nguồn Rin/Vy đã chọn cùng các bản nháp 128.
- `build/portraits/64/`: các bản cũ; bản ngay trước chuyển đổi ở
- `build/portraits/ref/`: chỉ các frame tham khảo 128×128 của Rin, Bảo và Vy.
- `tools/ref/`: prompt và nguồn tham khảo các lần làm trước.
- `build/shots/`: ảnh chụp trong game. Các thư mục `build/` không commit.
