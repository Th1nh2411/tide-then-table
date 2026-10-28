# Archived 3D art studies — 2026-10-28

Superseded by the selected imagegen → Hunyuan → material/rig → Godot workflow.
The following records are historical, not the current asset catalog or backlog.
Recoverable sources/assets/renders and SHA-256 manifest are stored locally in
`.art_backups/art_studies_20261028_143130`. Restore files to their original paths using that manifest if needed.


## Historical ART_PLAN.md

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
- Hướng triển khai ban đầu: thử **Quaternius Universal Base Characters — Regular Male**
  làm nền stylized có rig, rồi chỉnh thành Rin. Sau khi kiểm file Standard thực tế,
  chỉ có Superhero Male/Female; candidate dùng Superhero Male đã thu gọn tỷ lệ,
  chưa chốt dùng trong runtime. MPFB2 là phương án dự phòng
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

### Rin — low-poly từ base humanoid, 2026-10-28 (candidate mới)

- Áp dụng ảnh low-poly người dùng đã chốt: màu phẳng có nhận ánh sáng, tóc chia
  mảng lớn, ưu tiên silhouette và tỷ lệ. Thân/rig từ Quaternius Superhero Male
  Standard CC0, đã thu gọn vai/tay/thân; không dùng mesh/rig hai study trước.
- Bổ sung áo ba lỗ có cổ/nách mở và trọng số da, quần lửng, dép, kính không có
  tấm tròng đục, khuyên bạc và dây chuyền lưỡi câu. Portrait approved giữ nguyên.
- Mesh glTF đầu vào có vertex tách ở UV/normal seam: weld trước khi làm mềm và
  giảm mesh để không hở cổ/cổ tay/cổ chân. Giữ tối đa 4 trọng số/vertex, chuẩn hóa
  trước xuất; gom thành 1 mesh, 11 surfaces, 6,934 tam giác, 65 xương, cao ~1.84 m.
- Idle/Walk dùng Universal Animation Library CC0, bake theo tên xương; Carry
  chỉnh tay bằng IK hai khớp. JointCheck dùng tư thế gập để kiểm biến dạng.
- Trang itch chính trả HTTP 403 khi tải tự động. Input lấy từ mirror public pin
  commit `5821923af517ac5fdc82505faa92a0d575fc1b1a`, có SHA-256 từng file và license
  trong `assets/models/characters/rin_lowpoly/`. Không dùng gói Source trả phí.
- Source Blender, render nhiều góc/contact sheet/ảnh Godot và backup nằm trong
  `build/characters/rin_lowpoly/`. Generator: `tools/blender/build_rin_lowpoly.py`;
  tải lại input có kiểm checksum: `tools/blender/fetch_rin_lowpoly_base.py`.
- Preview riêng `scenes/art_preview/rin_lowpoly_study.tscn`: F6; B so study cũ,
  1/2/3 đứng/đi/bưng, 4 cận, 5 đặt trong mẫu quán đã thích, 6 gập khớp, ←/→ xoay.
- Đã kiểm Godot Compatibility: đủ clip, skeleton/skin/material, trọng số chuẩn
  hóa và vertex thực sự di chuyển theo Walk; đã xem ảnh trước/nghiêng/sau/đi/bưng/
  gập và cỡ trong quán. Đây là candidate để đánh giá hướng mới, chưa duyệt thẩm mỹ.
  Carry còn cần chỉnh lòng bàn tay theo đĩa; cổ/nách áo và gấu quần cần chỉnh thêm
  ở tư thế gập sâu. Chưa thay nhân vật gameplay.

#### Chỉnh trang phục Rin — 2026-10-28

- Theo phản hồi người dùng: chỉnh vị trí áo/dây chuyền và nới quần. Áo bám mặt
  thân thật ở vai/ngực, cổ tròn cao và cân hơn; chuyển trọng số theo bề mặt tam giác
  thay cho lấy vertex gần nhất. Giữ da ngực nguyên ở cổ áo để không lộ mặt lưng áo.
