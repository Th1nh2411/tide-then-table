# RIN THE FISHER — MVP Build Plan (cho coding agent)

> File này dành cho coding agent. Đọc toàn bộ trước khi viết code.
> Làm **từng Phase một**. Hết mỗi Phase thì DỪNG, tóm tắt những gì đã làm, liệt kê cách test, và chờ người dùng xác nhận rồi mới sang Phase tiếp theo.

---

## 1. Bối cảnh

RIN THE FISHER là game 2D: **ban đêm** (0:00–6:00) Rin thắp đèn câu, lái thuyền ra biển câu hải sản; **sáng** (6:00–15:00) về nhà ngủ; **chiều tối** (15:00–24:00) bán món ăn tại quán hải sản Việt Nam, kiếm tiền để nâng cấp thuyền, dụng cụ và quán.

**Bối cảnh địa lý:** vùng biển hư cấu quanh Xóm Đèn và dải đảo Ngủ Quên (tên tự đặt, không dựa trên địa danh thật nào). Bờ phía nam là làng chài Xóm Đèn và bến; càng ra bắc càng sâu, có các đảo Gò Vỏ Ốc, Đá Canh Đêm; góc đông bắc là vùng sương mù. Chất liệu văn hóa: đèn lồng phố cổ, thuyền thúng, câu mực đêm, tục thờ cá Ông (cá voi) của ngư dân.

**Nhân vật chính (bản ghép với STORY.md):** Rin (nam) tốt nghiệp IT, cùng người bạn thân **Bảo** khởi nghiệp làm app ở thành phố; startup sập, Rin thất nghiệp nằm dài trong phòng trọ, gửi CV không ai gọi. Nhìn gói mì cuối cùng, Rin nhớ hồi ký túc xá Bảo nấu mì ngon nhất tầng → gọi điện rủ Bảo về Xóm Đèn (quê ông nội, còn chiếc ghe của ông) mở quán hải sản vỉa hè: **Bảo đứng bếp, Rin ra khơi câu và làm phục vụ** (cutscene "intro_call" ở phòng trọ khi New Game). Bảo chốt: "tao là bếp trưởng, món nướng mày tự lo". App điện thoại **"Rin's Catch"** (phím J) là phần còn sót lại của startup, Rin sửa lại để quản lý kho, menu, sách cá (Dex), thuyền và sổ sách; app ghi log lỗi khi gặp cá biến dị / tọa độ lạ ("có bug thì phải debug"). Ở quán, Bảo có mặt từ ngày 1 (bỏ cutscene "Bảo tới" cũ): tự nấu món hấp/xào/rau muống theo phiếu; Rin bưng, dọn bàn, nướng món nướng ở lò than (minigame) và rót tháp bia — phục vụ là nơi có nhiều minigame.

**Bí ẩn (bản ghép):** vùng sương đông bắc là nơi một **cổng không gian** dẫn tới một vùng biển song song — "lớp biển bên dưới" mà ông nội Rin từng kể. Cá biến dị (cá thu phát sáng...) là sinh vật lọt qua cổng. **Cá Ông** trong tín ngưỡng ngư dân thật ra là một tộc sinh vật thông minh canh giữ thế giới bên kia (ban đầu tưởng là thù địch vì chúng đẩy thuyền ra khỏi sương). Ông nội và người gác đèn Đá Canh Đêm đã thấy dấu hiệu từ xưa (cổng mở chập chờn); gần đây cổng mở rộng vì một nhà khoa học của **tập đoàn Thâm Lam** (tên tự đặt) vô tình kích hoạt nó, và tập đoàn đang lén khai thác sinh vật bên kia làm nguyên liệu công nghệ. MVP dừng ở lúc Rin bị xoáy nước kéo qua cổng. Hướng màn sau: khám phá biển song song, hiểu ra tộc cá Ông chỉ bảo vệ quê hương, cùng họ đánh sập các cơ sở của Thâm Lam, rồi cổng đóng lại.

- Nhân vật phụ dự kiến (từ STORY.md, chưa làm): chú mèo béo ở bến (thật ra là rồng từ chiều không gian kia), một nhân viên quán (nhân vật nữ chính), một người bạn đến từ thế giới bên kia.
- Manh mối đang có trong game: log lỗi của app, nhật ký người gác đèn, chai thư (ông nội), lời ông từ ở miếu, tin đồn ông Tám, phao lạ của Thâm Lam ở cảnh kết.

**Mục tiêu MVP:** kiểm chứng vòng lặp cốt lõi có vui không:

```
Thắp đèn ra khơi → Tìm điểm câu → Câu (minigame) → Xếp vào khoang (lưới xếp hình)
→ Về bến trước khi cạn dầu đèn → Ngủ → Chuẩn bị menu → Nấu & bán → Nhận tiền → Nâng cấp → Đêm mới
```

Áp lực chính ngoài biển là **dầu đèn câu** (kiểu bình oxy của Dave the Diver, không có đồng hồ đếm giờ): dầu cháy dần và tốn thêm mỗi lượt câu/lưới; ở lâu thì câu được nhiều nhưng cạn dầu ngoài khơi là phải gọi cứu hộ (mất tiền). Cùng với chỗ trong khoang và độ bền thuyền. Giờ hiển thị suy ra từ dầu: đầy = 0:00, cạn = bình minh 6:00.

Người chơi trải hết MVP trong khoảng 15–20 phút. Kết thúc bằng một cảnh ngắn: Rin thấy một xoáy nước phát sáng giữa vùng sương mù ngoài khơi.

Người dùng là dev solo, mới bắt đầu với Godot. Code cần **dễ đọc, dễ sửa, có comment giải thích**, ưu tiên rõ ràng hơn là khéo léo.

---

## 2. Ràng buộc kỹ thuật

- **Engine:** Godot 4.x (bản stable mới nhất, tối thiểu 4.4). KHÔNG dùng API hay cú pháp Godot 3.
- **Ngôn ngữ:** GDScript, có khai báo kiểu (typed GDScript).
- **Không dùng plugin/addon** bên ngoài.
- **Góc nhìn:** màn biển nhìn **từ trên xuống** (top-down). Màn quán nhìn **ngang** (side-view). Minigame câu là UI overlay.
- **Art:** chỉ dùng placeholder (`ColorRect`, `Polygon2D`, `Label`, hình khối màu). Không tạo hay tải ảnh. Mỗi loài hải sản có một màu riêng.
- **Độ phân giải gốc:** 640x360, stretch mode `viewport`, aspect `keep`, bật integer scaling (chuẩn bị cho pixel art). Cửa sổ mặc định 1280x720.
- **Âm thanh:** chưa làm.
- **Nền tảng:** desktop (Windows/macOS/Linux).

---

## 3. Quy tắc cho agent

1. Chỉ làm những gì có trong Phase hiện tại. Không tự thêm tính năng nằm trong mục "Ngoài phạm vi".
2. Mỗi script một trách nhiệm rõ ràng, cố gắng giữ dưới ~200 dòng.
3. Số liệu cân bằng (tốc độ, giá, thời gian) đặt bằng `@export` hoặc trong file Resource, không hardcode rải rác.
4. Giao tiếp giữa các node ưu tiên dùng **signal**; tránh `get_node("../../..")` dài.
5. Dữ liệu game (loài cá, món ăn, nâng cấp, thuyền) dùng **custom Resource** (`.tres`) để dễ thêm/sửa mà không đụng code.
6. Mỗi hệ thống lớn có một scene test chạy độc lập được (F6 trong Godot).
7. Comment trong code bằng tiếng Anh ngắn gọn; giải thích _tại sao_ ở những chỗ không hiển nhiên.
8. Cuối mỗi Phase: cập nhật mục "Tiến độ" ở cuối file này và gợi ý một commit message.

