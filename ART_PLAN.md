# Kế hoạch art — Xóm Đèn

> **Portrait framing rule (approved):** Runtime portraits must show the character from the navel/upper abdomen upward, ending around the elbows (not chest-up). Keep the same crop and shoulder placement used by the existing Rin, Bao, and Vy portraits; hands and lower torso should not be visible.

> **Cô Năm visual update (approved):** Cô Năm is approximately 40 years old, with a youthful modern appearance. Use a simple tied-back dark/gray hairstyle with limited gray highlights, a friendly face, and a green blouse. Match Rin's low-detail pixel-art treatment and restrained palette; avoid the older-woman/60s design and overly detailed rendering.

> **Restaurant prop perspective (approved):** Props use a top-down orthographic farming-sim view: primary edges stay horizontal/vertical, top surfaces are modest, and there is no isometric convergence. Add only a hard 1–2 px dark-navy contact shadow directly under feet, wheels, or the base so objects do not float; never use soft or long cast shadows.

Cập nhật: 2026-10-27. Kích thước và tên file từng loại xem `ASSETS.md`;
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
- Kiểm kê 2026-10-27: runtime đã có `bao/base.png`, `base_open.png` và `vui.png`; không còn thiếu base đóng miệng. Trạng thái approved của nguồn được giữ theo ghi nhận ở trên.

## Việc tiếp theo

1. Duyệt hình ảnh nhóm mới ở các preview dưới đây; phần kỹ thuật và tích hợp đã có kiểm tra riêng.
2. Sprite phụ đã bổ sung trong đợt bên dưới: khách sang/quen, đạo cụ cutscene và portrait phụ. Không cần 9 bản PNG nhân viên trùng nhau vì đã có `staff.png` dùng chung.
3. Mặt nước, địa điểm ngoài biển, UI và cảnh riêng thuộc backlog P2/P3 trong `ASSETS.md`; ô gạch quán đã có. Xác minh hoặc thay nguồn sprite Vy trước phát hành công khai.

### Hoàn thiện nhóm art tiếp theo — 2026-10-27

- `grill/{ca_thu,tom,muc,oc_huong}.png`: 4 master 60×32, sống, mỗi ảnh 6 màu Xóm Đèn; runtime nhuộm màu/lật khi nướng.
- `sea/{thuyen_thung,ghe_cheo,ghe_may}.png`: 32×32 / 48×20 / 60×24, boong nhìn trên, mũi +X. `Boat` đùn thành theo silhouette hướng xuống màn hình khi xoay; PNG không chứa bóng đổ.
- `sea/rin_boat.png`: 16×32, áo ba lỗ, kính, nón lá; renderer giữ người thẳng đứng.
- `characters/co_nam.png` 64×128 + `co_nam_idle.png` 64×96: khung 16×32, đi xuống/lên/trái, vẫy tay, thở/chớp mắt; tóc buộc thấp, áo xanh. `characters/staff.png` 64×128 là nhân viên chung, đi ba hướng và hàng bận. Mỗi nhân vật tối đa 10 màu.
- Imagegen built-in tạo concept riêng từng asset; nguồn oversized giữ riêng trong `tmp/imagegen/`. Master được đặt pixel trực tiếp trên grid native bằng `tools/grill_sprites.py`, `make_sea_sprites.py`, `make_co_nam.py`, `staff_sprites.py`; không thu nhỏ concept thành master.
- Kiểm kỹ thuật: `python3 tools/check_assets.py --group grill --group sea --group characters` (11 master). Approved portrait không bị xử lý lại. Ảnh fish/dish cũ đủ cỡ/alpha/giới hạn màu nhưng có màu ngoài bảng Xóm Đèn; checker báo WARN, chưa tự đổi màu art đang active.
- Xem renderer thật: F6 `scenes/test/asset_preview.tscn` (phím 1/2/3: sống/chín/cháy) và `restaurant_art_preview.tscn` (quán có Cô Năm, Vy, nhân viên chung, tắt autosave). Ảnh chụp ở `build/shots/asset_preview_0.png`, `_1.png`, `_2.png`, `restaurant_art_preview.png`.
- Lần đầu cài không ghi đè ảnh cũ. Các lần chỉnh mới trong đợt này đã sao lưu sea vào `build/sea/backups/20261027_*`; generator bảo vệ hoặc sao lưu trước khi ghi lại. `make_idle.py` nay cất bản cũ vào `build/idle/backups/<timestamp>/` trước khi dựng lại (đã kiểm bytes backup bằng thư mục test riêng). Trạng thái thẩm mỹ: đã tự kiểm ở native/enlarged và trong renderer; chờ chủ dự án duyệt.