- Dây chuyền thành vòng liên tục quanh cổ, mặt lưỡi câu ngắn hơn và nằm trên mặt áo;
  mặt và điểm nối dây dùng cùng bộ trọng số để hạn chế trượt khi thân chuyển động.
- Quần rộng dần từ eo xuống đùi/ống, hạ đũng nhẹ; gấu ống theo xương đùi để giữ
  miệng ống khi gập gối. Giữ hướng low-poly, màu sắc và đặc điểm Rin.
- Candidate cập nhật: 6,934 tam giác, 1 mesh/11 surfaces, 65 xương, bốn clip cũ.
  Bản trước sửa: `build/characters/rin_lowpoly/backups/clothing_before_fix/`; các
  lượt dựng tiếp theo có backup theo timestamp. Ảnh trước/sau: `clothing_comparison.png`.

### Rin — thử flow gen-image + mesh script, không Blender — 2026-10-28

- Theo yêu cầu người dùng, thử riêng pipeline không mở/chạy Blender: built-in
  imagegen tạo `assets/models/characters/rin_image_guided/concept_v1.png`, sheet
  trước/ngang/sau theo ảnh low-poly người dùng và portrait Rin. Prompt giữ ở
  `prompt.txt`, nguồn/checksum ở `provenance.json` cùng thư mục.
- Dựa vào mẫu ảnh để dựng hình bằng `tools/mesh/build_rin_image_guided.py`:
  Python/NumPy ghi trực tiếp GLB, tự tạo mesh, trọng số, rig và các clip.
  Đây là dựng mesh theo tham chiếu, không phải công cụ tự tái tạo 3D từ ảnh.
- `rin_image_guided.glb`: 1 mesh/9 material surfaces, 1,528 tam giác, 20 xương,
  cao ~1.84 m; Idle/Walk/Carry/JointCheck. Màu phẳng lit, mặt tối giản, tóc mảng
  lớn, quần rộng, bàn tay đơn giản. Áo/ngực dùng các vùng màu của cùng bề mặt.
  Mesh/rig này không dùng base bên ngoài hoặc geometry từ các bản Rin Blender.
- F6 `scenes/art_preview/rin_image_guided_study.tscn`; 1/2/3 đứng/đi/bưng, 4 cận,
  5 cỡ quán, 6 gập gối, ←/→ xoay; B chỉ để xem GLB bản Blender cũ khi so sánh.
- Ảnh nhiều góc/contact sheet/log: `build/characters/rin_image_guided/`. Godot
  Compatibility kiểm đủ skin, clip, trọng số chuẩn hóa và mesh thực sự biến dạng
  theo Walk; đã xem trước/ngang/sau/đi/bưng/gập/cỡ quán. Chưa duyệt thẩm mỹ.
- Mẫu gen-image chi tiết/đẹp hơn mesh dựng lần đầu. Tóc/mặt, bàn tay, đũng quần
  và biến dạng vai còn cần tinh chỉnh; chưa có rig mặt/ngón tay hoặc IK giữ bàn
  chân chạm đất. Giữ thành candidate riêng, chưa thay Rin gameplay.

### Rin — thử Hunyuan3D-2.1 từ ảnh, 2026-10-28

- Đã chạy thành công Space chính thức Tencent qua API: crop ảnh front từ concept
  imagegen → shape 78,972 tam giác → endpoint export giảm còn đúng 3,000 tam giác.
  Đây là inference image-to-3D thực tế, khác bản Python tự dựng theo ảnh trước đó.
- Chỉ thử shape; chưa chạy paint. Không tải weights hoặc cài nguyên repo lên Mac
  M1/16 GB vì pipeline gốc phụ thuộc CUDA và dung lượng trống hiện tại ~12 GB.
- Giữ GLB gốc và bản giảm; thêm bản `_3k_lit` với normals bằng NumPy để xem có
  ánh sáng. Preview F6 `scenes/art_preview/rin_hunyuan_study.tscn`, B đổi gốc/3k.
