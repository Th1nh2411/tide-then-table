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
  cùng `animation_group_id`). Đã dùng 35/40 lượt + 1 lượt thưởng ngày. **Trial không cho `create_image_pro` khi
  còn < 10 lượt** (không cộng lượt thưởng ngày).
- Rin chốt dáng (2026-10-14, theo ảnh mẫu của chủ dự án): **tóc đen rối, kính gọng đen chữ nhật, da ngăm, áo ba
  lỗ trắng, dây chuyền đen mảnh có mặt lưỡi câu bạc, khuyên tai bạc, quần short đen, dép**; không đội nón. Chân dung quay 3/4 sang phải
    (lần 2 `edit_image_pixen`: "turn ... facing right"; màu mới chưa có trong bảng gán lấy theo màu gốc gần nhất).
  - Chân dung: `edit_image_pixen` (1 lượt) sửa thẳng trên ảnh mẫu (thu về lưới pixel gốc ~45x56, đệm 64x64):
    thêm kính, bỏ tay ở cằm. Màu gán **bằng tay** từng màu gốc → Xóm Đèn (tự động thì tóc ra đỏ nâu, da vàng).
  - Nét mặt (2026-10-14): `edit_image_pixen` trên chân dung gốc phóng x2 (128), chỉ đổi nét mặt; lấy mẫu về
    64x64, gán về đúng 13 màu của chân dung, **chỉ giữ hàng 18–37 (mặt)**, tóc dưới + cổ + thân lấy từ ảnh gốc.
    Có `rin_vui`, `rin_ngac_nhien` (trong game); `rin_lo`, `rin_buon` (chờ duyệt, `build/pixelize/rin_moods/`).
    Bóng dưới cằm sửa tay cho mọi nét: 1 hàng tối ngay dưới đường hàm, mảng vừa, mép dưới gọn, viền phải cổ.
  - Sprite (làm lại 2026-10-14): `create_character` **mode pro** (10 lượt) với `concept_image_url` = chân dung
    `portraits/rin.png` phóng x4, size 32 → dáng chibi đầu to, màu khớp chân dung; character id
    `f07ff7e8-0d08-42f9-b22b-e231ab4b36af`. Animation `walking-4-frames` của PixelLab lem (tóc đổi hình mỗi
    khung, chân thành cục) → **không dùng**; sheet dựng tay từ 3 ảnh đứng yên (15x28, vừa khung 16x32 1:1, màu gán
    tay sang Xóm Đèn): dọn kính trắng loáng (tròng `ebede9` + `c7cfcc`), dây tối + móc bạc, áo trắng `ebede9`
    (kem `e7d5b3` trùng tông da, lưng nhìn như cởi trần); khung 1/3 đứng yên, 2/4 nhún lên 1 px + nhấc 1 chân
    (ngang: 2 chân dạng, chân xa tối hơn). Không chạy `pixellab_import.py` cho Rin nữa (mất phần sửa tay).
