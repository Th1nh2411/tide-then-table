# Dựng model local tối nay (Hunyuan3D-2mini-turbo, máy Windows)

## Cập nhật 04/11/2026: brief 5 đã dựng đủ 25/25

Đã tiếp tục bằng hai token được người dùng cho phép và dựng đủ 25 model mới.
Output đã được kiểm hash, budget và normals; **74.761 tam giác**, metadata tổng
50 ID. Nhà C dùng raw Hunyuan và giảm mặt bằng CPU do export Space lỗi kết nối.
Danh sách pending hiện bằng **0**; chưa cần chạy batch Windows cho đợt này.
Chi tiết và review: [HORROR_CODEX_DELIVERY_5.md](HORROR_CODEX_DELIVERY_5.md).

## Lịch sử dừng quota và cách chạy lại local

25 model của đợt đầu bên dưới đã xong. **25 concept brief 4 còn chờ dựng**:
Space miễn phí từ chối ngay `dish_plate_fish` do quota anonymous (90 giây yêu cầu,
86 giây còn lại). Đã dừng gọi Space theo brief, chưa có raw/reduced mới.
ID và ngân sách chính thức: `tools/art/horror_brief5_models.json`;
trạng thái và kế hoạch tích hợp: [HORROR_CODEX_DELIVERY_5.md](HORROR_CODEX_DELIVERY_5.md).

Sau khi đồng bộ nhánh chứa các file này sang Windows và cài pipeline theo
`ART_PIPELINE.md`, chạy từ repo:

```powershell
python tools/art/stage_horror_brief5.py
# Chạy nguyên lệnh powershell mà tool vừa in (run_pending.ps1 dưới build/hunyuan_brief5/<stamp>/).
```

Tool chỉ copy concept, không gọi API hay cài weights. Script PowerShell sinh ra
chạy tuần tự các nhóm bằng `hunyuan_local.ps1`, retry một lần riêng cho ID lỗi,
liệt kê ID còn thiếu và trả exit 1 nếu chưa xong. Chạy lại tool stage trước mỗi
lần tiếp tục: chỉ bỏ qua output có status success và hash raw/reduced/input đúng.
Mỗi nhóm chỉ một ảnh được đưa vào thư mục output theo ID riêng, tránh khác biệt
single/batch của CLI hiện tại. Không chạy inference song song trên CPU.

Sau khi dựng: kiểm tra số tam giác theo budget, thêm normals nếu thiếu và merge
metadata mới vào `horror_models.gd/.json` (giữ các ID cũ), render đủ 3 góc/model.
Chưa gọi là tích hợp xong chỉ vì có GLB. Chưa thay furniture hay material của
WORLD/STYLE; nối đồ ăn/đồ uống và normal offering sau khi review model.

## Hướng dẫn đợt đầu — đã hoàn tất, giữ để tham khảo

Đợt đầu có **25 concept** (3 concept nhân vật anh Út / ông Tư / chú Hai **không cần**, vì đã dùng gói PSX có rig).
Mỗi model ~3,5 phút trên CPU → cả loạt **~1,5 giờ**. Chạy qua đêm được. Cài đặt máy: xem `docs/ART_PIPELINE.md` mục "Cài trên máy mới".

## Cách 1: tự chạy lệnh (PowerShell, ở thư mục repo)

```powershell
git pull                      # lấy nhánh try-horror-1st mới nhất
git checkout try-horror-1st

# 1) Gom concept cần dựng vào 3 thư mục theo độ chi tiết
$small = "fish_ca_thu","fish_ca_mu","fish_muc","fish_cua","fish_tom","fish_oc_huong","fish_glowing","fishing_bobber","hat_hook","water_jar","low_table_tea","altar_ong_tu"
$medium = "fish_basket","fishing_rod","bamboo_fence","banana_clump","power_pole","roadside_shrine","fishing_nets_drying","stone_steps","wooden_bed","wooden_wardrobe"
$big = "rin_house","neighbour_house_a","neighbour_house_b"
foreach ($g in @(@{n="small";l=$small},@{n="medium";l=$medium},@{n="big";l=$big})) {
  $d = "build\hunyuan_in\$($g.n)"; New-Item -ItemType Directory -Force $d | Out-Null
  foreach ($id in $g.l) { Copy-Item "assets\concepts\horror\$id.png" $d }
}

# 2) Dựng (mỗi ảnh -> assets\models\ready\<id>\<id>_raw.glb + <id>_reduced.glb)
powershell -File tools/art/hunyuan_local.ps1 -InputDir build\hunyuan_in\small  -OutDir assets\models\ready -Faces 2000
powershell -File tools/art/hunyuan_local.ps1 -InputDir build\hunyuan_in\medium -OutDir assets\models\ready -Faces 3000
powershell -File tools/art/hunyuan_local.ps1 -InputDir build\hunyuan_in\big    -OutDir assets\models\ready -Faces 5000

# 3) Kiểm tra đủ 25 model
foreach ($id in $small + $medium + $big) { if (-not (Test-Path "assets\models\ready\$id\${id}_reduced.glb")) { "THIẾU: $id" } }

# 4) Commit
git add assets/models/ready
git commit -m "Horror models: local Hunyuan batch (fish, fishing gear, lane props, room interior, houses)"
git push
```

`build\` đã được Godot bỏ qua (`build/.gdignore`), nên ảnh gom tạm ở đó không lẫn vào game.

## Cách 2: đưa prompt cho Claude Code / Codex trên máy Windows

Copy nguyên khối dưới đây:

```text
Repo tide-then-table, branch try-horror-1st (git pull first). Build 3D models locally with Hunyuan3D-2mini-turbo
for the concepts that have no model yet, following docs/ART_PIPELINE.md ("Tool gen 3D", local CPU tool
tools/art/hunyuan_local.ps1; install steps in "Cài trên máy mới" if the venv/weights are missing).

Concepts (assets/concepts/horror/<id>.png), output to assets/models/ready/<id>/ (<id>_raw.glb, <id>_reduced.glb,
hunyuan_provenance.json, LICENSE-HUNYUAN.txt):
- small, -Faces 2000: fish_ca_thu, fish_ca_mu, fish_muc, fish_cua, fish_tom, fish_oc_huong, fish_glowing,
  fishing_bobber, hat_hook, water_jar, low_table_tea, altar_ong_tu
- medium, -Faces 3000: fish_basket, fishing_rod, bamboo_fence, banana_clump, power_pole, roadside_shrine,
  fishing_nets_drying, stone_steps, wooden_bed, wooden_wardrobe
- big, -Faces 5000: rin_house, neighbour_house_a, neighbour_house_b
Do NOT build anh_ut, ghost_ong_tu, villager_chu_hai (characters come from a rigged pack).

Use batch mode (-InputDir) with one staging folder per face budget under build\hunyuan_in\ (build/ is ignored by
Godot). Run the batches one after another (parallel jobs are not faster on CPU). If one image fails, retry it once
alone with -Image/-Name; if it fails again, list it and continue. Do not touch scenes or scripts.
At the end: check every listed id has <id>_reduced.glb, report face counts and any failures, then commit
"Horror models: local Hunyuan batch (fish, fishing gear, lane props, room interior, houses)" and push.
```

## Sau khi push

Báo Claude Code trên máy Mac: "model local xong rồi". Claude sẽ pull, gắn model vào game
(cá trên tay + trong giỏ, giỏ, cần, phao, đồ trên đường làng, nội thất phòng, nhà Rin, nhà hàng xóm),
tô màu bằng ảnh concept (`ConceptModel3D`) và chạy test + bot.