- Shape nhận ra tóc/kính/dáng/quần theo input nhưng còn nhập chi tiết nhỏ, cần
  làm sạch topology, vật liệu và rig. GLB không có skin/animation/texture; màu đất
  sét trong preview là vật liệu xem hình, không phải texture AI tạo.
- Tất cả nằm riêng trong `assets/models/characters/rin_hunyuan_shape/`, thông số
  và checksum trong provenance; log/ảnh ở `build/hunyuan21_trial/`. Chưa duyệt art.
  Giấy phép Tencent khác CC0, có giới hạn khu vực áp dụng cả Output; xem README
  và license trước khi cân nhắc phát hành quốc tế.


## Historical ASSETS.md

## Model 3D thử nghiệm — chưa active

| File | Quy cách | Trạng thái |
|---|---|---|
| `assets/models/characters/rin_portrait_study.glb` | Rin khoảng 1.8 m, skeleton và Idle/Walk/Carry, mesh tóc/tai/kính/áo/phụ kiện theo portrait | Candidate chờ duyệt; chỉ dùng ở scene art preview |

Nguồn dựng và ảnh so sánh xem `ART_PLAN.md`, phần Rin model theo portrait 2026-10-28.

### Biến thể Rin dùng texture — chưa active

`assets/models/characters/rin_painted/rin_painted.glb`: 1 mesh skinned, 13 material
surfaces, 11,718 tam giác, ba albedo 256×256 nhúng trong GLB, Idle/Walk/Carry.
Texture nguồn imagegen trong thư mục `rin_painted/textures/`; xem `README.md` và
`provenance.json` ở đó. Preview F6 `scenes/art_preview/rin_painted_study.tscn`;
B so sánh bản cũ/mới. Không thay portrait approved hoặc nhân vật gameplay.

### Rin low-poly từ base humanoid — chưa active

| File | Quy cách | Trạng thái |
|---|---|---|
| `assets/models/characters/rin_lowpoly/rin_lowpoly.glb` | ~1.84 m, 1 mesh skinned, 11 material surfaces, 6,934 tam giác, 65 xương; Idle/Walk/Carry/JointCheck; màu phẳng lit, không dùng texture raster | Candidate theo hướng low-poly mới; preview riêng, chờ duyệt |

Base Quaternius Superhero Male Standard và Universal Animation Library: CC0.
`README.md`, `provenance.json`, `LICENSE-QUATERNIUS.txt`, `LICENSE-ANIMATIONS.txt`
cùng thư mục ghi nguồn và cách dựng lại. Source/ảnh/backup: `build/characters/rin_lowpoly/`.
Preview F6 `scenes/art_preview/rin_lowpoly_study.tscn`; xem hướng art và hạn chế
ở `ART_PLAN.md`. Không thay portrait/sprite approved hoặc Rin gameplay.

### Rin gen-image + mesh script — thử không Blender, chưa active

| File | Quy cách | Trạng thái |
|---|---|---|
| `assets/models/characters/rin_image_guided/concept_v1.png` | 1672×941, sheet 3 góc do built-in imagegen tạo; ảnh tham chiếu, không phải model/sprite runtime | Giữ prompt và provenance cùng thư mục |
| `assets/models/characters/rin_image_guided/rin_image_guided.glb` | ~1.84 m, 1 mesh/9 surfaces, 1,528 tam giác, 20 xương, Idle/Walk/Carry/JointCheck; màu phẳng lit | Candidate tự dựng bằng Python/NumPy, không dùng Blender/base ngoài; chờ duyệt |

Source: `tools/mesh/build_rin_image_guided.py`. Preview F6:
`scenes/art_preview/rin_image_guided_study.tscn`; ảnh/log/backup trong
`build/characters/rin_image_guided/`. `README.md` ghi cách dựng lại và giới hạn;
mesh còn đơn giản hơn concept, chưa thay nhân vật gameplay.

### Rin Hunyuan3D-2.1 — shape AI thực tế, chưa active

