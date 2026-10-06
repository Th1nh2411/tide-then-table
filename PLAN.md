# RIN THE FISHER — MVP Build Plan (cho coding agent)

> File này dành cho coding agent. Đọc toàn bộ trước khi viết code.
> Làm **từng Phase một**. Hết mỗi Phase thì DỪNG, tóm tắt những gì đã làm, liệt kê cách test, và chờ người dùng xác nhận rồi mới sang Phase tiếp theo.

---

## 1. Bối cảnh

RIN THE FISHER là game 2D: ban ngày nhân vật Rin lái thuyền ra biển câu hải sản, ban đêm bán món ăn tại quán hải sản Việt Nam, kiếm tiền để nâng cấp thuyền, dụng cụ và quán.

**Mục tiêu MVP:** kiểm chứng vòng lặp cốt lõi có vui không:

```
Lái thuyền ra biển → Tìm điểm câu → Câu (minigame) → Xếp vào khoang (lưới xếp hình)
→ Về bến trước giờ mở quán → Nấu & bán → Nhận tiền → Nâng cấp → Ngày mới
```

Áp lực chính của game là **thời gian**: ở ngoài biển lâu thì câu được nhiều hơn, nhưng về trễ thì quán mở trễ và bán được ít hơn.

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

### Danh sách loài ban đầu

| id                 | Tên              | Hình dạng | Vùng                     | Minigame | Độ khó | Giá |
| ------------------ | ---------------- | --------- | ------------------------ | -------- | ------ | --- |
| `oc_huong`         | Ốc hương         | 1x1       | NEARSHORE, REEF          | HAUL (lưới) | 0.1 | 15  |
| `tom`              | Tôm              | 1x2       | NEARSHORE                | TIMING   | 0.2    | 25  |
| `muc`              | Mực              | 1x2       | NEARSHORE, OPEN_SEA      | TENSION  | 0.3    | 30  |
| `ca_thu`           | Cá thu           | 1x3       | OPEN_SEA                 | TENSION  | 0.5    | 40  |
| `cua`              | Cua              | 2x2       | REEF                     | TIMING   | 0.4    | 50  |
| `ca_mu`            | Cá mú            | 2x3       | REEF, OPEN_SEA           | TENSION  | 0.8    | 90  |
| `ca_thu_phat_sang` | Cá thu phát sáng | 1x3       | OPEN_SEA (rất hiếm), FOG | TENSION  | 0.9    | 200 |

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

| Món                    | Nguyên liệu | Kiểu nấu | Giá |
| ---------------------- | ----------- | -------- | --- |
| Ốc hương nướng mỡ hành | 3 ốc hương  | GRILL    | 70  |
| Mực hấp gừng           | 1 mực       | STEAM    | 60  |
| Cá thu nướng           | 1 cá thu    | GRILL    | 80  |
| Tôm rang muối          | 2 tôm       | STIR     | 75  |
| Cua rang me            | 1 cua       | STIR     | 110 |
| Cá mú hấp xì dầu       | 1 cá mú     | STEAM    | 150 |
| Rau muống xào tỏi      | Mua chợ 10k/phần (món phụ, không chiếm slot, thừa bỏ đi) | STIR | 30 |
| Đậu phộng rang         | Luôn có, miễn phí, phục vụ ngay (không minigame) | — | 15 |

> **Menu & phạt (thêm sau Phase 6):** trước ca chọn tối đa 3 món hải sản + món phụ. ~15% khách gọi đậu phộng; menu hết món thì khách chỉ gọi đậu phộng (chuẩn bị kém = thu ít). Menu ít món bị chê đơn điệu: giá mọi món x0.8 (0–1 món), x0.9 (2 món), x1.0 (3+ món). Có nút "Đóng quán sớm".

### UpgradeData (Resource)

`id`, `display_name`, `description`, `levels: Array[int]` (giá từng cấp), `values: Array` (giá trị từng cấp).

| Nâng cấp     | Ảnh hưởng                                                  |
| ------------ | ---------------------------------------------------------- |
| Thuyền       | Thuyền thúng → Ghe chèo → Ghe máy (đổi `BoatData`)         |
| Cần câu      | Nới rộng vùng xanh trong minigame, giảm tốc độ giãy của cá |
| Tủ lạnh quán | Giảm tốc độ mất độ tươi của đồ trong kho                   |

### InventoryItem

`fish: FishData`, `quality: float` (0.7 hoặc 1.0, từ kết quả câu), `freshness: float` (100 → 0), `rotated: bool`, `grid_pos: Vector2i`.

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

| Phase                    | Trạng thái | Ghi chú |
| ------------------------ | ---------- | ------- |
| 0 — Khởi tạo             | ✅         | Godot 4.7.2; autoload GameState/DayClock/SceneRouter, main menu, sea scene trống |
| 1 — Lái thuyền           | ✅         | Map 1920x1280, 3 BoatData, spin drift, phím debug 1/2/3 đổi thuyền |
| 2 — Thời gian & về bến   | ✅         | Trễ tính theo phút (pro-rata); màn quán tạm có nút "Ngày mới (tạm)" — thay ở Phase 6/7 |
| 3 — Điểm câu             | ✅         | 7 loài + fish_catalog.tres; 4 spot/zone, 2–4 lượt, mỗi lượt +20 phút game; minigame tạm là thông báo |
| 4 — Minigame câu         | ✅         | TIMING + TENSION; cần câu tạm = +15% vùng xanh/cấp (đổi sang UpgradeData ở Phase 7); test: scenes/test/fishing_minigame_test.tscn |
| 5 — Khoang xếp hình      | ✅         | GridInventory thuần + HoldUI kéo-thả, khay "Cá mới" + ô "Bỏ"; overflow = pause; test: scenes/test/grid_inventory_test.tscn |
| 6 — Quán ăn              | ✅         | + Chuẩn bị menu kiểu Dave the Diver (MenuPlan, 3 món, phần lấy từ kho, thừa trả kho, bán hết thì đóng sớm); tip 20% nếu kiên nhẫn > 50%; đơn vị "k"; F1 debug thêm cá; test: scenes/test/cooking_test.tscn |
| 7 — Vòng ngày & nâng cấp | ✅         | Sao = tỉ lệ khách được phục vụ (−1 nếu menu đơn điệu), ảnh hưởng tần suất khách hôm sau; 3 UpgradeData (thuyền 300/800, cần 120/350, tủ lạnh 150/400); tủ lạnh mua tối nay có tác dụng ngay đêm nay |
| 8 — Lưu game             | ✅         | SaveSystem (static) → user://save.json, ghi file tạm rồi đổi tên; autosave lúc 6:00 mỗi ngày; field thiếu/sai kiểu → mặc định, cá lạ bị bỏ qua; test: scenes/test/save_test.tscn |
| 9 — Cảnh kết             | ⬜         |         |