- Bài học bước 2:
  - `create_image_pro` ở đúng cỡ game (64x64, 40x20) đẹp hơn hẳn pixflux + thu nhỏ; cỡ ≤ 42 px cho 64 ứng viên.
    Tốn 10 lượt mỗi lần → dùng cho chân dung + hải sản, chọn nhiều thứ trong một lần nếu được.
  - `create_image_pixflux` cho con mực kém (2 lần, hình lạ) → bỏ cho hải sản.
  - `create_character` size 48 → người cao ~53 px, thu về 32 px làm mặt lỗi. Dùng **size 29** (người cao ~35 px,
    gần đúng 16x32, nét hơn hẳn). Nón lá phải tả rõ "pointed cone-shaped conical hat", không thì ra nón cao bồi.
  - `edit_image_pixen` đổi hướng / thêm kính tốt, nhưng **tư thế tay chính xác thì không nghe lời** (3 lần "gãi
    sau đầu" đều ra tay trên đỉnh đầu hoặc mất khuỷu). Tư thế cụ thể: phác khối tay thô trong Aseprite trước
    (đúng chỗ, đúng màu da), rồi cho AI làm sạch (`edit_image_pixen` "clean up, keep the pose" hoặc
    `create_image_pixflux` `init_image_strength` ~300); hoặc `edit_image` bản pro.
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
| Chân dung Rin | `create_image_pro` | 64x64 (nếu không cho thì 128 rồi pixelize về 64), `palette` = 37 màu hex, `max_colors` 16, `no_background` true | `portraits/rin.png` (64x64, 3/4 **quay mặt sang phải**, vai chạm đáy; nhân vật khác: xem quy ước chân dung ở bước 3) |
| Rin đi bộ | `create_character` + `animate_character` (`template_animation_id` "walking-4-frames" hoặc "walk") | `view` "low top-down", `n_directions` 4, `size` ~48, `outline` "single color black outline" | `characters/rin.png` (64x128 hoặc 64x96 nếu chưa có hàng "bận") |
| Con mực | `create_image_pixflux` | 80x40 (tối thiểu 32x32 về diện tích), `no_background` true, `color_image` = `xom_den.png`, vẽ ngang **đầu quay sang phải** | `fish/muc.png` (40x20, tối đa 6 màu) |

Mô tả nhân vật cố định (dùng lại mọi lần):
- **Rin:** young Vietnamese man, messy fluffy black hair with bangs, black rectangular glasses, tanned skin, small
  silver earring, white tank top (singlet), thin black chain necklace with a small silver fish-hook pendant, dark shorts, sandals, kind face. Cựu sinh viên IT, giờ đi câu đêm + chạy bàn.
  Tính: dễ dãi, thuận theo ý trời, chưa biết mình muốn gì → dáng thả lỏng, vai hơi xuôi, mắt sau kính hơi lờ đờ,
  cười nửa miệng kiểu "sao cũng được"; không vẽ Rin tự tin / quyết liệt (để dành cho hồi cuối, có thể thêm mood
  `quyet` sau).
- **Bảo:** Vietnamese man, early 20s, a bit chubby, round cheerful face, short black hair, no hat,
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

Sau khi tải + import: chạy game có cửa sổ, chụp màn hình (quán có Rin đi, hộp thoại có chân dung, khoang có con mực,
F7 bật/tắt) để chủ dự án duyệt. Chưa duyệt thì chưa làm tiếp.

## Bước 3 — làm hàng loạt (sau khi duyệt)

**Quy ước chân dung (mọi nhân vật):** cùng góc nhìn với chân dung Rin: bán thân, **3/4**, đầu + vai, vai chạm đáy,
64x64, cùng phong cách (tóc / mảng màu phẳng, viền tối, màu gán tay sang Xóm Đèn). Trên màn hình Rin ở bên trái
**quay sang phải**, mọi nhân vật khác ở bên phải **quay sang trái** (nhìn về phía Rin).
- **File PNG luôn vẽ quay sang phải**, kể cả nhân vật khác: game tự lật chân dung bên phải
  (`DialoguePortrait.mirrored`), nên file quay phải → trên màn hình quay trái. Đừng vẽ sẵn quay trái (bị lật
  thành quay phải). Chi tiết lệch một bên (khuyên tai, rẽ ngôi, vết sẹo) sẽ đổi bên khi lật — đặt chúng theo
  hướng nhìn trên màn hình.
- Cách làm: dùng `portraits/rin.png` làm ảnh mẫu phong cách (`create_image_pro` `style_image_url`, hoặc
  `edit_image_pixen` từ ảnh nhân vật), mô tả "three-quarter view facing right"; ép / gán màu như chân dung Rin.
- Kiểm tra trong game: hộp thoại Rin ↔ nhân vật đó, hai người phải nhìn nhau.
- **Cách đã chạy tốt (Bảo, 2026-10-15):** chân dung = `edit_image_pixen` (1 lượt) trên `portraits/rin.png` phóng
  x2 với mô tả "turn this into a different character, same three-quarter bust facing right, same framing...";
  lấy mẫu về 64x64, gán màu tay (bảng màu trong lần làm của Bảo: áo `de9e41` / bóng `be772b`, da `d7b594`);
  bỏ má hồng (ra vệt bẩn), dọn quầng nâu quanh mắt; mắt vẽ tay kiểu Rin (mí trên `151d28`, lòng trắng `ebede9`, con ngươi lệch về hướng nhìn). Bỏ mũ: `edit_image_pixen` "remove the chef hat", chỉ lấy hàng 0–23 (tóc), mặt giữ bản vẽ tay.
  Sprite = `create_character` pro (10 lượt) với chân dung làm `concept_image_url`, size 32, rồi dựng sheet tay
  như Rin (ảnh đứng yên xén về 16 px, khung 2/4 nhún + nhấc chân, ngang tự vẽ chân sải); hàng 4 "đang bận" =
  người nhún 1 px + một tay nhấc 1 px, xen kẽ. Bảo: character id `6c8fa01a-acd4-4ddc-aaf3-10f5bfc40bf1`.

Thứ tự: chân dung (Bảo, Vy, Cô Năm, mèo) → hải sản trong khoang (`fish/`) → món ăn (`dishes/`, 16x16, ≤ 6 màu)
→ đồ trong quán (`create_map_object`, view "high top-down") → nhân vật còn lại + khách → hải sản trên vỉ
(`grill/`) → thuyền (`sea/`). Ô gạch / mặt nước để sau (game chưa dùng tile tự nối).

## Chia việc: PixelLab vs công cụ miễn phí (đã chốt)

Model AI phổ thông (Gemini, FLUX, SDXL + LoRA pixel) vẽ ảnh to "giả pixel": lưới lệch, nhiều màu, viền nhòe;
thu về 16–64 px thì mất chi tiết. PixelLab vẽ thẳng ở độ phân giải nhỏ, ép được bảng màu, có góc top-down và
hoạt hình. Ở cỡ 16 px kiểu gì cũng sửa tay nhiều (sheet Rin / Bảo đã phải dựng tay) → **dồn lượt PixelLab vào
chỗ không thay được, còn lại làm miễn phí.**

| Asset | Làm bằng | Ghi chú |
|---|---|---|
| Sprite người 16x32 + đi bộ 4 hướng (Vy, Cô Năm, khách...), mèo | **PixelLab** | Không công cụ miễn phí nào giữ cùng một nhân vật qua 4 hướng x 4 khung. Vẫn dựng sheet tay như Bảo |
| Đồ trong quán (`create_map_object`) | **PixelLab** | Giữ đúng góc 3/4 giữa các món; đồ free hay lệch góc |
| Chân dung 64x64 | **Miễn phí:** Gemini (sửa ảnh theo ảnh mẫu `portraits/rin.png`) → `tools/pixelize.py` → sửa tay | Gần bằng PixelLab; khó nhất là giữ cùng phong cách. Chưa ra thì quay về cách `edit_image_pixen` ở bước 3 |
| Cá trong khoang, món ăn 16x16, hải sản trên vỉ | **Miễn phí:** vẽ tay trong Pixelorama hoặc `pixelart_workbench` (công cụ pixel miễn phí của PixelLab MCP), AI chỉ để tham khảo dáng | Cỡ này tay người thường đẹp hơn; ≤ 6 màu, gán màu Xóm Đèn |

- Công cụ miễn phí dùng được: Gemini / ChatGPT / Bing Image Creator (phác), Pixelorama hoặc LibreSprite (vẽ tay),
  `pixelart_workbench` (sửa pixel không tốn lượt), `tools/pixelize.py` (về đúng cỡ + bảng màu).
- Không làm: tự cài SD / ComfyUI / Draw Things + LoRA — tốn công thử model, không đáng với dev solo.
- Làm thử trước khi làm hàng loạt: một con cá (cá mú) bằng Gemini → `pixelize.py`, đặt cạnh `fish/muc.png`
  (PixelLab) trong khoang để so; chủ dự án duyệt rồi mới chốt cách cho cả nhóm `fish/` / `dishes/`.
- Trước khi phát hành: kiểm tra điều khoản thương mại từng công cụ (bản free có nơi giới hạn hoặc để ảnh công khai).

## Lưu ý chi phí

- Tính theo lượt tạo. Chế độ thường ~1 lượt; `create_image_pro` và mọi chế độ "pro" 10–25 lượt mỗi lần → chỉ dùng
  cho chân dung. Gọi `get_balance` trước khi làm hàng loạt và báo số dư cho chủ dự án.
- Đừng tạo lại cả loạt khi chỉ cần sửa một chỗ: dùng `edit_image` / `create_character_state`.
- Asset dùng thương mại được trong game theo nguồn bên thứ ba; chủ dự án tự kiểm tra Điều khoản PixelLab.