### Sprite phụ — 2026-10-27

- Đã cài 6 PNG khách sang/quen: mỗi loại có sheet 64×128 đi xuống/lên/trái và hàng bận, cùng `_wait`/`_eat` 64×32. Khách sang áo vàng/cà vạt đỏ/tóc rẽ ngôi; khách quen tóc muối tiêu/áo xanh rêu. `Customer` tự chọn đúng ảnh, cảnh `regular_thanks` dùng actor `guest_regular` để khớp chân dung.
- Đạo cụ: `characters/crate.png` 20×14, `rin_bed.png` 32×16, `rin_faint.png` 32×10, `glow.png` 320×80 (4 frame). Rin giữ kính, áo ba lỗ, đầu bên trái; aura giữ sáng qua tint đêm. Glow là ngoại lệ alpha theo bậc có chủ đích, không phải halo từ resize.
- Chân dung mới: `portraits/ong_tam/base.png`, `portraits/khach_quen/base.png` 128×128, 3/4 quay phải, đến bụng trên/khuỷu tay, palette gọn. Ông Tám tóc bạc/áo nâu, khách quen tóc muối tiêu/áo xanh rêu khớp sprite. `PoiDialog.ask` có speaker tuỳ chọn, ông Tám dùng ảnh trong cả lời chào và hỏi chuyện; các địa điểm khác giữ hộp thoại gọn khi không có speaker/ảnh.
- Nguồn tái tạo: `tools/guest_variants.py`, `tools/cutscene_sprites.py`, `tools/side_portraits.py`. Khách/portrait có concept imagegen riêng; cutscene chuyển từ thiết kế fallback GDScript có sẵn thành pixel native. Không thu nhỏ concept thành master, không sửa các PNG approved cũ. Các bản portrait nháp trước chỉnh được giữ trong `build/portraits/backups/20261027_*`.
- QA: `python3 tools/check_assets.py --group characters --group cutscenes --group portraits`; art test nạp từng PNG đúng kích thước. Preview F6 `scenes/test/secondary_art_preview.tscn` dùng đúng `Customer`, `CutsceneActor`, `PoiDialog`, `DialogueBox`; O/K mở chân dung ông Tám/khách quen. Ảnh chụp: `build/shots/secondary_art_preview.png`, `ong_tam_poi_preview.png`, `khach_quen_dialogue_preview.png`. Đã tự kiểm kỹ thuật và hình ảnh, chưa có duyệt thẩm mỹ từ chủ dự án.

Kiểm kê 2026-10-27: đã có chân dung Cô Năm và mèo, đủ 7 ảnh hải sản trong `fish/` và 18 ảnh món trong `dishes/`. Các mục này không còn là việc tạo mới; việc có file chưa thay thế bước duyệt hình ảnh. Nhóm mới phía trên được bổ sung trong đợt art tiếp theo, giữ nguyên các PNG đã duyệt từ trước.

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

### Hướng nhân vật 3D đã chốt — 2026-10-28

- Người dùng chọn **low-poly stylized** theo ảnh tham khảo gửi trong hội thoại:
  tỷ lệ người tương đối tự nhiên, silhouette rõ, tóc thành mảng lớn, quần áo ít
  chi tiết, bề mặt đa giác và màu phẳng. Giữ bảng màu/ánh sáng ấm của mẫu quán đã thích.
- Ưu tiên hình khối, tỷ lệ và chuyển động khớp đúng; không tăng độ chi tiết mặt
  hay số polygon để bù cho cấu trúc cơ thể sai. Mặt tối giản, nhận diện bằng dáng,
  tóc, kính, trang phục và màu sắc. Không yêu cầu sao chép từng nét portrait lên mesh.