| File | Quy cách | Trạng thái |
|---|---|---|
| `assets/models/characters/rin_hunyuan_shape/input_front.png` | 505×941, crop mặt trước của concept imagegen Rin | Input của lượt thử Space chính thức Tencent |
| `assets/models/characters/rin_hunyuan_shape/rin_hunyuan_shape.glb` | 78,972 tam giác, 1 mesh, không skin/animation/texture | GLB gốc từ image-to-shape, giữ nguyên bytes |
| `assets/models/characters/rin_hunyuan_shape/rin_hunyuan_3k.glb` | 3,000 tam giác; static, chưa texture/rig | Space giảm mesh bằng endpoint export |
| `assets/models/characters/rin_hunyuan_shape/rin_hunyuan_3k_lit.glb` | 3,000 tam giác, thêm vertex normals bằng NumPy; giữ vị trí và chỉ số tam giác | Bản mặc định trong preview, chưa duyệt chất lượng |

Preview F6 `scenes/art_preview/rin_hunyuan_study.tscn`, ←/→ xoay, 4 cận, B đổi
gốc/3k. Ánh sáng/vật liệu đất sét chỉ để xem shape. Source, tham số, checksum,
giới hạn và license Tencent (không CC0) ở README/provenance/license cùng thư mục.
Không thay Rin gameplay hoặc các candidate trước.


## Historical PLAN.md

### Kế hoạch art nhân vật đã chốt — 2026-10-28

Hướng chính thức: **low-poly stylized**, tỷ lệ người tự nhiên, tóc chia mảng lớn,
quần áo gọn, mặt tối giản, bề mặt đa giác/màu phẳng theo ảnh người dùng gửi.
Giữ màu và ánh sáng ấm của quán. Chi tiết và tiêu chí duyệt ở
`ART_PLAN.md` → “Hướng nhân vật 3D đã chốt”.

- [x] Chốt hướng thẩm mỹ; hai Rin study hiện tại chỉ là nghiên cứu, chưa đạt chuẩn dùng chính thức.
- [x] Kiểm bản Standard thực tế: chỉ có base Superhero nam/nữ, chưa có Regular Male. Dùng Superhero Male CC0 làm candidate, thu gọn cơ thể; nguồn mirror pin commit và checksum trong `assets/models/characters/rin_lowpoly/provenance.json`.
- [x] Dựng candidate Rin mới từ base: thân liền có trọng số da, dáng thanh, tóc mảng lớn, kính chữ nhật, áo ba lỗ ngà, quần lửng, dép, khuyên bạc và dây chuyền lưỡi câu. Không kế thừa mesh/rig của hai study cũ.
- [x] Thử Idle/Walk/Carry/JointCheck trong Blender, render trước/nghiêng/sau/cỡ quán và nhập Godot. GLB: 1 mesh, 11 surfaces, 6,934 tam giác, 65 xương; kiểm trọng số chuẩn hóa và skin thực sự biến dạng theo Walk.
- [x] Chỉnh trang phục theo phản hồi: áo ôm đúng vị trí vai/ngực, dây chuyền liên tục và mặt nằm trên áo, quần rộng đùi/ống, gấu theo xương đùi; giữ backup trước sửa. Xem `ART_PLAN.md` → chỉnh trang phục Rin.
- [ ] Hoàn thiện/duyệt ngoại hình và tư thế: tóc/mặt còn là bản cách điệu đầu tiên; Carry cần chỉnh hướng lòng bàn tay theo đĩa, cổ/nách áo và gấu quần còn cần cân chỉnh khi gập sâu. JointCheck chỉ là clip chẩn đoán, chưa dùng gameplay.
- [ ] Duyệt candidate trong `scenes/art_preview/rin_lowpoly_study.tscn` trước khi thay Rin active có backup. Nếu base không đáp ứng chất lượng sau chỉnh sửa, đánh giá MPFB2 dự phòng.
- [ ] Sau khi Rin đạt chuẩn, dùng cùng quy ước tỷ lệ, shading và rig để triển khai Bảo, Vy, Cô Năm và khách.

