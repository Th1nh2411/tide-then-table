# Art 3D — flow và pilot hiện hành

Chốt ngày 2026-10-28: gen-image → Hunyuan image-to-shape → giảm mesh/làm sạch →
material phẳng → rig/animation cho nhân vật → kiểm Godot. Không dùng Blender
cho ba pilot mới; không thay inference bằng mesh code-native tự dựng. Tool gen: xem mục dưới.

## Tool gen 3D — chốt 2026-10-28

**Chính: Hunyuan3D-2mini-turbo chạy local trên CPU** (máy dev: Windows, AMD RX 5600,
không CUDA). Không quota, không upload ảnh, cùng dòng Hunyuan với các pilot đã làm.
Octree 128, 5 bước, FlashVDM: ~3,5 phút/asset; octree 256 trên CPU quá 20 phút chưa
xong, không dùng. Chỉ tạo hình khối: texture của
Hunyuan cần CUDA, nên vẫn tô material phẳng như flow trên.

```
powershell -File tools/art/hunyuan_local.ps1 -Image <png> -OutDir assets/models/pilots/<id> -Name <id> -Faces 2000
powershell -File tools/art/hunyuan_local.ps1 -InputDir <thư mục png> -OutDir <gốc>   # batch, mỗi ảnh -> <gốc>/<tên ảnh>/
```

Ra `<id>_raw.glb`, `<id>_reduced.glb` (có normal), `hunyuan_provenance.json`
(provider `tencent/Hunyuan3D-2mini`, tham số, SHA-256), `LICENSE-HUNYUAN.txt`.
PNG đã có nền trong suốt thì bỏ qua bước xóa nền.

FlashVDM bật mặc định (tắt bằng `-NoFlashVDM`): giải mã khối 4,5 phút → 3 giây, cả asset
~3,5 phút (còn lại là diffusion). Rin có/không FlashVDM ra gần như giống hệt; bàn ra sạch
(mặt, khung, 4 chân vuông). Cần thêm VAE turbo 407 MB (bước cài 3). Chạy nhiều job song song trên CPU không nhanh hơn (một job đã dùng hết nhân,
mỗi job 4–7 GB RAM); muốn nhanh hơn thì dùng batch qua đêm.

**Dự phòng: Space Hunyuan3D-2.1** (`tools/art/hunyuan.ps1`, `hunyuan_job.py`): chất lượng
cao hơn một chút nhưng giới hạn quota ZeroGPU và phải upload ảnh. Bàn từng bị chặn ở đây
(`blocked_by_quota`).

So sánh trên ghế đẩu + Rin cùng ảnh đầu vào: 2mini-turbo gần bằng 2.1 (Rin: tóc vuốt,
dáng, quần đúng; kính mờ hơn). TripoSR (MIT, ~30 s CPU, có màu) bị loại: chân ghế
thành ống tròn, tóc Rin thành cục, mất kính. triposr.org là site trả phí bên thứ ba.

### Cài trên máy mới (Windows, một lần)

Code và weights nằm ngoài repo; đổi đường dẫn bằng `$env:HY3D_HOME` / `$env:HY3DGEN_MODELS`.

1. `git clone --depth 1 https://github.com/Tencent-Hunyuan/Hunyuan3D-2 E:\workSpace\Hunyuan3D-2`
2. Trong thư mục đó: `uv venv --python 3.11 .venv`, rồi
   `uv pip install --python .venv\Scripts\python.exe torch torchvision --index-url https://download.pytorch.org/whl/cpu`
   và `uv pip install --python .venv\Scripts\python.exe "diffusers==0.32.2" "transformers==4.46.3" "huggingface_hub<0.28" einops opencv-python numpy omegaconf tqdm trimesh pymeshlab pygltflib accelerate rembg onnxruntime`.
   Phải ghim ba bản này: transformers mới đổi tên trọng số DINOv2 (load lỗi `q_proj`),
   huggingface_hub mới thì diffusers cũ không import được.
3. Tải weights bằng curl (thư viện HF trong Python từng treo ở 0 byte trên máy này), 3,8 GB:
   `curl -L -C - --retry 10 -o E:\workSpace\hy3d_models\tencent\Hunyuan3D-2mini\hunyuan3d-dit-v2-mini-turbo\model.fp16.safetensors https://huggingface.co/tencent/Hunyuan3D-2mini/resolve/main/hunyuan3d-dit-v2-mini-turbo/model.fp16.safetensors`
   và `config.yaml` cùng thư mục. Cho FlashVDM (mặc định): tải `config.yaml` + `model.fp16.safetensors`
   của `hunyuan3d-vae-v2-mini-turbo` (407 MB) vào thư mục cùng tên cạnh đó. Model xóa nền `u2net` (~170 MB) tự tải lần đầu.

License: Tencent Hunyuan 3D Community License (loại trừ EU/UK/Hàn Quốc, áp dụng cả output),
giống bản 2.1.

## Dọn trước khi triển khai

Đã archive bốn nhóm Rin study không chọn, preview, builder và render/vendor cũ:
`.art_backups/art_studies_20261028_143130/` (local, ignored by Git và Godot).
`manifest.json` ghi từng đường dẫn gốc, kích thước và SHA-256; snapshot các plan
trước dọn nằm trong `documents/`. Di chuyển lại theo manifest để khôi phục.
Không xóa dữ liệu khỏi máy. Đã kiểm hash sau di chuyển.

Giữ portrait/sprite approved, gameplay, PersonRig3D, mẫu quán PSX, Hunyuan trial,
`tools/mesh/add_glb_normals.py`. Concept Rin chuyển sang `assets/concepts/rin/`.
Lịch sử tài liệu cũ: `docs/archive/ART_STUDIES_20261028.md`.

## Ba pilot

| Pilot | Phạm vi | Tiêu chí |
|---|---|---|
| Rin | Hunyuan shape đã tạo, palette từ concept, rig/skin và Idle/Walk/Carry | Cao ~1.84 m; giữ API đi/bưng/giơ tay/cần câu; kiểm vai/gối và nhiều góc |
| Bàn + ghế đẩu | Gen từng vật riêng, Hunyuan, giảm mesh/material, ráp wrapper | Bàn 1.5×1.2 m cao .86 m; ghế .55×.55 m cao .52 m; giữ marker/collider/logic |
| Thuyền thúng | Gen/Hunyuan hull, material gọn, thay visual | Đường kính ~2.4 m; giữ BoatVisual, đèn, actor, controller, collider và cinematic |

Chỉ chỉnh renderer khi đã có mesh cụ thể để review; backup file active trước
khi thay. Lưu input, prompt, output gốc, tham số, license/checksum cùng artifact.
Không để license chặn demo theo chỉ đạo người dùng. Không phát sinh dịch vụ trả phí.

## Kiểm tra và mở rộng

Mỗi pilot cần ảnh trước/ngang/sau, cỡ gameplay và kiểm import; nhân vật cần kiểm
skin thực sự biến dạng theo animation. Kiểm regression quán/biển/cutscene theo
phạm vi tích hợp, luôn dùng `-- --no-autosave` để giữ save thật.
Sau ba pilot mới mở rộng Bảo/Vy/Cô Năm/khách và các nhóm prop khác theo ASSETS.md.