### Quy ước đặt tên

- File và thư mục: `snake_case` (`fishing_spot.gd`, `sea_scene.tscn`)
- Class: `PascalCase` với `class_name`
- Biến và hàm: `snake_case`; hàm private bắt đầu bằng `_`
- Signal: thì quá khứ (`fish_caught`, `customer_left`, `day_ended`)
- Hằng số: `UPPER_SNAKE_CASE`

---

## 4. Cấu trúc thư mục

```
res://
├── autoload/
│   ├── game_state.gd        # tiền, ngày, kho, nâng cấp, cờ cốt truyện
│   ├── day_clock.gd         # giờ trong ngày
│   └── scene_router.gd      # chuyển scene
├── data/
│   ├── resources/           # định nghĩa class Resource
│   │   ├── fish_data.gd
│   │   ├── boat_data.gd
│   │   ├── dish_data.gd
│   │   └── upgrade_data.gd
│   ├── fish/                # file .tres cho từng loài
│   ├── boats/
│   ├── dishes/
│   └── upgrades/
├── systems/
│   └── inventory/
│       ├── grid_inventory.gd    # logic lưới (không phụ thuộc UI)
│       └── inventory_item.gd    # một món trong kho
├── scenes/
│   ├── main_menu/
│   ├── sea/                 # màn biển: boat, map, fishing spots, dock
│   ├── fishing/             # minigame câu
│   ├── restaurant/          # màn quán: customer, cooking minigame
│   ├── ui/                  # HUD, hold UI, upgrade shop, day summary
│   └── test/                # scene test độc lập
└── PLAN.md
```

---

## 5. Input Map