### Trạng thái vòng chơi

- **Hunyuan3D-2.1, 2026-10-28:** đã thử inference thật trên Space chính thức Tencent
  bằng ảnh Rin; nhận GLB 78,972 tam giác, giảm qua API còn 3,000, thêm normals để
  xem trong Godot. F6 `scenes/art_preview/rin_hunyuan_study.tscn`. Shape còn cần
  cleanup/vật liệu/rig; chưa thay gameplay. Giới hạn local và license ghi ở
  `assets/models/characters/rin_hunyuan_shape/README.md`.

- **Thử art không Blender, 2026-10-28:** hoàn thành candidate riêng
  `rin_image_guided`: imagegen tạo mẫu 3 góc, Python/NumPy tự dựng mesh/rig và ghi
  GLB trực tiếp, Godot xem/kiểm skin cùng bốn clip. 1,528 tam giác, 20 xương;
  chưa duyệt ngoại hình/animation, còn chỉnh tóc/mặt/tay/đũng quần/vai. F6
  `scenes/art_preview/rin_image_guided_study.tscn`. Xem `ART_PLAN.md` và README
  trong thư mục asset để phân biệt concept 2D với model 3D thực tế.

Theo yêu cầu hiện tại, ưu tiên hoàn thiện **cả vòng câu cá → quán → nâng cấp**
trên nhánh `try-3d`. Bản 2D vẫn là mốc tính năng; bản 3D chưa đạt toàn bộ tương đương.
Hướng dẫn chạy, kiểm tra và danh sách còn thiếu: `docs/3D_DEMO.md`.

- F5 vào menu có nhãn bản 3D; New Game/Continue → biển 3D → thẻ nghỉ → quán 3D → ngày kế.
- Biển: cần/đèn có hiệu lực, dầu không hao ở bến, đồng hồ theo bình dầu nâng cấp;
  đàn cá hết lượt; lưới tăng lượng theo thời gian; Dex/phần thưởng nhận cả cá overflow;
  chỉ dẫn đàn cá/bến/lưới/POI/ghim; cứu hộ bất tỉnh; sửa input và sự kiện cá heo.
- Minigame: Tab mở kho giữa lượt câu và tạm ngừng trận câu; giữ choáng giữa lượt,
  bất tỉnh cứu hộ sau khi đóng kết quả; chờ nhả phím rồi mới trả quyền cho thuyền.
- Quán: Bảo tự nấu, Rin nhận đĩa ở bàn kê, nướng/rót bia thủ công, khách ăn xong
  trả tiền và để bàn bẩn; nhân viên nhận/giao/dọn; menu dùng được pantry-only;
  giữ giá món hot/độ đa dạng; đóng ca chống giao dịch trùng; lựa chọn thuê Vy có hiệu lực.
- Giữ màu/ánh sáng ấm mẫu đã được người dùng thích; HUD, panel navy và prompt E đọc rõ.
- Kiểm thử: 18 kiểm tra liên cảnh/save của `game3d_loop_test`; 8 kiểm tra pause/kho/
  faint của `fishing3d_inventory_test`; 13 regression biển; regression quán và smoke
  tích hợp vào `tools/run_tests.sh`. Bot 3D đã tới ending ngày 5 (boat-first), ngày 6
  (kitchen-first/balanced), kiểm roundtrip save mỗi ca; không dùng save thật.
- Đợt 2 (5 phần, 2026-10-28): nhóm khách 1–2 người/1–3 món, A* nhân viên + xe máy khách,
  túi chợ → tủ lạnh, preview sửa quán, biển 3D theo bố cục 2D + `SeaShoals3D`, dàn cảnh cutscene 3D.
- Chưa xong: đá ngầm ẩn + cổng sương ở biển 3D, preview bếp/thùng đá, `tint` cutscene, model khách thứ hai,
  playtest tay, pacing, art 3D.

