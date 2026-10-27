
# GAME PROJECT REQUIREMENT DOCUMENT (PRD) - UPDATED 2026

## Dự án: Game Lai 2.5D (Chiều Bán Hải Sản - Đêm Đi Câu Biển Sâu)

---

## 1. TỔNG QUAN DỰ ÁN (OVERVIEW)

* **Thể loại:** Kinh dị hoài cổ (Retro Horror) / Mô phỏng quản lý / Phiêu lưu.
* **Engine phát triển:** Godot Engine 4 (GDScript).
* **Phong cách đồ họa:** 3D Low-poly thô mộc (Retro PSX Style). Không gian, nhà cửa, và toàn bộ nhân vật đều là mô hình 3D khối góc cạnh, sử dụng màu phẳng hoặc bọc texture pixel art cũ kỹ. Cấu hình bộ lọc hình ảnh là `Nearest` để tạo răng cưa kiểu PlayStation 1. Tắt tính năng mượt bề mặt (Dùng Flat Shading/Unlit).
* **Cơ chế hoạt ảnh (Animation):** KHÔNG dùng Billboard 2D. Nhân vật là mô hình 3D nhưng được làm chuyển động bằng cách ghép các bộ phận riêng lẻ vào một bộ khung xương cơ học. Khi di chuyển, các khối 3D này sẽ lắc lư tịnh tiến, tạo ra cảm giác giật cục, méo mó và rùng rợn đặc trưng của game *Phở Anh Hai*.
* **Cảm hứng thiết kế:** *Tiệm phở của Anh Hai*, *DREDGE* (Lái thuyền đêm mờ sương), *Dave the Diver* (Vòng lặp bắt cá - quản lý nhà hàng).

---

## 2. VÒNG LẶP GAMEPLAY CỐT LÕI (CORE GAMEPLAY LOOP)

Trò chơi vận hành liên tục dựa trên 3 trạng thái (State) chính được quản lý bởi một State Machine tổng (`GameManager.gd` Autoload):

1. **STATE_RESTAURANT (Chiều tối - Quản lý quán hải sản 3D):**
   * **Không gian:** 3D hoàn chỉnh (Quán ăn nền gạch bông cũ, bàn nhựa, quầy bếp).
   * **Góc nhìn:** Top-down gần.
   * **Gameplay:** Người chơi điều khiển nhân vật 3D đi lại bưng bê phục vụ các món ăn làm từ hải sản dị hợm cho những vị khách mô hình 3D thô đang lắc lư đi vào quán. Kiếm tiền (Gold) để nâng cấp.
2. **STATE_SAILING (Đêm muộn - Lái thuyền biển đêm 3D):**
   * **Không gian:** 3D hoàn chỉnh (Mặt biển đêm, đá ngầm, sương mù dày đặc).
   * **Góc nhìn:** Nghiêng từ sau đuôi thuyền (Chasing Camera kiểu *DREDGE*) kết hợp ngọn đèn pha (SpotLight3D) quét xuyên sương mù để tạo cảm giác u ám, cô độc.
   * **Gameplay:** Lái thuyền gỗ 3D (có quán tính vật lý, gia tốc, lực cản của nước) dò tìm các Vùng Cá Đột Biến (Fishing Spots).
3. **STATE_FISHING (Đêm muộn - Mini-game câu cá 2D):**
   * **Không gian:** 2D phẳng độc lập (Được render qua một lớp phủ `CanvasLayer` chứa `SubViewport`).
   * **Góc nhìn:** 2D Top-down thẳng đứng từ trên xuống (kiểu *Dave the Diver*) để nhìn rõ đàn cá pixel art bên dưới.
   * **Gameplay:** Khi thả câu, thế giới 3D sẽ đóng băng (`get_tree().paused = true`). Người chơi tương tác với mini-game câu cá 2D. Khi kết thúc, dữ liệu cá lưu vào hòm đồ, ẩn SubViewport và unpause thế giới 3D.

---

## 3. THÔNG SỐ KỸ THUẬT & KIẾN TRÚC NODE (GODOT 4)

### Cấu trúc cây Node mẫu tại Scene Chính (Main Scene):

* **Main (Node3D)** -> Gắn `Main.gd` (Điều phối chuyển cảnh)
  * **World3D (Node3D)** -> Chứa map 3D Quán ăn, Biển đêm.
    * **DirectionalLight3D & WorldEnvironment** (Cấu hình Volumetric Fog & Glow/Bloom).
    * **Thuyen (CharacterBody3D)** -> Gắn `boat_3d.gd` (Vật lý lái thuyền kiểu DREDGE).
      * **Camera3D** (Góc theo dõi nghiêng từ phía sau, có độ trễ nhẹ).
    * **Khach_Hang_3D (CharacterBody3D)** -> Khách hàng bằng mô hình 3D Low-poly (Gắn xương cơ học cử động giật cục, không dùng Billboard).
  * **FishingSystem (CanvasLayer)** -> Mặc định `visible = false`. `ProcessMode = ALWAYS`.
    * **SubViewportContainer**
      * **SubViewport**
        * **MiniGame2D (Node2D)** -> Trực quan hóa mini-game câu cá bằng UI và đàn cá 2D Pixel Art cũ.
  * **CanvasLayer_UI (CanvasLayer)** -> UI hệ thống (Hòm đồ hộc lưới 2D Grid, Tiền vàng).

---

## 4. ĐỊNH HƯỚNG SỬ DỤNG AI AGENT (TASK FOR AGENT)

*(Lưu ý nghiêm ngặt: Chỉ đọc và đánh giá hệ thống, KHÔNG tự ý sửa code hiện tại).*

1. **Phân tích kiến trúc:** Quét thư mục dự án để kiểm tra tính khả thi của việc chuyển đổi. Đánh giá cách cấu trúc file scene để quản lý 3 trạng thái (Quán ăn 3D -> Lái thuyền 3D -> Câu cá 2D trong SubViewport).
2. **Giải pháp xử lý Input Focus:** Đảm bảo khi mở màn hình câu cá 2D, tiêu điểm phím bấm (Input) được chuyển hoàn toàn vào `SubViewport` để điều khiển cần câu, ngắt hoàn toàn chuyển động của thuyền 3D mà không bị lỗi dính phím (ghost inputs).
3. **Bản kế hoạch triển khai:** Đưa ra danh sách các file cần tạo/chỉnh sửa và cấu trúc dữ liệu lưu trữ (Persistent Data) cho Vàng và Hòm đồ cá.

---

**END OF DOCUMENT**