| Action                               | Phím mặc định                                   |
| ------------------------------------ | ----------------------------------------------- |
| `throttle_forward` / `throttle_back` | W / S (+ mũi tên lên/xuống)                     |
| `turn_left` / `turn_right`           | A / D (+ mũi tên trái/phải)                     |
| `cast`                               | Space hoặc chuột trái (dùng trong minigame câu) |
| `interact`                           | E (bắt đầu câu tại điểm câu, cập bến)           |
| `rotate_item`                        | R                                               |
| `open_hold`                          | Tab                                             |
| `pause`                              | Esc                                             |
| `drop_net`                           | Q (thả lưới ốc)                                 |
| `repair_boat`                        | F (sửa thuyền, chỉ khi ở khu bến)               |
| `open_phone`                         | J (app điện thoại Rin's Catch)                  |

---

## 6. Dữ liệu cốt lõi

### Vùng biển (zone)

Map MVP là một vùng biển nhỏ quanh một làng chài, chia thành các vùng theo khoảng cách từ bến:

| Zone        | Vị trí               | Đặc điểm                                             |
| ----------- | -------------------- | ---------------------------------------------------- |
| `NEARSHORE` | Gần bến, nước nông   | Cá dễ, giá rẻ                                        |
| `REEF`      | Quanh các rạn đá     | Cá trung bình, có ốc và cua                          |
| `OPEN_SEA`  | Xa bờ                | Cá lớn, đắt, câu khó                                 |
| `FOG`       | Rìa map, có sương mù | Chỉ có cá biến dị, mở khóa theo cốt truyện (Phase 9) |

### FishData (Resource)

| Field          | Kiểu            | Ghi chú                                             |
| -------------- | --------------- | --------------------------------------------------- |
| `id`           | String          |                                                     |
| `display_name` | String          | Tên tiếng Việt                                      |
| `shape`        | Array[Vector2i] | Các ô chiếm trong lưới, gốc (0,0)                   |
| `color`        | Color           | Màu placeholder                                     |
| `zones`        | Array[Zone]     | Vùng xuất hiện                                      |
| `minigame`     | enum            | `TENSION` (thanh căng dây), `TIMING` (bấm đúng lúc) |
| `difficulty`   | float           | 0.0–1.0, ảnh hưởng tốc độ và độ khó minigame        |
| `base_price`   | int             |                                                     |
| `spawn_weight` | float           | Độ phổ biến                                         |
| `is_aberrant`  | bool            | Cá biến dị, manh mối cốt truyện                     |
| `typical_kg`   | float           | Cân nặng con cỡ trung bình (size 1.0), để hiển thị  |

### Danh sách loài ban đầu

| id                 | Tên              | Hình dạng | Vùng                     | Minigame    | Độ khó | Giá |
| ------------------ | ---------------- | --------- | ------------------------ | ----------- | ------ | --- |
| `oc_huong`         | Ốc hương         | 1x1       | NEARSHORE, REEF          | HAUL (lưới) | 0.1    | 15  |
| `tom`              | Tôm              | 1x2       | NEARSHORE                | TIMING      | 0.2    | 25  |
| `muc`              | Mực              | 1x2       | NEARSHORE, OPEN_SEA      | TENSION     | 0.3    | 30  |
| `ca_thu`           | Cá thu           | 1x3       | OPEN_SEA                 | TENSION     | 0.5    | 40  |
| `cua`              | Cua              | 2x2       | REEF                     | TIMING      | 0.4    | 50  |
| `ca_mu`            | Cá mú            | 2x3       | REEF, OPEN_SEA           | TENSION     | 0.8    | 90  |
| `ca_thu_phat_sang` | Cá thu phát sáng | 1x3       | OPEN_SEA (rất hiếm), FOG | TENSION     | 0.9    | 200 |

> **Đổi cơ chế ngày (sau Phase 9, thay Phase 2):** bỏ đồng hồ giới hạn. Ngày = Đêm (ra khơi, giới hạn bằng dầu đèn: 100 = ~4 phút thật, câu −2, thả lưới −1, kéo lưới −2, minigame không cháy (giờ đứng yên lúc câu), đậu ở bến không cháy, cạn ngoài khơi = cứu hộ −80k) → màn Nghỉ ngơi (giờ cập bến, mẻ cá) → Quán 15:00–24:00 (3 phút thật cố định). Bỏ phạt về trễ. Dầu tự đổ đầy miễn phí mỗi đêm; nâng cấp "Bình dầu đèn" làm bình to hơn: 100 → 140 (150k) → 190 (400k). Lưới đầy sau 90 giây ở biển. Trời đêm xanh đậm, rạng dần khi dầu dưới ~1/3. Bến có cột đèn (PointLight2D, texture gradient) sáng xuyên màu đêm.

> **Đọc chỗ câu + độ sâu + cỡ cá (sau Phase 9):** mỗi điểm câu chọn sẵn 1 loài "chủ" (70% lượt câu ra loài này), bọt nhuộm màu loài đó; prompt hiện "có vẻ là <tên>" nếu loài đã có trong Dex, chưa thì "???". Độ sâu = khoảng cách tới bờ (0 ở bờ, 1 ở mép trên map): càng sâu loài giá cao càng dễ ra (trọng số × (1 + 3 × sâu × giá/giá max), cá biến dị không được cộng) và cá càng to. Điểm "bóng cá lớn" (5% gần bờ → 40% ngoài khơi, tối đa 2 lượt) có bóng cá lượn bên dưới, loài giá cao, cỡ +0.35. Cỡ cá ~ N(1 + 0.25 × sâu, 0.15), kẹp 0.6–1.8; giá món nhân thêm cỡ; cá to khó kéo hơn (zone_scale ÷ (1 + (cỡ−1) × 0.3)). Cân nặng làm tròn (size được chỉnh theo): từ 1kg là kg nguyên (Cá mú 4kg), dưới 1kg là bội 10g (520g); "(to!)" từ 1.3; Dex trên điện thoại ghi kỷ lục mỗi loài (lưu save). Lưới ốc luôn cỡ 1.0. Test: scenes/test/catch_test.tscn.

> **Đèn thuyền + bóng tối (Dredge):** màu đêm tối hẳn (0.13, 0.15, 0.27); thuyền có `BoatLamp` (PointLight2D) bán kính 150px khi đầy dầu → 55px khi cạn, chập chờn dưới 15% dầu. Bọt cá, đá, phao chỉ thấy rõ trong vòng đèn (hoặc đèn bến). Rạng sáng làm cả biển sáng dần.

> **Đơn đặt cá (Dave the Diver):** mỗi sáng 70% có tin nhắn đặt cá (tối đa 2 đơn, mỗi khách 1 đơn) — loài câu đã có trong Dex (Dex trống: loài gần bờ), cỡ yêu cầu 1.0/1.2/1.4 (làm tròn ký), thưởng = giá gốc × cỡ × 2.5 (làm tròn 10k), hạn 2 đêm. Đơn hiện ở HUD biển (dưới tiền) và tab "Đơn" của điện thoại. Đầu ca bán, con nhỏ nhất đủ ký trong kho được **để riêng** và khách quen (áo xanh, bóng thoại vàng, kiên nhẫn x2) **tới quán gọi món nấu từ con cá đó** (món đầu tiên trong menu có loài đó); nấu xong trả tiền đơn × hệ số nấu (hoàn hảo x1.3). Không phục vụ thì cá trả về kho; hết ca của ngày cuối hạn mà chưa phục vụ thì khách hủy (ghi trong bảng tổng kết). Màn sáng chỉ báo "có cá rồi / chưa có cá". Lưu trong save. Logic: `FishOrders`; test: scenes/test/orders_test.tscn.

> **Điểm ghé trên bản đồ (Dredge):** mỗi điểm có đèn riêng (thấy được trong đêm), tên vẽ trên map, ghé bằng E khi thuyền chậm; hộp thoại `PoiDialog` (tạm dừng game, chọn bằng phím số/click, E/Esc đi tiếp). Điểm câu tự tránh xa các điểm ghé.
>
> - **Miếu Cá Ông** (bờ Xóm Đèn): thắp nhang 10k → đêm đó va đá chỉ hư 50%. Lời ông từ đổi theo cốt truyện (trước điềm báo / sau điềm báo / sương mở).
> - **Chòi ông Tám** (Gò Vỏ Ốc): vá thuyền giữa biển +25 bền / 40k (đắt hơn ở bến); hỏi chuyện = mẹo chơi + tin đồn cốt truyện theo giai đoạn.
> - **Hải đăng Đá Canh Đêm** (sát vùng sương): đèn quét xoay; nhật ký người gác đèn, mỗi lần ghé đọc 1 trang (lưu trong story_flags); đọc được 2 trang trước điềm báo, 3 sau điềm báo, 4 khi sương mở.
> - **Bè tôm hùm anh Năm** (rạn đá): bán hết khoang ngay ngoài biển với 50% (giá gốc × cỡ × chất lượng) để lấy chỗ.
>   Test: scenes/test/places_test.tscn (logic thuần; ghé thử cần màn biển nên kiểm bằng test tạm).

> **Bản đồ trên điện thoại (tab "Bản đồ"):** màn biển chụp bố cục map (vùng nước, bờ, đảo/đá, bến, điểm ghé) vào snapshot tĩnh lúc vào biển, nên ở quán vẫn xem được. Ngoài biển hiện thêm thuyền (mũi tên theo hướng) và lưới đang thả. Vùng sương: trước điềm báo không có gì, sau điềm báo nháy "[ERR] NaN" ở góc đông bắc, khi mở thì hiện vùng sương + "???" ở xoáy nước. Click lên bản đồ để ghim/bỏ ghim (tối đa 5, lưu trong save); ghim hiện thành mũi tên "Ghim N" ở mép màn hình khi ra khơi.

> **Đi đêm thêm chiều sâu (sau Phase 9):**
>
> - **Tầm đi theo thuyền** (`BoatData.max_depth`, `BoatRange`): thuyền thúng 0.32 (gần bờ + mép rạn), ghe chèo 0.6 (rạn đá + mép khơi), ghe máy 1.0 (cả map). Vượt vạch sóng (bọt trắng, cả trên bản đồ điện thoại) thì bị đẩy lùi 90px/s và giới hạn tốc độ 20. Chòi ông Tám, hải đăng và vùng sương cần ghe máy; bè tôm hùm thuyền thúng tới được.
> - **Đá ngầm**: 12 viên `Rock.submerged` ở rạn đá và ngoài khơi, chỉ vẽ ở chỗ có đèn chiếu (CanvasItemMaterial LIGHT_ONLY), không có trên bản đồ.
> - **Thời tiết** (`WeatherData` trong data/weather/, `WeatherController`): chọn ở màn sáng cho chuyến kế tiếp, hiện dự báo ở màn sáng + log điện thoại + cạnh đồng hồ ở biển; đêm 1 luôn lặng. Lặng (x3): không gì. Trăng (x2): trời sáng x1.8, mực x3. Gió (x2): trôi 22px/s hướng ngẫu nhiên, dầu x1.15. Mưa (x2): đèn x0.7, trời tối x0.8, rarity +3, +1 điểm câu/vùng, vệt mưa trên màn hình.
> - **Sự kiện đêm** (`NightEvents`, từ đêm 2, 1–2 sự kiện khác loại, chỉ trong tầm thuyền): ghe chết máy (E: kéo về → thuyền chậm x0.65, cập bến +80k; bị cứu hộ thì không tiền), chai thư (5 trang truyện về "lớp biển bên dưới", lưu story_flags; hết trang thì bán ve chai 5k), đàn sứa phát sáng (trôi chậm, trong đàn -3 bền mỗi 1.5s), đàn cá heo (lại gần thì bơi tới điểm câu tốt nhất trong tầm — ưu tiên bóng cá lớn — chờ 25s rồi đi). Ghi chú cuối chuyến hiện ở màn sáng (`GameState.trip_notes`).
> - **Dỡ cá ở bến**: khi đậu ở bến hiện **nút cố định** góc phải: "Dỡ N con vào kho [E]" (đêm vẫn tiếp tục) và "Về nhà ngủ →" (hết đêm; ghi số lưới sẽ bỏ lại). Cá dỡ giữa đêm vào kho ngay (`GameState.unload_catch`, `trip_catch`) và vẫn tính vào mẻ đêm nay ở màn sáng. Khoang vẫn giới hạn mỗi chuyến; cái giá là dầu cho quãng đường quay về.
> - **Không tự chuyển cảnh** (kiểu Dave the Diver): đêm chỉ hết khi bấm "Về nhà ngủ" (trừ khi bị cứu hộ kéo về); màn sáng có nút "Dậy mở quán"; vào quán không tự bật bảng menu — nút cố định **"Chuẩn bị menu"** mở bảng (có "Đóng" để làm việc khác trước, kế hoạch menu được giữ), quán mở khi bấm "Mở quán" trong bảng; hết ca → bảng tổng kết → "Đóng" → nút cố định **"Ra khơi →"**. Nút **"Sửa quán"** hiện trong quán lúc không phục vụ (trước khi mở và sau khi đóng).
> - **Hướng dẫn**: chữ hướng dẫn trên màn hình (gợi ý minigame câu/nấu, khoang, bếp, hộp thoại, bảng menu, "[E] Vào bếp", gợi ý dưới điện thoại) chỉ hiện **ngày 1**; ngày 1 có hướng dẫn theo bước ở biển (`TutorialHints`) và ở quán (`RestaurantTutorial`: mở quán → vào bếp → nấu → món lên kệ → bàn bẩn → buổi tối). Toàn bộ điều khiển nằm trong màn **"Hướng dẫn"** (`HelpPanel`: Biển / Quán / Điện thoại / Mẹo), mở từ menu tạm dừng (Esc) và menu chính. Đã lược: "[J] điện thoại" cạnh tiền, "[E]" trên nút bến, nhắc ở bến, thông báo khi bấm E sai chỗ.
> - **Hội thoại (khung chung)**: `Dialogue` (.tres trong data/dialogues/, kịch bản dạng chữ "Tên: lời thoại", điều kiện: từ ngày, cần cờ, nói 1 lần, bật cờ khi xong, độ ưu tiên) → `DialogueLibrary` (thuần: tách dòng, chọn đoạn, nhớ đã xem trong story_flags → được lưu) → `Talker` (gắn vào nhân vật: danh sách đoạn + câu nói vặt) → `DialogueBox` (khung dưới màn hình, chữ chạy, E/Space/click qua câu, Esc bỏ qua, tạm dừng game). Trong quán Rin đi tự do (A/D) cả lúc chưa mở / đã đóng; E cạnh người có Talker để nói chuyện. Hiện có Bảo: app báo lỗi (ngày 2), con mèo ở bến (ngày 3, bật cờ `heard_about_cat`), ánh sáng xanh (sau điềm báo) + câu nói vặt. Test: scenes/test/dialogue_test.tscn.
> - **Cutscene kiểu Stardew Valley** (`Cutscene` = Dialogue có kịch bản lệnh, data/cutscenes/; `CutsceneScript` tách lệnh; `CutscenePlayer` diễn ngay trong thế giới: tạm dừng game, ẩn HUD, camera riêng trượt/zoom tới điểm đánh dấu `CutsceneMarkers`, `CutsceneActor` đi lại + biểu cảm ! ? ... tim nốt nhạc, khung thoại có chân dung + lựa chọn, mờ dần; Esc bỏ qua nhưng vẫn giữ cờ / tên mặc định / lựa chọn đầu). Lệnh: fade_in/out, tint, camera, spawn, move_to, face, emote, speak, narrate, choice/label/goto, pause, name_pet, set_flag.
> - **Bảo tới quán**: cutscene "bao_arrival" sau khi đóng bảng tổng kết ca ngày 1 (trong quán, nhân vật phóng to 1.6x): Bảo đẩy cửa vào, gặp lại Rin, xin làm phục vụ → cờ `bao_joined`; ngày 1 không có Bảo (`Waiter.is_hired()`: có cờ hoặc từ ngày 2 — cho save cũ), hướng dẫn ngày 1 chỉ cách tự bưng / tự dọn.
> - **Mèo của quán**: cutscene "cat_arrival" sau khi kết thúc đêm 2 (rạng sáng ở bến): mèo mập ăn vụng cá (chỉ trong phim, không mất cá) → Rin vuốt ve → nhận nuôi, người chơi đặt tên (mặc định "Mỡ", cờ `pet_name`, `cat_adopted`). Từ đó mèo ngồi trước quầy (`PetCat`), nói chuyện được (có "!"), "mèo chiêu tài" khách kiên nhẫn x1.1; Bảo có thoại về mèo (ngày 3); mèo ấm bất thường (ngày 4), nhìn về đông bắc sau điềm báo; app báo "[WARN] cảm biến nhiệt: sinh vật trong quán 60°C". Chưa làm: mèo biến mất sau điềm báo, bóng rồng ở cảnh kết.
> - **Nâng cấp trong điện thoại** (tab "Nâng cấp" = app "Chợ Đồ Nghề"): chỉ bán **đồ nghề đi biển** (thuyền, cần câu, đèn), mua được ở mọi nơi (J), có hiệu lực từ chuyến sau.
> - **Sửa quán** (kiểu Dave the Diver): nút cố định "Sửa quán" khi quán không phục vụ (trước giờ mở / sau khi bán xong). Vào chế độ sửa: ẩn người và bảng; bàn ghế, trang trí, bếp, tủ lạnh có viền xanh nhấp nháy; click đồ → danh sách cấp (cấp đang có / +giá), chọn là **xem trước** ngay (số bàn, đèn lồng/tranh/hoa, bếp than → gas → bếp công nghiệp có chụp hút, tủ lạnh to dần). Thanh dưới: "Hủy" (trả về như cũ) / "Xác nhận (-Xk)" (khóa nếu thiếu tiền). Chỉ nâng lên, không hạ. Áp dụng ngay cho ca hôm nay nếu sửa trước giờ mở (`RenovationMode`).
>   Test: scenes/test/night_test.tscn.

> **Quán nâng cấp + lưu 2 lần:**
>
> - **Bàn ghế** (150k/400k): 4 → 6 → 8 bàn, bàn đặt vào các chỗ có sẵn trên vỉa hè (`StreetRoom.setup_tables`).
> - **Đèn lồng & trang trí** (200k/500k): khách tới nhanh hơn (khoảng cách x0.85 / x0.72), khách sang 15% / 30% (áo vàng, cà vạt, trả x1.5, kiên nhẫn x0.75); cấp 1 treo đèn lồng, cấp 2 thêm tranh + chậu hoa.
> - **Bếp** (180k/450k): minigame nấu chạy chậm x0.85 / x0.72 (dễ hoàn hảo).
> - **Phục vụ kiểu Dave the Diver** (luật phục vụ vẫn dùng; phần bố cục/điều khiển góc ngang bên dưới đã được thay bằng quán vỉa hè ở mục kế tiếp): khách vào → ngồi đọc menu 1.5–3s → gọi món (chỉ món còn phục vụ được: phần còn lại + món trên kệ − phiếu đang chờ; hết thì gọi rau muống) → chờ (kiên nhẫn 45s, chỉ giảm lúc chờ) → ăn 4–6s → trả tiền + tip → bàn **bẩn**. **Bếp nằm ngay trong quán** (không có màn hình bếp riêng): Rin đi A/D vào khu bếp bên trái; **bảng menu đánh số** trên tường bếp (tên món + số phần còn lại; món hết vẫn giữ số, mờ đi; rau muống; khách quen viền vàng ở cuối); **bấm số hoặc click** dòng nào thì nấu món đó (không dùng E để nấu); minigame hiện thu nhỏ ở góc trên trái phía trên bếp (quán vẫn chạy, Rin đứng yên khi nấu); món lên **kệ bếp** (4 chỗ); **đứng trước đĩa** trên kệ (mũi tên xanh nhỏ chỉ đĩa, nhắc ghi bàn nào gọi) bấm E để cầm, **E ở sọt rác** vứt món đang cầm, E ở bàn đặt món. Thanh **phiếu order** ở trên cùng (viền xanh = món đã có trên kệ). **Không dùng chữ nhắc**, chỉ dấu hiệu (`ServiceMarkers`): cầm món thì bàn gọi món đó + phiếu của nó nhấp nháy viền xanh kèm mũi tên; món không ai gọi thì sọt rác viền đỏ; đứng trước đĩa thì mũi tên xanh trên đĩa và bàn của nó sáng mờ; phím "E" nhỏ hiện trên chỗ E sẽ tác động (sọt rác, bàn đúng, bàn bẩn). **Bảo** tự bưng theo thứ tự khách vào, rảnh thì dọn bàn bẩn; **E ở bàn bẩn**: Rin dọn. Đóng quán (sớm hoặc hết giờ): không nhận khách mới, khách trong quán vẫn được phục vụ và ăn xong mới về (hoặc tự bỏ về khi hết kiên nhẫn), bếp vẫn mở tới khi khách cuối rời quán; món còn trên kệ bỏ đi. (`DishShelf`, `DiningTables`, `KitchenStation`, `Waiter`, `RinWalker`, `ShelfDisplay`; test: scenes/test/restaurant_test.tscn)
> - **Quán vỉa hè nhìn từ trên xuống (3/4)** — thay hẳn quán góc ngang: ô 16px chuẩn Stardew, 40x23 ô phủ kín màn hình (cửa sổ 1920x1080, F11 toàn màn hình). Mặt tiền nhà (cửa cuốn, biển "HẢI SẢN TƯƠI SỐNG", mái hiên sọc, xe máy dựng) ở trên, **vỉa hè rộng** ở giữa (bàn 2x2 ô `StreetRoom.TABLE_SIZE`, 2 ghế nhựa phía trên: ghế khách + ghế phụ, khách ngồi quay mặt ra đường; 8 chỗ bàn xếp 2 hàng x 4 cột, 4 bàn đầu là 2 cột sát xe đẩy, mỗi cấp Bàn ghế mở thêm 1 cột bên phải (4 → 6 → 8 bàn) — sau này mở rộng tiếp sang phải), mép dưới chỉ thấy **một phần đường** (làn gần + nửa làn xa, xe máy chạy qua). Bếp lộ thiên bên trái: thùng đá (nâng cấp Tủ lạnh: thùng xốp → thùng nhựa → tủ đông), **xe đẩy có bếp trên xe** (rộng 4 ô, chỉ hàng bánh xe chặn đường, mặt bàn vẽ cao thêm 1 ô và y-sort với người: Rin đứng sau xe bị xe che chân; nâng cấp Bếp: lò than → bếp ga → bếp ga đôi; tủ kính + biển đỏ quay ra đường), **bàn kê món đặt dọc cạnh xe** (5 ô, mỗi ô 1 đĩa). Rin đi **WASD**, **Shift lướt** (dash ~3 ô, hồi 0.45s, vệt gió + bụi), **E** vào ô đang quay mặt (viền trắng + phím E nhỏ); đứng gần xe đẩy mà bấm số / click món trên **hàng món luôn hiện trên cùng** (mờ khi xa xe) thì Rin tự ra **sau bếp, quay mặt ra đường** nấu; minigame hiện nhỏ đè lên mặt đường; món nấu xong nằm trên tay Rin → tự mang ra bàn (bàn gọi món đó nhấp nháy xanh) hoặc đặt lên bàn kê (bản cũ — nay Rin chỉ nướng ở lò than, xem "Đổi vai"). Khách phần lớn **đi xe máy tới** (chạy dưới đường → đỗ sát lề, đầu xe ra đường → đi bộ vào bàn → ăn xong ra xe chạy đi), số còn lại đi bộ dọc vỉa hè. **Đổi vai (sau này):** Bảo là đầu bếp đứng sau bếp trên xe đẩy từ ngày 1 (`ChefBao`): tự nấu món hấp/xào/rau muống theo phiếu cũ nhất, có thanh tiến độ + chảo + hơi nóng, xong để lên bàn kê (đầy thì chờ), hết rau thì hô Rin sang tạp hoá; tốc độ/chất lượng theo nâng cấp Bếp (7s → 5.5s → 4s, x1.0 → x1.15). Rin là phục vụ: tự bưng, dọn bàn, **nướng** món nướng ở **lò than** `N` ngay dưới xe đẩy (minigame) và rót tháp bia; trên hàng món, món của Bảo có ô "B" cam, món của Rin có số. Bàn khách (bàn inox có giấy, tương ớt, nước mắm; bàn y-sort với người như xe đẩy; ghế chặn người đi, A* chỉ mở ghế ở đầu đường đi cho khách ngồi/rời); xe máy cỡ thật (~32px, người lái cao như nhân vật). Trang trí: dây đèn (cấp 1), + chậu cây cạnh bàn (cấp 2). **Tạp hoá Cô Năm** bên phải (tiệm mở cửa, mái hiên xanh; quầy `V` + két `G` trên vỉa hè, `MarketStall` + `MarketStock`): rau muống và bia con mèo luôn có trên menu, Rin đứng dọc trước quầy (2 hàng, quay hướng nào cũng được, `MarketStall.reach`) bấm E mở danh sách hàng — các ô quầy không tương tác, phím E hiện trên đầu cô; bia không cần nấu (`DishData.instant_serve`: bấm số ở bếp là cầm ra) (`MarketPanel`, hiện chỉ có rau; nút "Mua" hoặc phím 1-9 = 1 phần 10k, E/Esc đóng; mua trước giờ mở hoặc giữa ca, quán vẫn chạy); nấu/lấy món trừ 1 phần, hết thì báo "sang tạp hoá mua"; rau thừa bỏ cuối ngày, bia (`keeps_overnight`) để dành qua ngày — lưu trong `GameState.pantry` (save); mỗi lần mua = `market_pack` phần (bia: bình 20 lít 150k, kho tính theo lít, mỗi tháp `portion_units` 3 lít), tiền mua tính vào "Tiền chợ". Hàng nút ghim (Sửa thuyền / Chuẩn bị menu / Sửa quán) dời sang giữa mặt tiền để không che tạp hoá. **Bố cục (sắp xếp lại):** **bếp ở giữa vỉa hè** — hàng sau là thùng rác + xe đẩy (Bảo đứng sau bếp) + bàn kê món nằm ngang 5 ô; trước đó là lối đi trống rộng 2 ô; thùng đá ở góc trên bên trái bếp; bình bia (vòi rót tháp) đặt trên đầu phải xe đẩy; hàng trước là lò than 2 ô bắt đầu thẳng mép trái xe đẩy (đứng trước lò thì viền trắng bao cả lò) (Rin đứng ở lối đi quay xuống để nướng / rót). **Bàn ghế bên trái** (4 cột x 2 hàng, cách nhau 2 ô), nâng cấp mở bàn gần bếp trước. Tạp hoá vẫn bên phải. Màn quán không hiện giờ, tiền hay dòng kho (kho xem trong phone). Tường mặt tiền cao 5 hàng ô (bỏ bớt 1 hàng đường dưới cùng; 2 làn xe ở hàng 19/21, vạch giữa hàng 20). **Bỏ nút "Chuẩn bị menu"**: bấm chuột vào bảng hiệu LED để chọn món (trước giờ mở quán bảng có viền vàng nhấp nháy + mũi tên nhún nhảy; rê chuột vào thì viền sáng dày hơn, bảng nhích lên, con trỏ bàn tay). **Bảng LED menu nhỏ** (`MenuBoard`, ô `E` 4 ô sát lề đường ở giữa, trước bếp, cao 40px, y-sort với người; sàn dưới bếp không tô tối nữa): chữ chạy "QUÁN RIN & BẢO · HẢI SẢN TƯƠI SỐNG" (đo độ rộng thật), hình các món hải sản + số phần, hết = mờ + X đỏ; phiếu order ở mép trên bên trái. Không còn hàng ô món / phím số: **E ở lò than** = nướng món nướng của phiếu cũ nhất đang chờ, **E ở vòi bia** (`U`, bình bia cạnh thùng đá) = rót tháp cho bàn gọi bia sớm nhất; không ai gọi thì báo; phím E hiện trên lò / vòi khi có việc. **Thùng rác 1 ô** ngay bên trái xe đẩy, sát chỗ đứng nấu: E vứt món đang cầm; cầm món không ai gọi thì xô nhấp nháy đỏ (món thừa trên bàn kê bỏ đi lúc đóng quán). (`StreetRoom`, `RoomGrid`, `StreetBackdrop`, `StreetProps`, `StreetPerson`, `RinChef`, `Waiter`, `Customer`, `CustomerBikes`, `KitchenStation`, `ServiceHud`, `ServiceMarkers`)
> - **Lưu 2 lần**: lúc ra khơi (tiếp tục ở biển) và ở màn sáng sau chuyến câu (tiếp tục ở quán, `resume_at`). SAVE_VERSION 2.

> **Tiện ích (sau Phase 9):** Esc = menu tạm dừng (Tiếp tục / Về menu — bấm 2 lần / Thoát + bảng phím) ở biển và quán. Mũi tên mép màn hình chỉ Bến, Lưới, và xoáy nước "???" kèm khoảng cách (m). Ngày 1 có gợi ý theo ngữ cảnh. "Chơi mới" khi đã có save phải bấm 2 lần.

> **Thân thuyền (sau Phase 9):** đâm đá/đảo nhanh hơn 25px/s thì mất độ bền (0.3%/px/s, đâm chéo nhẹ hơn). Dưới 50% thuyền chậm dần (tối thiểu 60% tốc độ). 0% = hư: cứu hộ kéo về (-150k, +1 giờ game). Sửa: thúng 2.5k/%, ghe chèo 4k/%, ghe máy 7k/%, sửa được bao nhiêu theo tiền có; sửa ở quán (nút) hoặc ở khu bến (F), không sửa khi đang ra khơi. Sáng ra thuyền còn hư thì không chạy được tới khi sửa. Độ bền được lưu.

> **Câu lâu hơn (sau Phase 9):** câu cần có 2 giai đoạn: **chờ cá cắn** (phao nhấp = cá rỉa, phao chìm hẳn = giật; giật sớm 1 lần được tha, 2 lần cá bỏ đi; không giật kịp = mất mồi) rồi mới đánh cá. TENSION có 3 giai đoạn theo thời gian vật lộn, không có thanh sức (vùng vẫy mạnh + lao bứt có báo trước → giằng co → đuối sức; cá khó: khỏe 5s, đuối từ 10s; cá dễ: 2s / 4.5s), ra ngoài vùng xanh thì thanh kéo tụt. Màn hình chỉ còn 2 thanh: Kéo, Dây. Đồng hồ đứng yên khi câu (dầu không cháy). Nút/phím **Khoang [Tab]** trong lúc câu sẽ tạm dừng game.

> **Bắt bằng lưới (thêm sau Phase 6):** loài có `catch_method = NET` (hiện là ốc hương) không ra ở điểm câu. Bấm Q để thả lưới ở vùng có loài đó, ngâm càng lâu càng nhiều (đầy sau 3 giờ game, tối đa 8 con), rồi quay lại phao bấm E để chơi minigame **Kéo lưới**: giữ để kéo, dây đỏ (vướng đá) thì nhả, kéo cố sẽ rơi ốc. Thuyền mang 2 lưới; lưới còn ngoài biển khi cập bến sẽ mất ốc.

### BoatData (Resource)

`id`, `display_name`, `max_speed`, `acceleration`, `turn_speed`, `spin_drift: float` (mức xoay trôi khi bẻ lái; cao = khó lái), `hold_size: Vector2i`.

| Thuyền       | Tốc độ | Xoay trôi | Khoang | Ghi chú                                                                                            |
| ------------ | ------ | --------- | ------ | -------------------------------------------------------------------------------------------------- |
| Thuyền thúng | chậm   | cao       | 4x3    | Thuyền khởi đầu. Bẻ lái là bị xoay vòng, khó đi thẳng — cố ý tạo cảm giác vui và lý do để nâng cấp |
| Ghe chèo     | vừa    | thấp      | 5x4    |                                                                                                    |
| Ghe máy      | nhanh  | rất thấp  | 6x5    |                                                                                                    |

### DishData (Resource)

`id`, `display_name`, `ingredients: Dictionary` (fish_id → số lượng), `cook_type: enum { GRILL, STEAM, STIR }`, `base_price: int`.

| Món                    | Nguyên liệu                                              | Kiểu nấu | Giá |
| ---------------------- | -------------------------------------------------------- | -------- | --- |
| Ốc hương nướng mỡ hành | 3 ốc hương                                               | GRILL    | 70  |
| Mực hấp gừng           | 1 mực                                                    | STEAM    | 60  |
| Cá thu nướng           | 1 cá thu                                                 | GRILL    | 80  |
| Tôm rang muối          | 2 tôm                                                    | STIR     | 75  |
| Cua rang me            | 1 cua                                                    | STIR     | 110 |
| Cá mú hấp xì dầu       | 1 cá mú                                                  | STEAM    | 150 |
| Rau muống xào tỏi      | Luôn có trên menu; rau mua ở tạp hoá Cô Năm 10k/phần, thừa bỏ đi cuối ngày | STIR     | 30  |
| Tháp bia con mèo        | Luôn có; bia hơi mua ở tạp hoá theo bình 20 lít 150k, 1 tháp = 3 lít; phục vụ ngay (minigame rót tháp: chờ chọn), thừa để dành (lưu `GameState.pantry`) | —        | 25  |

> **Menu & phạt (thêm sau Phase 6):** trước ca chọn tối đa 3 món hải sản; rau muống luôn có (không chiếm slot). ~25% khách gọi rau muống / bia; hết hải sản thì khách chỉ gọi rau muống / bia (chuẩn bị kém = thu ít). (Đậu phộng rang đã bỏ.) Menu ít món bị chê đơn điệu: giá mọi món x0.8 (0–1 món), x0.9 (2 món), x1.0 (3+ món). Có nút "Đóng quán sớm".

### UpgradeData (Resource)

`id`, `display_name`, `description`, `levels: Array[int]` (giá từng cấp), `values: Array` (giá trị từng cấp).

| Nâng cấp     | Ảnh hưởng                                                  |
| ------------ | ---------------------------------------------------------- |
| Thuyền       | Thuyền thúng → Ghe chèo → Ghe máy (đổi `BoatData`)         |
| Cần câu      | Nới rộng vùng xanh trong minigame, giảm tốc độ giãy của cá |
| Tủ lạnh quán | Giảm tốc độ mất độ tươi của đồ trong kho                   |

### InventoryItem

`fish: FishData`, `quality: float` (0.7 hoặc 1.0, từ kết quả câu), `size: float` (cỡ cá, 1.0 = trung bình, 0.6–1.8; hiển thị bằng kg), `freshness: float` (100 → 0), `rotated: bool`, `grid_pos: Vector2i`.

---

## 7. Các Phase

### Phase 0 — Khởi tạo project

- Tạo `project.godot` với thiết lập ở mục 2, input map ở mục 5.
- Tạo cấu trúc thư mục ở mục 4 và `.gitignore` chuẩn cho Godot 4 (bỏ qua `.godot/`).
- Tạo autoload `GameState` (money, day, storage, upgrade levels, story flags), `DayClock` (chưa cần logic, chỉ khung), `SceneRouter` (`go_to(scene_path)` có fade đen đơn giản).
- Main menu placeholder: nút "Chơi mới" → vào màn biển, "Thoát".

**Xong khi:** mở project không lỗi, chạy được main menu, bấm "Chơi mới" chuyển sang một scene biển trống.

### Phase 1 — Lái thuyền

- Map biển top-down: nền nước, đất liền và vài hòn đảo/rạn đá là vật cản có collision, một bến tàu cạnh làng chài. Các zone được tô màu nước khác nhau (nông = nhạt, xa bờ = đậm). Rìa map có biên chặn.
- `Boat` là `CharacterBody2D` điều khiển kiểu xe: W/S tăng giảm ga (có quán tính, trôi dần khi nhả ga), A/D bẻ lái. Thông số lấy từ `BoatData`.
- **Xoay trôi (spin drift):** khi bẻ lái, thuyền nhận thêm vận tốc góc tỉ lệ với `spin_drift` và giảm dần sau khi nhả phím. Thuyền thúng phải có cảm giác xoay vòng rõ rệt nhưng vẫn điều khiển được.
- Va chạm đá/đảo thì thuyền nảy nhẹ và giảm tốc.
- `Camera2D` đi theo thuyền, giới hạn trong map.
- Tạo 3 file `BoatData` ở mục 6 và một cách tạm để đổi thuyền khi test (phím debug).

**Xong khi:** lái được cả 3 loại thuyền, thuyền thúng rõ ràng khó lái hơn ghe máy, không ra khỏi map.

### Phase 2 — Thời gian trong ngày và về bến

- `DayClock`: một ngày ngoài biển kéo dài từ 6:00 đến 18:00 (giờ trong game), tương ứng 4 phút thực. HUD hiện đồng hồ.
- Màu màn hình ngả dần sang cam lúc chiều (dùng `CanvasModulate`).
- Lái thuyền vào vùng bến và bấm `interact` → kết thúc ngày đi biển, đồ trong khoang chuyển vào kho (`GameState.storage`), sang màn quán.
- Quán mở lúc 18:00. Về sau 18:00 vẫn được, nhưng mỗi giờ trễ (tối đa đến 21:00) làm ca bán ngắn đi 25%. Qua 21:00 thì tự động kéo thuyền về và ca bán còn ngắn nhất.
- Từ 17:00 HUD nhắc "Sắp tới giờ mở quán".

**Xong khi:** về bến đúng giờ, trễ giờ, và bị kéo về đều hoạt động; thời lượng ca bán được truyền sang màn quán đúng.

### Phase 3 — Điểm câu và dữ liệu cá

- Tạo các file `.tres` cho các loài ở mục 6 (trừ cá của zone FOG chưa cần xuất hiện).
- `FishingSpot`: vùng bọt nước nhấp nháy trên mặt biển. Mỗi zone có một số điểm câu ngẫu nhiên đầu ngày.
- Mỗi điểm câu có 2–4 lượt câu, hết lượt thì điểm biến mất (gợi ý đánh bắt có giới hạn). Điểm mới xuất hiện lại vào ngày hôm sau.
- Thuyền dừng gần điểm câu (tốc độ thấp) thì hiện gợi ý "E: Câu". Bấm → chọn ngẫu nhiên một loài theo zone và `spawn_weight` → mở minigame ở Phase 4.
- Trong lúc câu, `DayClock` vẫn chạy (mỗi lần câu tốn thời gian).

**Xong khi:** điểm câu xuất hiện đúng zone, hết lượt thì biến mất, loài được chọn đúng theo bảng.

### Phase 4 — Minigame câu

Minigame là UI overlay, thuyền đứng yên trong lúc câu.

- **TIMING:** một kim chạy qua lại trên thanh ngang, có vùng xanh nhỏ ở vị trí ngẫu nhiên. Bấm `cast` khi kim trong vùng xanh. Cần trúng 2–3 lần (tùy `difficulty`), trượt 2 lần là cá thoát.
- **TENSION:** thanh căng dây có một vùng xanh di chuyển ngẫu nhiên (cá giãy). Giữ `cast` làm kim dâng lên, nhả ra kim tụt xuống. Giữ kim trong vùng xanh để tăng thanh "kéo cá"; ở ngoài vùng xanh quá lâu thì thanh "độ bền dây" giảm. Đầy thanh kéo = bắt được, hết độ bền = đứt dây.
- `difficulty` điều chỉnh tốc độ kim, kích thước vùng xanh, độ giãy. Nâng cấp cần câu làm vùng xanh rộng ra.
- Kết quả: câu hoàn hảo (không trượt lần nào / không bao giờ ra khỏi vùng xanh) → `quality` 1.0, còn lại → 0.7.
- Cá biến dị có minigame nhấp nháy màu lạ để người chơi nhận ra.

**Xong khi:** cả hai minigame chơi được, độ khó khác nhau rõ giữa các loài, quality ghi đúng.

### Phase 5 — Khoang thuyền lưới xếp hình

- `GridInventory` là class logic thuần: `can_place(item, pos)`, `place(item, pos)`, `remove(item)`, `find_free_spot(item)`, hỗ trợ xoay 90 độ.
- Viết scene test cho `GridInventory` với vài trường hợp: đặt vừa, đặt chồng, xoay, ra ngoài biên.
- Kích thước khoang lấy từ `BoatData.hold_size`.
- Câu được cá: tự tìm chỗ trống; nếu không còn chỗ thì mở UI khoang (game tạm dừng, đồng hồ dừng) để người chơi sắp xếp lại, xoay (`rotate_item`), hoặc bỏ bớt món. `open_hold` mở khoang bất cứ lúc nào (đồng hồ vẫn chạy).
- UI hiển thị mỗi món là một khối màu theo hình dạng, kéo-thả bằng chuột.

**Xong khi:** xếp, xoay, kéo-thả, bỏ món đều hoạt động và không đặt chồng lên nhau được.

### Phase 6 — Quán ăn

- Màn quán nhìn ngang: quầy bếp, 4 bàn nhựa, cửa ra vào.
- Khách đến theo khoảng thời gian ngẫu nhiên, ngồi vào bàn trống, hiện bong bóng món muốn gọi (ưu tiên món mà kho đủ nguyên liệu; nếu không có món nào nấu được thì khách gọi ngẫu nhiên và sẽ bỏ đi).
- Mỗi khách có thanh kiên nhẫn giảm dần. Hết kiên nhẫn thì bỏ đi, điểm đánh giá ngày giảm.
- Click vào khách → nấu món đó → minigame theo `cook_type`:
    - `GRILL`: kim chạy qua thanh, bấm khi kim ở vùng "chín tới". Bấm hai lần (hai mặt).
    - `STEAM`: giữ nút, thả ra đúng lúc thanh thời gian vào vùng xanh.
    - `STIR`: bấm liên tục cho đầy thanh trong thời gian giới hạn.
- Kết quả nấu: Hoàn hảo (x1.3), Ổn (x1.0), Hỏng (x0.5).
- Giá bán = `base_price` × kết quả nấu × trung bình `quality` nguyên liệu × hệ số độ tươi. Khách được phục vụ khi còn trên 50% kiên nhẫn thì cho thêm tip.
- Ca bán mặc định 3 phút thực, bị rút ngắn nếu về trễ (Phase 2). Có đồng hồ hiển thị.

**Xong khi:** một ca bán hoàn chỉnh chạy được từ đầu đến cuối, tiền tính đúng công thức, thời lượng ca đúng theo giờ về bến.

### Phase 7 — Vòng ngày và nâng cấp

- Hết ca bán → bảng tổng kết: tiền kiếm được, số khách phục vụ, số khách bỏ đi, đánh giá (1–5 sao).
- Đánh giá cao làm tăng tần suất khách ngày hôm sau.
- Sau tổng kết → cửa hàng nâng cấp (mục 6) → ngày mới bắt đầu ở bến lúc 6:00.
- Mỗi ngày trôi qua, `freshness` của mọi món trong kho giảm 35 (nâng cấp tủ lạnh giảm con số này). Hệ số độ tươi: trên 60 = x1.0, 30–60 = x0.7, dưới 30 = x0.4, bằng 0 thì hỏng và tự bỏ khỏi kho.
- HUD màn quán hiển thị kho kèm độ tươi.

**Xong khi:** chơi liên tục nhiều ngày, nâng cấp có hiệu lực ngay ngày kế tiếp (đổi thuyền đổi cả cảm giác lái và kích thước khoang), đồ trong kho ươn dần.

### Phase 8 — Lưu game

- Lưu `GameState` ra JSON tại `user://save.json` vào đầu mỗi ngày mới.
- Main menu có "Tiếp tục" nếu có file save.
- Xử lý an toàn khi file lỗi hoặc thiếu field (dùng giá trị mặc định, không crash).

**Xong khi:** thoát game, mở lại, "Tiếp tục" khôi phục đúng tiền, ngày, kho, nâng cấp, cờ cốt truyện.

### Phase 9 — Cảnh kết MVP

- Khi đủ điều kiện (câu được cá thu phát sáng lần đầu, HOẶC tới ngày 7), đặt cờ cốt truyện. Từ ngày hôm sau, vùng `FOG` ở rìa map mở ra: sương mù (lớp phủ trắng mờ) và ở giữa có một xoáy nước phát sáng.
- Trong vùng FOG có vài điểm câu chỉ ra cá biến dị.
- Lái thuyền vào xoáy nước → màn hình sáng trắng, hiện vài dòng thoại ngắn của Rin và dòng chữ "Còn tiếp...", rồi quay về main menu.

**Xong khi:** đạt điều kiện thì vùng FOG và xoáy nước xuất hiện, cảnh kết chạy đúng.

---

## 8. Ngoài phạm vi MVP (KHÔNG làm)

Lặn biển, thế giới song song, dị biến cơ thể, dụng cụ kết hợp hải sản, các cách bắt khác (lưới, bẫy, bắt ốc theo thủy triều), nhân viên, nâng cấp không gian quán, special guest, nhân vật phụ, hệ thống hội thoại, map nhiều vùng biển, thời tiết, âm thanh, art thật, cốt truyện ngoài cảnh kết Phase 9.

---

## 9. Tiến độ

| Phase                    | Trạng thái   | Ghi chú                                                                                                                                                                                                    |
| ------------------------ | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 — Khởi tạo             | ✅           | Godot 4.7.2; autoload GameState/DayClock/SceneRouter, main menu, sea scene trống                                                                                                                           |
| 1 — Lái thuyền           | ✅           | Map 1920x1280, 3 BoatData, spin drift, phím debug 1/2/3 đổi thuyền                                                                                                                                         |
| 2 — Thời gian & về bến   | ✅ (đã thay) | Trễ tính theo phút (pro-rata); màn quán tạm có nút "Ngày mới (tạm)" — thay ở Phase 6/7                                                                                                                     |
| 3 — Điểm câu             | ✅           | 7 loài + fish_catalog.tres; 4 spot/zone, 2–4 lượt, mỗi lượt +20 phút game; minigame tạm là thông báo                                                                                                       |
| 4 — Minigame câu         | ✅           | TIMING + TENSION; cần câu tạm = +15% vùng xanh/cấp (đổi sang UpgradeData ở Phase 7); test: scenes/test/fishing_minigame_test.tscn                                                                          |
| 5 — Khoang xếp hình      | ✅           | GridInventory thuần + HoldUI kéo-thả, khay "Cá mới" + ô "Bỏ"; overflow = pause; test: scenes/test/grid_inventory_test.tscn                                                                                 |
| 6 — Quán ăn              | ✅           | + Chuẩn bị menu kiểu Dave the Diver (MenuPlan, 3 món, phần lấy từ kho, thừa trả kho, bán hết thì đóng sớm); tip 20% nếu kiên nhẫn > 50%; đơn vị "k"; F1 debug thêm cá; test: scenes/test/cooking_test.tscn |
| 7 — Vòng ngày & nâng cấp | ✅           | Sao = tỉ lệ khách được phục vụ (−1 nếu menu đơn điệu), ảnh hưởng tần suất khách hôm sau; 3 UpgradeData (thuyền 300/800, cần 120/350, tủ lạnh 150/400); tủ lạnh mua tối nay có tác dụng ngay đêm nay        |
| 8 — Lưu game             | ✅           | SaveSystem (static) → user://save.json, ghi file tạm rồi đổi tên; autosave lúc 6:00 mỗi ngày; field thiếu/sai kiểu → mặc định, cá lạ bị bỏ qua; test: scenes/test/save_test.tscn                           |
| 9 — Cảnh kết             | ✅           | Điềm báo (cá thu phát sáng / ngày 7) → hôm sau mở FOG góc đông bắc (3 điểm cá biến dị + xoáy nước); xoáy → fade trắng → thoại Rin → "Còn tiếp..." → menu; F2 debug mở sương                                |