- **Rin portrait → 3D, 2026-10-28:** thêm candidate `assets/models/characters/rin_portrait_study.glb`
  bằng Blender, tóc/tai/kính/áo/phụ kiện chi tiết; giữ portrait approved làm tham khảo.
  Preview riêng `scenes/art_preview/rin_portrait_study.tscn` (F6, 1/2/3 animation, 4 cận,
  mũi tên xoay). Đã xem render nhiều góc và nạp model trong Godot; kiểm skeleton,
  ba clip và chuyển động xương chân Walk thành công. Cần chủ dự án duyệt độ giống;
  chưa thay Rin gameplay. Generator sao lưu bản trước mỗi lần xuất.

- **Rin mesh + texture, 2026-10-28:** đã thử pipeline mesh gọn + albedo imagegen
  theo portrait (mặt/tóc/vải). Candidate riêng `assets/models/characters/rin_painted/`;
  1 mesh/13 surfaces/11,718 tam giác so với bản trước 112 mesh/19,296 tam giác.
  F6 `scenes/art_preview/rin_painted_study.tscn`, B so bản cũ/mới, 5 xem cỡ quán.
  Đã kiểm ba texture nhúng, skeleton/Walk, ba clip và chuyển biến thể trong Godot;
  xem render cận/nhiều góc/cỡ nhỏ. Chờ duyệt art; giữ nguyên bản cũ và gameplay.


## Historical docs/3D_DEMO.md

## Xem thử Rin theo portrait

Các scene dưới đây chỉ xem art, chưa thay Rin trong vòng chơi:

- **Hunyuan3D-2.1 tạo mesh từ ảnh thật:** `scenes/art_preview/rin_hunyuan_study.tscn`.
  F6; ←/→ xoay, **4** cận, **B** đổi shape gốc 78,972 tam giác và bản giảm 3,000.
  Chưa texture/rig; preview dùng màu đất sét. Lượt thử chạy qua Space chính thức
  Tencent, không cài weights trên máy. Source/tham số/license và giới hạn ở
  `assets/models/characters/rin_hunyuan_shape/README.md`.
- **Thử không Blender:** `scenes/art_preview/rin_image_guided_study.tscn` —
  imagegen tạo mẫu tham chiếu, Python/NumPy tự dựng GLB 1,528 tam giác/20 xương.
  F6; **1/2/3** đứng/đi/bưng, **4** cận, **5** cỡ quán, **6** gập gối, **← →** xoay;
  **B** so GLB bản Blender cũ. Ảnh gen bên trái là mẫu 2D; nhân vật xoay bên phải
  là mesh thật. Mesh còn thô hơn mẫu gen; xem giới hạn ở README của asset.
  Ảnh nhiều góc: `build/characters/rin_image_guided/contact_sheet.png`.
- **Bản low-poly mới:** `scenes/art_preview/rin_lowpoly_study.tscn` — từ base
  humanoid Quaternius CC0, cơ thể liền và rig mới, màu phẳng, tóc mảng lớn.
  F6; **B** so study cũ, **1/2/3** đứng/đi/bưng, **← →** xoay, **4** cận/toàn thân,
  **5** đặt vào mẫu quán đã thích, **6** gập khớp. Candidate ~6.9k tam giác/65 xương;
  Carry và viền trang phục khi gập sâu còn cần chỉnh, chưa duyệt dùng chính thức.
  Ảnh: `build/characters/rin_lowpoly/contact_sheet.png`, `godot_close.png`,
  `godot_game_scale.png`. Source/cách dựng lại: `assets/models/characters/rin_lowpoly/README.md`.
- `scenes/art_preview/rin_portrait_study.tscn`: bản dựng chi tiết bằng mesh.
- `scenes/art_preview/rin_painted_study.tscn`: bản mesh gọn + texture mặt/tóc/áo.
  Bấm F6, **B** đổi bản cũ/mới, **← →** xoay, **1/2/3** đứng/đi/bưng,
  **4** cận/toàn thân, **5** xem cỡ trong quán.

Ảnh so sánh: `build/characters/rin_painted/comparison.png`.