- Rin: dáng thanh, da rám, tóc đen/xanh đen vuốt lệch có độ phồng, kính chữ nhật,
  áo ba lỗ màu ngà, khuyên bạc nhỏ và dây chuyền lưỡi câu. Portrait approved vẫn
  là chuẩn nhận diện và giữ vai trò thể hiện biểu cảm chi tiết trong hội thoại.
- Hướng triển khai: thử **Quaternius Universal Base Characters — Regular Male**
  làm nền stylized có rig, rồi chỉnh thành Rin. Đây là lựa chọn thử nghiệm, chưa
  tải/kiểm chứng model hoặc chốt dùng trong runtime. MPFB2 là phương án dự phòng
  nếu tỷ lệ/topology của base không phù hợp; không chuyển sang hướng tả thực.
- Dùng nguồn chính thức: https://quaternius.itch.io/universal-base-characters.
  Bản Standard CC0 miễn phí; gói Source có file Blender là gói trả phí, chưa mua.
- Điều kiện nghiệm thu: xem trước/nghiêng/sau và tại camera gameplay; kiểm vai,
  khuỷu tay, hông, đầu gối, trọng số da khi đứng/đi/bưng đồ; không hở khớp, gãy
  hình hoặc xuyên cơ thể rõ. Kiểm lại material, skeleton và animation sau import Godot.
- Hai bản `rin_portrait_study` và `rin_painted` giữ làm nghiên cứu, chưa đạt chuẩn
  ngoại hình/giải phẫu/rig để duyệt dùng chính thức. Kiểm import/clip trước đây
  không đồng nghĩa đã đạt chất lượng biến dạng khớp.
- Quyết định này thay hướng nhân vật ghép khối cơ học, giật/méo bắt buộc trong
  `NEW_ART_PLAN.md`. Giữ asset active và tạo backup trước mọi thay thế.

### Rin — thử model theo portrait, 2026-10-28 (chờ duyệt)

- Dựng mesh Blender từ portrait runtime `portraits/rin/base.png`: tóc xanh đen rủ mái,
  kính chữ nhật, tai/khuyên bạc, mắt/mũi/miệng, áo ba lỗ, dây lưỡi câu, tay và dép.
- Candidate `assets/models/characters/rin_portrait_study.glb`; source/render trong
  `build/characters/rin_portrait_study/`, generator `tools/blender/build_rin_portrait_study.py`.
- F6 `scenes/art_preview/rin_portrait_study.tscn`: portrait gốc cạnh model, xoay bằng
  mũi tên, 1/2/3 đứng/đi/bưng, 4 cận/toàn thân. Đã kiểm import, skeleton và Walk trong Godot.
- Bảng so sánh `comparison.png`; bản này vẫn cách điệu, chưa được duyệt ngoại hình.
  Không thay portrait, sprite, mesh Rin đang dùng trong gameplay. Rebuild có backup.

### Rin — biến thể mesh + texture, 2026-10-28 (chờ duyệt)

- Thử hướng mesh gọn + nét vẽ 2D gắn lên 3D từ bài tham khảo người dùng đưa;
  không sao chép asset của tác giả bài Reddit.
- `assets/models/characters/rin_painted/rin_painted.glb`: 1 mesh có rig, 13 material
  surfaces, 11,718 tam giác; bản mesh cũ 112 mesh/surface và 19,296 tam giác.
- imagegen tạo albedo riêng cho mặt, tóc, vải áo theo portrait Rin; bản nguồn giữ
  ở `rin_painted/textures/`, ba ảnh 256×256 được nhúng trong GLB. Kính, tai/khuyên,
  mũi, hình khối chính của tóc và phụ kiện vẫn là mesh; material có nhận ánh sáng.
- F6 `scenes/art_preview/rin_painted_study.tscn`; B đổi cũ/mới, 1/2/3 đứng/đi/bưng,
  4 cận/toàn thân, 5 cỡ trong quán. Đã xem nhiều góc và kiểm texture/rig/clip trong Godot.
- Source/render/bản sao ở `build/characters/rin_painted/`; `comparison.png` đặt
  portrait, mesh cũ và bản texture cạnh nhau. Chưa duyệt thẩm mỹ; chưa cài vào gameplay.
