# RIN THE FISHER — MVP Build Plan (cho coding agent)

> File này dành cho coding agent. Đọc toàn bộ trước khi viết code.
> Làm **từng Phase một**. Hết mỗi Phase thì DỪNG, tóm tắt những gì đã làm, liệt kê cách test, và chờ người dùng xác nhận rồi mới sang Phase tiếp theo.

---

## 1. Bối cảnh

RIN THE FISHER là game 2D: **ban đêm** (0:00–6:00) Rin thắp đèn câu, lái thuyền ra biển câu hải sản; **sáng** (6:00–15:00) về nhà ngủ; **chiều tối** (15:00–24:00) bán món ăn tại quán hải sản Việt Nam, kiếm tiền để nâng cấp thuyền, dụng cụ và quán.

**Bối cảnh địa lý:** vùng biển hư cấu quanh Xóm Đèn và dải đảo Ngủ Quên (tên tự đặt, không dựa trên địa danh thật nào). Bờ phía nam là làng chài Xóm Đèn và bến; càng ra bắc càng sâu, có các đảo Gò Vỏ Ốc, Đá Canh Đêm; góc đông bắc là vùng sương mù. Chất liệu văn hóa: đèn lồng phố cổ, thuyền thúng, câu mực đêm, tục thờ cá Ông (cá voi) của ngư dân.

**Nhân vật chính (bản ghép với STORY.md):** Rin (nam) tốt nghiệp IT, cùng người bạn thân **Bảo** khởi nghiệp làm app ở thành phố; startup sập, Rin thất nghiệp nằm dài trong phòng trọ, gửi CV không ai gọi. Nhìn gói mì cuối cùng, Rin nhớ hồi ký túc xá Bảo nấu mì ngon nhất tầng → gọi điện rủ Bảo về Xóm Đèn (quê ông nội, còn chiếc ghe của ông) mở quán hải sản vỉa hè: **Bảo đứng bếp, Rin ra khơi câu và làm phục vụ** (cutscene "intro_call" ở phòng trọ khi New Game). Bảo chốt: "tao là bếp trưởng, món nướng mày tự lo". App điện thoại **"Rin's Catch"** (phím J) là phần còn sót lại của startup, Rin sửa lại để quản lý kho, menu, sách cá (Dex), thuyền và sổ sách; app ghi log lỗi khi gặp cá biến dị / tọa độ lạ ("có bug thì phải debug"). Ở quán, Bảo có mặt từ ngày 1 (bỏ cutscene "Bảo tới" cũ): tự nấu món hấp/xào/rau muống theo phiếu; Rin bưng, dọn bàn, nướng món nướng ở lò than (minigame) và rót tháp bia — phục vụ là nơi có nhiều minigame.

**Bí ẩn (bản ghép):** vùng sương đông bắc là nơi một **cổng không gian** dẫn tới một vùng biển song song — "lớp biển bên dưới" mà ông nội Rin từng kể. Cá biến dị (cá thu phát sáng...) là sinh vật lọt qua cổng. **Cá Ông** trong tín ngưỡng ngư dân thật ra là một tộc sinh vật thông minh canh giữ thế giới bên kia (ban đầu tưởng là thù địch vì chúng đẩy thuyền ra khỏi sương). Cổng mở chập chờn từ xưa (Cô Năm thấy "trời sáng xanh cả góc" hồi còn con gái); **vài năm gần đây** cổng mở rộng vì một nhà khoa học của **tập đoàn Thâm Lam** (tên tự đặt) vô tình kích hoạt nó, và tập đoàn đang lén khai thác sinh vật bên kia làm nguyên liệu công nghệ. MVP dừng ở lúc Rin bị xoáy nước kéo qua cổng. Hướng màn sau: khám phá biển song song, hiểu ra tộc cá Ông chỉ bảo vệ quê hương, cùng họ đánh sập các cơ sở của Thâm Lam, rồi cổng đóng lại.

**Mốc thời gian & luật của sương (đã chốt, giữ cho mọi thoại khớp nhau):**
- *Xưa:* cổng mở chập chờn, thỉnh thoảng có mùa sáng xanh; tục thờ cá Ông. Ông Tám đi biển ba chục năm, chỉ thấy ánh xanh một lần — đêm ông Tư đi.
- *Vài năm trước:* nhà khoa học Thâm Lam vô tình mở rộng cổng; tàu lạ sơn xanh đen, không cờ, bắt đầu ra vùng sương thả máy móc. Từ đây mới có cá biến dị.
- *Hai năm trước:* **ông Tư** — ông nội Rin, bạn đi biển của ông Tám — thấy cá Ông dẫn đường, chèo **thúng** đi sâu vào sương, không về; chiếc ghe để lại ở bến, nhà bỏ trống (Rin về ở). Chai thư là của ông, viết cho "thằng cháu" (Rin). Ông từ, Cô Năm, ông Tám đều biết chuyện; Rin biết ông mất tích ngoài biển nhưng không biết chi tiết.
- *Năm ngoái:* người gác đèn Đá Canh Đêm chèo ra xem, không về (nhật ký dừng giữa câu).
- **Luật sương:** ghe chạy ở mép sương thì về được nhưng **quên sạch** đã thấy gì; ai **đi sâu / lặn theo cá Ông** xuống lớp biển dưới thì không về (ông Tư, người gác đèn — hướng màn sau: họ còn sống ở bên kia).
- Ba mẹ Rin không xuất hiện trong MVP (Rin lớn lên ở thành phố, về quê ông vài lần hồi nhỏ).

- **Tính cách Rin — dễ dãi, thuận theo ý trời, đang đi tìm mục đích sống.** Ban đầu Rin là người khá dễ: ai rủ
  gì cũng gật, không biết mình thích gì, câu cửa miệng "sao cũng được" / "tới đâu hay tới đó" / "trời kêu ai nấy
  dạ". Học IT vì bạn bè học, làm startup vì Bảo rủ, về Xóm Đèn vì còn gói mì cuối cùng và chiếc ghe của ông. Hiền,
  không giận ai lâu, nhưng cũng không giữ cái gì cho riêng mình — chính cái "chạy được là được" này làm Rin cắm SDK
  của Thâm Lam mà không đọc (khớp phần twist). Ngoại lệ duy nhất: **code** — thứ Rin từng hăng thật ("có bug thì
  phải debug", câu Bảo hay nhắc). Startup sập là mất luôn thứ đó, nên Rin trôi theo; ra biển, câu "debug" quay lại
  dưới dạng tò mò về sương — mầm của mục đích sống. Diễn tiến:
  1. *Trôi theo (ngày 1–3):* nhận mọi việc, khách chê thì bớt tiền, Bảo quyết thì nghe. Biển là thứ đầu tiên Rin
     thấy thích mà không cần ai rủ (câu cá to đầu tiên: im lặng nhìn mặt nước rất lâu).
  2. *Bị hỏi (ngày 4–5):* Vy là người đầu tiên hỏi thẳng "anh sống kiểu gì mà câu nào cũng là sao cũng được?",
     "ngoài câu cá anh thích cái gì?" — Rin chưa trả lời được. Nhịp Sóng: biển "chọn" Rin, Rin vẫn chưa chọn gì.
  3. *Chọn lần đầu (Arc Bảo):* lần đầu Rin tự quyết một mình (đi tới trạm Thâm Lam) — quyết sai cách, liều.
  4. *Có mục đích (hồi cuối):* hiểu ra thứ mình muốn giữ là quán, mấy người ở quán và vùng biển của cá Ông; từ
     "sao cũng được" thành "lần này tao chọn". Vẫn hiền, vẫn đùa, nhưng nói "không" được.
  - Viết thoại Rin: câu ngắn, hay nhường, hay đùa cho qua; chưa tới bước 4 thì đừng cho Rin nói về ước mơ / lý
    tưởng. Đã gieo: `intro_call` ("Trời kêu ai nấy dạ"), `vy_arrives`, `vy_stands_up`, `vy_stay`, `vy_omen`.
- Nhân vật phụ: chú mèo béo ở bến (đã có, `PetCat`; thật ra là rồng từ chiều không gian kia — chưa lộ), nhân viên quán / nữ chính Vy (đã có, xem dưới); chưa làm: một người bạn đến từ thế giới bên kia.
- **Arc Vy (nữ chính, nhân viên quán) — tiểu thư đi làm thêm.** *(Bản kinh dị §10 không dùng arc này: Vy chỉ là bạn cũ của Bảo, nhân viên cố định từ mùng 9.)* Vy, sinh viên năm cuối ở thành phố, nhà khá giả
  (bố mẹ làm ăn trên thành phố), là **cháu nội ông Tám** (ông chài già ở chòi Gò Vỏ Ốc, bạn đi biển của ông Tư —
  ông nội Rin). Quẹt thẻ quá tay nên bị bố mẹ **gửi về quê ở với ông cả hè, cắt tiền tiêu vặt** "tự kiếm đi rồi
  biết"; vẫn còn **chuyến đi chơi với nhóm bạn** (không nêu địa danh) phải góp tiền → xin làm ở quán gần nhà ông
  nhất, định làm đủ tiền rồi nghỉ.
  Ban đầu không ưa ai, ghét dơ, ghét mùi cá; về sau khác hẳn. Đổi từ từ qua hành động, không đổi tính một phát.
  1. *Tới (ngày 4, `vy_arrives`):* đứng xa xe đẩy, che mũi; hỏi lương trước khi chào; "Em chỉ bưng đồ thôi nha,
     không đụng cá sống." Gọi Rin là "anh chủ quán", Bảo là "anh đầu bếp", không nhớ tên. Bảo: "Tiểu thư hả trời."
  2. *Gai góc (ngày 4–5):* idle lines chê ("Bàn này ai ăn mà như bãi chiến trường vậy?", "Mùi cá dính tóc em
     rồi!"), đeo găng tay hồng dọn bàn, đếm từng ngày lương, lướt điện thoại xem ảnh bạn đi chơi. Không ghét Rin
     mà coi Rin là "ông chủ nghèo dễ dụ". Với mèo: sợ lông dính áo.
  3. *Vết nứt:* một tối khách say chê quán dơ / bắt nạt Rin → Vy là người cãi lại đầu tiên ("Quán người ta sạch
     hơn nhà anh đó!") rồi tự ngạc nhiên vì mình bênh. Lần đầu tự tay nhặt con cá rơi khỏi thùng; lần đầu ăn mì
     Bảo nấu cùng hai người sau ca (thấy họ cười với nhau, Vy mới biết quán này là thứ họ dựng lại từ đổ nát).
  4. *Mở lòng:* nghe Rin kể về cá Ông / sương thì về hỏi ông Tám, mang chuyện cũ tới quán: ông Tư từng rủ ông Tám
     vào sương, ông không dám; luật "mép sương về được mà quên, đi sâu thì không về" (`vy_fog`). Tóc buộc gọn, bỏ găng tay, gọi đúng tên mọi người; idle lines đổi giọng ("Bàn 3 xong rồi anh
     Rin!", "Anh Bảo, em nêm thử nha?"). Đủ tiền đi chơi rồi mà vẫn ở lại — hủy chuyến, nói cho qua: "Đi với tụi nó
     chán lắm. Ở đây còn có mì anh Bảo."
  5. *Người giữ quán:* trong Arc Bảo, chính Vy chặn Rin ở bến và chạy đi báo Bảo (bước 2 ở dưới) — cô tiểu thư
     từng chỉ muốn lấy lương giờ là người không muốn quán này tan. Tình cảm với Rin chỉ gợi (đỏ mặt, cãi nhỏ),
     không thành chuyện chính trong MVP.
  - **Đã cài:** `vy_arrives` viết lại (che mũi, hỏi lương, "không đụng cá sống"); cutscene sau ca mới
    `vy_stands_up` (cần flag `worked_vy` — `ShiftCloser` đặt `worked_<id>` cho mỗi nhân viên làm hết ca — khách
    say chê quán, Vy cãi lại, ba người ăn mì; đặt `vy_warmed`). Thoại: giai đoạn đầu `vy_app`, `vy_mark`; hai
    giai đoạn đều hợp `vy_cat`, `vy_omen`; sau `vy_warmed`: `vy_fog` (đi hỏi ông nội), `vy_stay` mới (đủ tiền mà
    ở lại, hỏi Rin thích gì). Câu nói vặt: `StaffData.later_flag` + `later_idle_lines` (Talker đổi bộ câu khi
    flag bật). Thoại giai đoạn đầu có `blocked_by_flag = "vy_warmed"` (`Dialogue.blocked_by_flag`) nên không quay
    lại giọng chảnh sau khi đã mở lòng. Ông Tám có một câu về Vy (flag `tam_vy`, sau `worked_vy`).
    Chân dung mood `che`, `kieu` chưa có file → dùng ảnh thường.
  - **Bản MVP (nhánh `release/mvp`) chỉ có bước 1–3:** Vy tới ngày 4, cảnh khách say sau ca ngày 4; lượt chơi
    thường kết thúc ở biển đêm 5 nên `vy_fog`, `vy_stay`, `vy_cat`, câu nói vặt "sau" chỉ hiện nếu người chơi chưa
    vào sương. Chấp nhận: MVP không cần cho thấy hết arc.
  - **Bản tiếp (nhánh `develop`):** game dài hơn sau cổng → kéo arc ra: Vy tới sớm hơn (ngày 2, ngày chưa có
    cảnh lúc tới quán), gai góc vài ngày, cảnh khách say muộn hơn, bước 4–5 có ngày riêng; viết thêm cảnh nhặt
    cá rơi, đổi ngoại hình (bản "sau" trong ART_PLAN.md).
- **Twist dự kiến (SAU MVP, chưa code; MVP chỉ gieo manh mối):** app của startup Rin & Bảo thật ra được làm ra để phục vụ Thâm Lam (khách hàng/nhà đầu tư giấu mặt: dữ liệu ngư dân, tọa độ, sinh vật lạ chảy về tập đoàn). Bí mật lộ qua một **sự kiện thông báo của app** (push notification / log `[ERR]` không phải do Rin viết), đặt **gần cuối** (đầu hồi cuối, trước khi đánh Thâm Lam: backdoor trong app thành vũ khí); trước đó chỉ gieo manh mối nhỏ để twist không bị hụt.
  - **Ai có lỗi gì (đã chốt):**
    - **Bảo lỗi nặng hơn**: hồi startup sắp sập, Bảo một mình ký với nhà đầu tư "TL Holdings" (công ty con của Thâm Lam), biết app sẽ gửi dữ liệu về cho họ nhưng tin lời "chỉ để nghiên cứu thị trường" và nhận thêm một khoản riêng; thấy dấu hiệu lạ vẫn lờ đi. Startup sập, Bảo giấu Rin. Về Xóm Đèn rồi TL Holdings vẫn liên lạc, nhờ Bảo giữ app chạy (Bảo im lặng). Về quê đứng bếp có phần là chuộc lỗi.
    - **Rin cũng có lỗi một phần**: dân IT tự tin, gấp, cắm SDK của nhà đầu tư vào app mà không đọc kỹ. Bảo từng hỏi "Mày đọc điều khoản SDK chưa?" — "Đọc làm gì, chạy được là được." (gieo trước, nhắc lại lúc cãi nhau) → cãi nhau hai chiều, Bảo không phải người gánh tội một mình.
    - **NEO là nạn nhân**: lõi AI lấy từ bộ SDK đó, bên trong có module ẩn tự gửi tọa độ / Dex / ảnh cá biến dị về server Thâm Lam; NEO không biết module đó là của mình.
  - **Gương mặt phản diện: "chị Diệp"** (tên tự đặt), người liên lạc của TL Holdings, chỉ nghe qua điện thoại với Bảo: lịch sự, ấm áp, gọi Bảo là "em", nhớ cả tên mèo của quán — đáng sợ chính vì tử tế. Là người dụ Bảo ở màn cứu.
  - **Cảnh lộ:** push "TL-Sync: đã tải lên 37 tọa độ, 12 loài, 3 ảnh cá biến dị" — **số liệu lấy từ save thật của người chơi** (Dex, `best_sizes`, số cá biến dị đã câu, tọa độ cá Ông / sương nếu đã tới) → mỗi con cá chính người chơi ghi vào Dex đã chảy về Thâm Lam. Rin lần log → NEO: "[ERR] Module này... nằm trong tôi, anh Rin." → Rin hỏi Bảo, Bảo thú nhận. NEO tự chọn phe: không xóa module mà đảo chiều nó, cho Rin đọc ngược dữ liệu Thâm Lam (tọa độ cơ sở) → hồi cuối dùng chính backdoor đánh sập hệ thống của chúng.
  - **Arc Bảo: cãi → cứu → làm lành.**
    1. *Cãi nhau:* Rin: "Mày bán cả tao lẫn cái app." Bảo: "Không có tiền đó thì mình sập từ năm ngoái! Mà cái SDK đó ai cắm vô mà không đọc?" Rin bỏ đi, quán đóng cửa 1 ngày (không có ca bán: im lặng, ghế xếp chồng).
    2. *Vy lên tiếng:* trong ngày đóng cửa, Vy chặn Rin ở bến ("Anh định đi một mình thật à?"); Rin vẫn đi → Vy chạy về báo Bảo là Rin đã ra khơi.
    3. *Rin đi một mình:* theo tọa độ NEO đọc ngược ra, Rin lái ghe tới trạm Thâm Lam ngoài khơi (giàn/trạm phao) → bị phát hiện, ghe hỏng / bị giữ lại.
    4. *Bảo cứu:* chị Diệp gọi Bảo, dụ "em giúp chị thì Rin không sao"; Bảo từ chối lần đầu tiên. Bảo không biết lái ghe nên nhờ ông Tám chở; dùng mã truy cập cũ trong hợp đồng để vào, nấu một nồi hải sản cho công nhân ca đêm ("ca đêm ai mà không đói") để đánh lạc hướng; Rin dùng **Nhịp Sóng** làm chậm thời gian để thoát trong lúc đó — mỗi người góp đúng sức mình (có thể cho người chơi điều khiển Bảo một đoạn ngắn).
    5. *Làm lành:* về quán lúc rạng sáng, Bảo nấu gói mì như hồi ký túc xá (gọi lại cảnh `intro_call`): "Lần này tao nói thật hết." Rin: "Lần sau tao đọc điều khoản." → hai người lên kế hoạch đánh sập Thâm Lam cùng nhau (Bảo khai những gì biết về TL Holdings và chị Diệp).
  - **Manh mối gieo trước (chỉ text, rẻ, có thể vào MVP):** log `[WARN] telemetry endpoint unreachable` thỉnh thoảng; dòng nhỏ "SDK © TL Holdings" trong app; logo trên phao Thâm Lam ở cảnh kết giống icon app; Bảo lảng khi nhắc tới nhà đầu tư cũ ("thôi chuyện cũ, ăn mì không?"); Bảo nghe điện thoại rồi cúp vội (giọng nữ, "chị" — chị Diệp); thoại hồi tưởng "đọc điều khoản SDK chưa?"; NEO đôi lúc nói "đang đồng bộ..." rồi tự sửa "à không, không có gì".
- Manh mối đang có trong game: log lỗi của app, nhật ký người gác đèn, chai thư (ông nội), lời ông từ ở miếu, tin đồn ông Tám, phao lạ của Thâm Lam ở cảnh kết.

**Mục tiêu MVP:** kiểm chứng vòng lặp cốt lõi có vui không:

```
Thắp đèn ra khơi → Tìm điểm câu → Câu (minigame) → Xếp vào khoang (lưới xếp hình)
→ Về bến trước khi cạn dầu đèn → Ngủ → Chuẩn bị menu → Nấu & bán → Nhận tiền → Nâng cấp → Đêm mới
```

Áp lực chính ngoài biển là **dầu đèn câu** (kiểu bình oxy của Dave the Diver, không có đồng hồ đếm giờ): dầu cháy dần và tốn thêm mỗi lượt câu/lưới; ở lâu thì câu được nhiều nhưng cạn dầu ngoài khơi là phải gọi cứu hộ (mất tiền). Cùng với chỗ trong khoang và độ bền thuyền. Giờ hiển thị suy ra từ dầu: đầy = 0:00, cạn = bình minh 6:00.

Người chơi trải hết MVP trong khoảng 45 phút (5 ngày; đo bằng bot chơi trọn, xem "Nhịp MVP" ở mục 6). Kết thúc bằng một cảnh ngắn: Rin thấy một xoáy nước phát sáng giữa vùng sương mù ngoài khơi.

Người dùng là dev solo, mới bắt đầu với Godot. Code cần **dễ đọc, dễ sửa, có comment giải thích**, ưu tiên rõ ràng hơn là khéo léo.

---

## 2. Ràng buộc kỹ thuật

- **Engine:** Godot 4.7.2. KHÔNG dùng API hay cú pháp Godot 3.
- **Ngôn ngữ:** GDScript, có khai báo kiểu (typed GDScript).
- **Không dùng plugin/addon** bên ngoài.
- **Góc nhìn (2D):** biển nhìn **từ trên xuống**, quán vỉa hè **top-down 3/4** (ô 16 px, người 16x32). Minigame là UI overlay. Nhánh `try-3d`: biển và quán dựng 3D, minigame vẫn 2D (xem `docs/3D_DEMO.md`).
- **Art:** PNG trong `assets/sprites/` (2D) và `assets/models/ready/` (3D); thiếu file thì game vẽ placeholder. Mỗi loài hải sản có một màu riêng.
- **Độ phân giải gốc:** 640x360, stretch mode `viewport`, aspect `keep`, bật integer scaling. Cửa sổ mặc định 1920x1080 (x3), F11 toàn màn hình.
- **Âm thanh:** chỉ có tiếng tạo bằng code (`Sfx`), chưa có nhạc nền.
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
| `catch_method` | enum            | `ROD` (cần) / `NET` (lưới)                          |
| `difficulty`   | float           | 0.0–1.0, ảnh hưởng tốc độ và độ khó minigame        |
| `base_price`   | int             |                                                     |
| `spawn_weight` | float           | Độ phổ biến                                         |
| `is_aberrant`  | bool            | Cá biến dị, manh mối cốt truyện                     |
| `typical_kg`   | float           | Cân nặng con cỡ trung bình (size 1.0), để hiển thị  |

### Danh sách loài ban đầu

| id                 | Tên              | Hình dạng | Vùng                     | Cách bắt    | Độ khó | Giá |
| ------------------ | ---------------- | --------- | ------------------------ | ----------- | ------ | --- |
| `oc_huong`         | Ốc hương         | 1x1       | NEARSHORE, REEF          | Lưới        | 0.1    | 15  |
| `tom`              | Tôm              | 1x2       | NEARSHORE                | Lưới        | 0.2    | 25  |
| `muc`              | Mực              | 1x2       | NEARSHORE, OPEN_SEA      | Cần         | 0.3    | 30  |
| `ca_thu`           | Cá thu           | 1x3       | OPEN_SEA                 | Cần         | 0.5    | 40  |
| `cua`              | Cua              | 2x2       | REEF                     | Lưới        | 0.4    | 50  |
| `ca_mu`            | Cá mú            | 2x3       | REEF, OPEN_SEA           | Cần         | 0.8    | 90  |
| `ca_thu_phat_sang` | Cá thu phát sáng | 1x3       | OPEN_SEA (~6%), FOG      | Cần         | 0.9    | 200 |

### Thiết kế đang dùng (bổ sung sau Phase 9)

Các mục dưới thay phần tương ứng trong Phase 2–9. Tên class/file chi tiết xem `CLAUDE.md` ("Map of the game").

**Ngày & dầu đèn** (thay Phase 2, không có đồng hồ giới hạn):
- Đêm ra khơi, giới hạn bằng dầu: 100 ≈ 4 phút thật; câu −2, thả lưới −1, kéo lưới −2; minigame và đậu ở bến không cháy dầu. Cạn ngoài khơi = cứu hộ −80k. Dầu đầy lại miễn phí mỗi đêm; nâng cấp "Bình dầu đèn" 100 → 140 → 190. Giờ hiển thị suy ra từ dầu (đầy = 0:00, cạn = 6:00).
- Sau đó: màn Nghỉ (giờ cập bến, mẻ cá, thời tiết, món mới) → Quán 15:00–24:00 (3 phút thật). Không phạt về trễ.
- Không tự chuyển cảnh (kiểu Dave the Diver): đêm chỉ hết khi về bến bấm "Về nhà ngủ" (hoặc bị cứu hộ); ở bến có thể dỡ cá vào kho rồi ra câu tiếp (cá dỡ vẫn tính vào mẻ đêm). Quán: chọn món → Mở quán → hết ca → tổng kết → "Ra khơi". "Sửa quán" có khi quán không phục vụ.
- Lưu 2 lần: lúc ra khơi (tiếp tục ở biển) và ở màn Nghỉ (tiếp tục ở quán, `resume_at`).

**Biển đêm:**
- Đèn thuyền + bóng tối kiểu Dredge: đêm rất tối; bán kính đèn co theo dầu (2D: 100 → 40 px ở zoom x2), chập chờn dưới 15%. Bọt cá, đá, phao chỉ thấy trong vòng đèn hoặc đèn bến; rạng sáng khi dầu dưới ~1/3.
- Điểm câu: mỗi điểm có loài "chủ" (70% lượt). Độ sâu = khoảng cách tới bờ (0 → 1): càng sâu loài đắt càng dễ ra (trọng số × (1 + 3 × sâu × giá/giá max), cá biến dị không được cộng) và cá càng to. "Bóng cá lớn" 5% gần bờ → 40% ngoài khơi, cỡ +0,35. Cỡ ~ N(1 + 0,25 × sâu, 0,15), kẹp 0,6–1,8; giá × cỡ; cá to kéo khó hơn. Cân: từ 1 kg làm tròn kg, dưới 1 kg bội 10 g; "(to!)" từ 1,3; Dex ghi kỷ lục mỗi loài.
- Câu bằng cần (`FishFightGame`, thay TIMING/TENSION/RhythmGame cũ): một lượt thấy 6 cá bơi; A/D đưa thuyền-dây, W/S nâng/hạ lưỡi, Space móc con đang nhắm, rồi W kéo / S nhả dây; E = cú tất tay xanh/vàng/đỏ. Choáng giữ giữa các lượt trong đêm, đầy = Rin ngất, cứu hộ miễn phí. Câu liên tiếp một chỗ làm đàn cảnh giác hơn, con cuối to hơn.
- Lưới (Q, `HaulGame`): bắt tôm/cua/ốc hương (gần bờ chủ yếu tôm, rạn đá chủ yếu cua), mỗi con có cỡ riêng; đầy sau ~90 giây, tối đa 8 con; thuyền mang 2 lưới, lưới còn ngoài biển khi về nhà thì mất. Cần câu chỉ ra cá và mực.
- Tầm thuyền (`BoatData.max_depth`): thúng 0,32 (gần bờ + mép rạn), ghe chèo 0,6, ghe máy 1,0 (cả map). Vượt vạch sóng bị đẩy lùi. Chòi ông Tám, hải đăng, sương cần ghe máy; bè tôm thuyền thúng tới được.
- Thân thuyền: va nhanh mất độ bền (đâm chéo nhẹ hơn), dưới 50% chậm dần; 0% = cứu hộ −150k và vá tạm lên 20% (không kẹt ván). Sửa: thúng 2,5k/%, ghe chèo 4k/%, ghe máy 7k/%; ở bến (F) hoặc tab "Thuyền" trong điện thoại.
- 12 đá ngầm ở rạn/khơi, chỉ thấy trong tầm đèn, không có trên bản đồ.
- Thời tiết (chọn ở màn Nghỉ, đêm 1 luôn lặng): Lặng; Trăng (trời sáng hơn, mực x3); Gió (trôi, dầu x1,15); Mưa (đèn x0,7, cá hiếm hơn, thêm điểm câu).
- Sự kiện đêm (từ đêm 2, 1–2 cái): ghe chết máy (kéo về +80k), chai thư (5 trang truyện của ông Tư), đàn sứa phát sáng (mất bền), đàn cá heo (dẫn tới điểm câu tốt).
- Điểm ghé (E, `PoiDialog`): Miếu Cá Ông (nhang 10k → va đá chỉ hư 50%); Chòi ông Tám (vá +25 bền 40k, chuyện + mẹo theo giai đoạn); Hải đăng Đá Canh Đêm (nhật ký người gác đèn, mỗi lần 1 trang: 2 trước điềm báo, 3 sau, 4 khi sương mở); Bè tôm hùm anh Út (mua cả khoang hoặc từng con với 50% giá).
- Bản đồ điện thoại + bản đồ lớn (M): snapshot bố cục, thuyền và lưới sống; vùng sương theo truyện (trống → "[ERR] NaN" → sương + "???"); tối đa 5 ghim, ghim thành mũi tên mép màn hình.
- Đơn đặt cá (`FishOrders`): mỗi sáng 70% có tin (tối đa 2), loài đã có trong Dex, cỡ 1,0/1,2/1,4, thưởng = giá gốc × cỡ × 2,5, hạn 2 đêm; đầu ca con cá được để riêng và khách quen tới gọi món từ nó.

**Quán vỉa hè (thay Phase 6–7 góc ngang):**
- Bảo đứng bếp từ ngày 1, tự nấu món luộc/hấp/xào/rau theo phiếu cũ nhất (7 s → 5,5 s → 4 s theo cấp Bếp). Rin là phục vụ: bưng, dọn bàn, nướng món nướng ở lò than (`GrillGame`) và rót tháp bia (`BeerPourGame`: giữ để rót, rót nhịp ngắn bọt mỏng, nhả trong dải; tràn = mất 1 lít).
- Khách: bàn 1–2 người (`pair_chance` 0,15), mỗi dòng món là một `TableOrder`, ra món nào ăn món đó, có thể gọi thêm 1 lượt; trả tiền cả bàn một lần (+ tip nếu còn kiên nhẫn); hết kiên nhẫn thì trả phần đã ăn rồi đi. Khách mở dần theo ngày (`data/restaurant/service_day1/2/3/5.tres`): ngày 1 một người một món, bia từ ngày 2, đôi/gọi thêm từ ngày 3, đủ từ ngày 5.
- Thực đơn: số món hải sản theo cấp Bếp 3 → 4 → 5; rau muống + bia luôn có. Menu ít món bị trừ giá (x0,8 với 0–1 món, x0,9 với 2), nhiều món cộng nhẹ (x1,05 / x1,1).
- Tạp hoá Cô Năm: rau 10k/phần hoặc sỉ 10 phần 80k; bia 25k/tháp 3 lít hoặc sỉ 10 tháp 200k. Đồ mua vào túi Rin, phải cất tủ lạnh. Rau già đi mỗi đêm như cá (tủ cấp 0: đêm 2 x0,7, đêm 3 hỏng); bia không hỏng.
- Độ tươi: mỗi đêm cá mất 35 / 25 / 15 theo cấp Tủ lạnh; >60 = x1,0, 30–60 = x0,7, <30 = x0,4, 0 = bỏ.
- Nhân viên (từ ngày 3, tab "Nhân viên" trong điện thoại): đăng tin 50k / 200k / 500k → ứng viên hạng 1/2/3 (lương 90–420k/ca, hạng cao đi nhanh, có tip thêm), tối đa 2 người; Vy tự tới ngày 4 (lương 200k, tip +15%). Nhân viên bưng đĩa và dọn bàn; lương trừ cuối ca.
- Món nổi trong ngày (`DailyTrend`): bán x1,5, khách gọi gấp 3. Thưởng sưu tầm: loài mới (giá gốc x2), mốc 3 loài +100k, 6 loài +300k, kỷ lục cỡ +50k. NEO (trợ lí AI trong app) nói mọi nhắc nhở hệ thống.

**Nhịp Sóng & lịch truyện:**
- Ngày 1 khai trương (+ cảnh bia sau ca); đêm 2 nhận mèo; ngày 2 bán bia; cuối đêm 3 `wave_faint` (con cá thu phát sáng chỉ có trong truyện cắn tay Rin, Rin ngất, Bảo tìm thấy); ngày 3 `wave_awaken` (chạy dưới mưa, mưa đứng lại) → có Nhịp Sóng + giờ cao điểm; sau ca ngày 3 Cô Năm kể chuyện sương; ngày 4 Vy xin việc; đêm 4 điềm báo (`fog_omen`); từ đêm 5 sương mở → xoáy nước → kết. Cá thu phát sáng thật vẫn hiếm ở vùng xa (~6%) và cũng mở điềm báo.
- Nhịp Sóng (C): thế giới chậm ~0,35 vài giây; ở biển chỉ trong minigame, ở quán cả phố chậm còn Rin giữ tốc độ. 2 lần mỗi đêm/ca, +1 mỗi 3 cá dị biến, tối đa 4. Có năng lực thì cá to/dị biến khó hơn, món nướng từ 80k khó hơn, quán có giờ cao điểm.

**Nhịp MVP:** sau khi nén (điềm báo ngày 4, cá phát sáng 6%, ghe 700k/1800k), bot chơi trọn kết ở ngày 5, ~45 phút, mỗi ngày ~10–13 phút. Kéo dây đo bằng bot phản xạ: mực/cá thu gần như luôn được, cá mú khó tới khi nâng cần.

### BoatData (Resource)

`id`, `display_name`, `max_speed`, `acceleration`, `turn_speed`, `spin_drift: float` (mức xoay trôi khi bẻ lái; cao = khó lái), `hold_size: Vector2i`, `max_depth`; thuyền chèo (`rowed`) thêm `stroke_seconds`, `stroke_push`, `stroke_turn`, `glide_drag` (bản 3D).

| Thuyền       | Tốc độ | Xoay trôi | Khoang | Ghi chú                                                                                            |
| ------------ | ------ | --------- | ------ | -------------------------------------------------------------------------------------------------- |
| Thuyền thúng | chậm   | cao       | 4x3    | Thuyền khởi đầu. Bẻ lái là bị xoay vòng, khó đi thẳng — cố ý tạo cảm giác vui và lý do để nâng cấp. Bản 3D: chèo từng nhịp |
| Ghe chèo     | vừa    | thấp      | 5x4    | 700k                                                                                               |
| Ghe máy      | nhanh  | rất thấp  | 6x5    | 1.800k                                                                                             |

### DishData (Resource)

`id`, `display_name`, `ingredients` (fish_id → số lượng), `cook_type: enum { GRILL, STEAM, STIR, BOIL }`, `base_price`; món chợ thêm `market_cost`, `market_pack`, `bulk_packs`, `bulk_cost`, `portion_units`, `keeps_overnight`, `instant_serve`, `unlock_day`.

Mỗi hải sản 2–3 món theo cách nấu: BOIL (Bảo) và GRILL (Rin) có từ đầu, STEAM cần Bếp cấp 1, STIR cần Bếp cấp 2. Món chỉ mở khi đã câu được hải sản đó (`DishBook`).

| Hải sản  | Món (giá k, cấp bếp)                                                     |
| -------- | ------------------------------------------------------------------------ |
| Tôm      | luộc 55 · nướng muối ớt 65 · rang muối 90 (2)                             |
| Mực      | luộc 45 · nướng sa tế 55 · hấp gừng 70 (1)                                |
| Ốc hương | luộc sả 55 · nướng mỡ hành 70                                             |
| Cua      | luộc 85 · hấp bia 105 (1) · rang me 125 (2)                               |
| Cá thu   | canh chua 65 · nướng 80 · sốt cà 100 (2)                                  |
| Cá mú    | cháo 115 · hấp xì dầu 150 (1)                                             |
| Luôn có  | Rau muống xào tỏi 30 (rau mua ở Cô Năm) · Tháp bia con mèo 75 (từ ngày 2) |

### UpgradeData (Resource)

`id`, `display_name`, `description`, `levels: Array[int]` (giá từng cấp), `values: Array` (giá trị từng cấp).

| Nâng cấp           | Giá (k)    | Ảnh hưởng                                                     |
| ------------------ | ---------- | ------------------------------------------------------------- |
| Thuyền             | 700 / 1800 | Thuyền thúng → Ghe chèo → Ghe máy (đổi `BoatData`)            |
| Cần câu            | 350 / 1050 | Câu dễ hơn (x1,0 → 1,2 → 1,4)                                 |
| Bình dầu đèn       | 450 / 1200 | Dầu 100 → 140 → 190                                           |
| Tủ lạnh quán       | 450 / 1200 | Mất độ tươi mỗi đêm 35 → 25 → 15                              |
| Mặt bằng (`seats`) | 450 / 1200 | 4 → 6 → 8 bàn (3D: thuê thêm gian bên trái)                   |
| Đèn lồng & trang trí | 600 / 1500 | Khách tới nhanh hơn, có khách sang                          |
| Bếp                | 550 / 1350 | Bảo nấu nhanh hơn, nướng dễ hơn, mở món hấp / xào, thêm ô menu |

Đồ nghề biển (thuyền, cần, đèn) mua trong tab "Nâng cấp" của điện thoại; đồ quán qua "Sửa quán".

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

### Phase 2 — Thời gian trong ngày và về bến (đã thay)

Bản gốc: ngày ngoài biển 6:00–18:00 có đồng hồ, về trễ thì ca bán ngắn lại. Đã thay bằng đêm giới hạn bằng dầu đèn, không phạt về trễ — xem "Thiết kế đang dùng" ở mục 6.

### Phase 3 — Điểm câu và dữ liệu cá

- Tạo các file `.tres` cho các loài ở mục 6 (trừ cá của zone FOG chưa cần xuất hiện).
- `FishingSpot`: vùng bọt nước nhấp nháy trên mặt biển. Mỗi zone có một số điểm câu ngẫu nhiên đầu ngày.
- Mỗi điểm câu có 2–4 lượt câu, hết lượt thì điểm biến mất (gợi ý đánh bắt có giới hạn). Điểm mới xuất hiện lại vào ngày hôm sau.
- Thuyền dừng gần điểm câu (tốc độ thấp) thì hiện gợi ý "E: Câu". Bấm → chọn ngẫu nhiên một loài theo zone và `spawn_weight` → mở minigame ở Phase 4.
- Trong lúc câu, `DayClock` vẫn chạy (mỗi lần câu tốn thời gian).

**Xong khi:** điểm câu xuất hiện đúng zone, hết lượt thì biến mất, loài được chọn đúng theo bảng.

### Phase 4 — Minigame câu (đã thay)

Bản gốc: TIMING (bấm khi kim trong vùng xanh) và TENSION (giữ kim trong vùng xanh, thanh kéo / độ bền dây); kết quả hoàn hảo → `quality` 1.0, còn lại 0.7; nâng cấp cần nới vùng xanh; cá biến dị nhấp nháy màu lạ. Đã thay bằng `FishFightGame` (cần) và `HaulGame` (lưới) — xem mục 6. Quy tắc `quality` vẫn giữ.

### Phase 5 — Khoang thuyền lưới xếp hình

- `GridInventory` là class logic thuần: `can_place(item, pos)`, `place(item, pos)`, `remove(item)`, `find_free_spot(item)`, hỗ trợ xoay 90 độ.
- Viết scene test cho `GridInventory` với vài trường hợp: đặt vừa, đặt chồng, xoay, ra ngoài biên.
- Kích thước khoang lấy từ `BoatData.hold_size`.
- Câu được cá: tự tìm chỗ trống; nếu không còn chỗ thì mở UI khoang (game tạm dừng, đồng hồ dừng) để người chơi sắp xếp lại, xoay (`rotate_item`), hoặc bỏ bớt món. `open_hold` mở khoang bất cứ lúc nào (đồng hồ vẫn chạy).
- UI hiển thị mỗi món là một khối màu theo hình dạng, kéo-thả bằng chuột.

**Xong khi:** xếp, xoay, kéo-thả, bỏ món đều hoạt động và không đặt chồng lên nhau được.

### Phase 6 — Quán ăn (bố cục đã thay)

Bản gốc: quán nhìn ngang, 4 bàn, click khách để nấu. Đã thay bằng quán vỉa hè top-down 3/4 (2D) và quán 3D — xem mục 6. Vẫn giữ:
- Khách tới theo khoảng ngẫu nhiên, gọi món còn phục vụ được; thanh kiên nhẫn, hết thì bỏ đi và trừ đánh giá.
- Kết quả nấu: Hoàn hảo (x1.3), Ổn (x1.0), Hỏng (x0.5).
- Giá bán = `base_price` × kết quả nấu × trung bình `quality` nguyên liệu × hệ số độ tươi (× cỡ cá). Còn trên 50% kiên nhẫn thì có tip.
- Ca bán 3 phút thực.

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

- Khi đủ điều kiện (câu được cá thu phát sáng lần đầu, HOẶC tới ngày 4), đặt cờ cốt truyện. Từ ngày hôm sau, vùng `FOG` ở rìa map mở ra: sương mù (lớp phủ trắng mờ) và ở giữa có một xoáy nước phát sáng.
- Trong vùng FOG có vài điểm câu chỉ ra cá biến dị.
- Lái thuyền vào xoáy nước → màn hình sáng trắng, hiện vài dòng thoại ngắn của Rin và dòng chữ "Còn tiếp...", rồi quay về main menu.

**Xong khi:** đạt điều kiện thì vùng FOG và xoáy nước xuất hiện, cảnh kết chạy đúng.

---

## 8. Ngoài phạm vi MVP (KHÔNG làm)

Lặn biển, thế giới song song, dị biến cơ thể (trừ Nhịp Sóng), dụng cụ kết hợp hải sản, bẫy / bắt ốc theo thủy triều, special guest, map nhiều vùng biển, nhạc nền + âm thanh thật (hiện chỉ có tiếng tạm tạo bằng code), cốt truyện ngoài cảnh kết Phase 9.

Đã đưa vào sau khi người dùng đồng ý (không còn ngoài phạm vi): lưới, nâng cấp quán, nhân vật phụ (Bảo, Cô Năm, Vy, ông Tám, mèo), hội thoại + cutscene, thời tiết, art thật (2D và 3D), âm thanh tạm, nhân viên, Nhịp Sóng.

---

## 9. Tiến độ

### Bản 2D (MVP gốc)

| Phase                    | Trạng thái   | Ghi chú                                                                                                                                                                                                    |
| ------------------------ | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 — Khởi tạo             | ✅           | Godot 4.7.2; autoload GameState/DayClock/SceneRouter, main menu, sea scene trống                                                                                                                           |
| 1 — Lái thuyền           | ✅           | Map 1920x1280, 3 BoatData, spin drift, phím debug 1/2/3 đổi thuyền                                                                                                                                         |
| 2 — Thời gian & về bến   | ✅ (đã thay) | Thay bằng dầu đèn, xem "Thiết kế đang dùng"                                                                                                                                                                |
| 3 — Điểm câu             | ✅           | 7 loài + fish_catalog.tres                                                                                                                                                                                 |
| 4 — Minigame câu         | ✅ (đã thay) | Nay là `FishFightGame` (cần) + `HaulGame` (lưới)                                                                                                                                                           |
| 5 — Khoang xếp hình      | ✅           | GridInventory thuần + HoldUI kéo-thả, khay "Cá mới" + ô "Bỏ"; overflow = pause; test: scenes/test/grid_inventory_test.tscn                                                                                 |
| 6 — Quán ăn              | ✅ (đã thay) | Nay là quán vỉa hè top-down 3/4 (2D) / quán 3D                                                                                                                                                             |
| 7 — Vòng ngày & nâng cấp | ✅           | Sao = tỉ lệ khách được phục vụ (−1 nếu menu đơn điệu), ảnh hưởng tần suất khách hôm sau; 7 nâng cấp (bảng ở mục 6)                                                                                         |
| 8 — Lưu game             | ✅           | SaveSystem (static) → user://save.json, ghi file tạm rồi đổi tên; field thiếu/sai kiểu → mặc định; test: scenes/test/save_test.tscn                                                                         |
| 9 — Cảnh kết             | ✅           | Điềm báo (cá thu phát sáng / ngày 4) → hôm sau mở FOG góc đông bắc (3 điểm cá biến dị + xoáy nước); xoáy → thoại Rin → "Còn tiếp..." → thẻ tổng kết lượt chơi → menu; F2 debug mở sương                    |

### Trạng thái hiện tại

- **Bản 2D hoàn chỉnh (mốc tính năng):** đủ vòng biển đêm → nghỉ → quán → nâng cấp → kết ở xoáy nước, ~5 ngày / ~45 phút; art pixel đã tích hợp (sprite 16x32, chân dung 128×128, prop quán, thuyền), âm thanh tạm bằng code, hội thoại/cutscene, Guide lần đầu, debug F9 nhảy cảnh (`StoryTimeline`). Bot 2D (`tools/bot/game_bot.gd`) chơi trọn và `TOUR=1` ghé mọi tính năng.
- **Bản 3D (nhánh `try-3d`, đang là bản chạy chính):** menu → intro → biển 3D ↔ thẻ nghỉ ↔ quán 3D ↔ nâng cấp → ngày kế → kết ở xoáy nước, dùng dữ liệu, save và cutscene .tres của game. Đã có:
  - Biển: bố cục như 2D, đàn cá = bọt khí, cảnh quăng cần → minigame 2D, lưới, đá ngầm, sương, POI, sự kiện đêm, thúng chèo từng nhịp.
  - Quán: Bảo nấu, Rin bưng/nướng/rót bia, khách 1–2 người ngồi/ăn/trả tiền, nhân viên, tạp hoá + tủ lạnh, Sửa quán có preview (bàn, trang trí, bếp, tủ lạnh), thuê thêm gian (Mặt bằng).
  - Toàn bộ 45 model 3D (Hunyuan) đã thay vào game; nhân vật có Idle/Walk/Carry, Rin có thêm Cast/Row/Faint/Roll.
  - UI mới "đồ thật ngoài phố" (gỗ, giấy, bảng phấn, bảng hiệu, điện thoại khung máy), ít chữ, icon; art UI đang là placeholder.
  - Mục tiêu: 3 thử thách mỗi ngày, 11 thành tựu, Xóm Đèn Review (bài đăng, follower, hạng quán), xếp hạng tuần với 3 quán đối thủ.
  - Chi tiết và thông số chỉnh được: `docs/3D_DEMO.md`. Art: `ART_PLAN.md`, `docs/ART_PIPELINE.md`, `ASSETS.md`.

### Việc còn lại

**P1 — Playtest & cân bằng**
- [ ] Chơi tay trọn vòng 3D theo `PLAYTEST.md` (bot chỉ kiểm tích hợp, không đo độ khó).
- [ ] Kinh tế: bot 3D có ~15.000–25.000k ở ngày 4–5 → xem lại giá / khách / thưởng; thưởng và mục tiêu thử thách ngày (`data/challenges/`), doanh thu quán đối thủ (`data/social/rivals/`), ngưỡng follower / hạng quán (`data/social/social_tuning.tres`).
  - Đo 30/10 (bot câu hết cá + phục vụ hoàn hảo, nhưng có đồng hồ ca 180 s thật): ~25–30 khách/ca từ ngày 2, thu ~4.000–5.600k ngày 2, ~7.400–8.500k ngày 3–4, cuối ~15.500k; câu 50% cá: cuối 160–9.000k (dao động lớn). Mỗi khách ~100–150k ngày 1, ~270k ngày 3+ (1–3 món/bàn, gọi thêm, x1,3 nấu khéo, size/quality, tip 20%).
  - Vấn đề: tiền nâng cấp (tổng ~12.850k) mua hết vào ngày 3 → sau đó tiền vô dụng; quán là nút thắt (kho 85–100 con, chỉ bán ~30 khách); thưởng thử thách 30–40k, đối thủ 220–940k/ngày, mục tiêu "kiếm 150k + 40k/ngày" quá nhỏ so với 4.000k+/ngày từ ngày 2; bot không mua hàng Cô Năm.
  - Đã sửa: món HOT ở quán 3D bị tính x2,25 (x1,5 hai lần) → nay x1,5.
  - Chỉnh 31/10 (trước playtest, ước người chơi ~60–70% bot có đồng hồ ca): nâng cấp tổng 12.850k → 20.700k (cấp 2 đắt hơn hẳn; thuyền chỉ 800 / 2.800k vì cần ghe máy cho kết); thử thách tăng theo ngày (`reward_per_day` mới: thưởng ~40–60k ngày 1 → ~220–300k ngày 4; mục tiêu "thu" 150k + 1.200k/ngày, số bàn/món +1–3/ngày); đối thủ Chú Hên 600 + 300/ngày, Bến Gió 1.600 + 600, Thâm Lam 2.200 + 900 (vượt lần đầu 200 / 500 / 1.200k); thưởng hạng quán 200 / 500 / 1.200k; thưởng thành tựu x3. Chờ playtest để chốt.
- [x] Quán 3D: nướng / rót bia xong Rin cầm món luôn (bia hiện tháp bia trên tay); Shift = chạy 3,2 m/s tốn thể lực (`StaminaBar3D` trên đầu, đầy thì ẩn; hết thì đi bộ tới khi hồi 35%), Space = lộn. Số trong export của `restaurant_scene_3d`.
- [ ] Tốc độ mới (Rin đi 1,8 / bưng 1,6 / chạy 3,2 m/s, lộn khi Space; khách 1,1 m/s; nhân viên ~0,9–1,6 m/s) có thể làm khách chờ lâu / bỏ về nhiều → chỉnh sau playtest.
- [ ] Chốt font: bộ hiện tại (Paytone One + Be Vietnam Pro + VT323) hay toàn VT323 — ảnh so sánh `build/shot/fontcmp/`.

**P2 — UI còn sót**
- [x] Câu cần toàn màn hình, nhìn ngang mặt cắt biển: nền theo vùng (gần bờ / rạn / khơi / sương), thuyền + Rin 2x nghiêng theo thăng bằng, cần cong theo độ căng, phao, cá dùng sprite (loài chưa có trong Dex là bóng đen), nước bắn / bọt, viền choáng, cá vọt vào thuyền khi bắt được; chỉ số trên tấm gỗ (cuộn dây + vòng căng, thước thăng bằng, choáng), đĩa tất tay chỉ hiện khi cá cắn; tên cá trên thẻ góc phải. Luật chơi không đổi. Thuyền theo cấp nâng cấp: thúng / ghe chèo / ghe máy (`FishFightBoat`, hình tạm riêng từng loại). Không còn thẻ cá góc phải (tên cá ở giữa đáy); thuyền + Rin không xoay, art vẽ đúng cỡ hiển thị (debug 1/2/3 đổi thuyền). Art đợt 1 của Codex: nền, cuộn dây, đĩa quay đạt; 3 thuyền + Rin vẽ lại đúng cỡ hiển thị, mặt boong y = 12: đạt (bản cũ ở `tmp/fishing_rejected/`). Rin quay mặt về phía cá. Cảm giác câu (`FishFightFeel`): tiếng cuộn dây nhanh dần, dây căng rít, đứt dây, tích tắc đĩa quay, cá quẫy trên boong, rung màn hình (cá giật, tất tay vàng/đỏ, đứt dây), khựng 0,07 s + vòng sáng khi cá cắn. Vật lý câu (31/10): chậm hơn (thuyền 0,85, lưỡi 0,42, cá 0,12–0,25); thuyền có quán tính + nảy lại khi chạm mép; lưỡi có quán tính + mồi chìm từ từ; cá quay đầu mượt, trôi lên xuống, va nhau thì đẩy ra / quay đầu (`FishSchoolPhysics`), cá lướt qua đẩy lưỡi; dây câu là sợi dây mềm Verlet (`FishFightLine`: võng khi lỏng, thẳng khi căng); Rin đứng trong thuyền (thân che chân, `FishFightRig`); nhấp nháy: đèn chập chờn, vảy cá loé trong vùng đèn, lưỡi loé, tia sáng khi cá va nhau.
- [x] Dây câu lúc chưa căng: đầu cần → phao → lưỡi là 2 sợi riêng (trên không võng mềm; dưới nước chì kéo gần thẳng, dòng chảy uốn nhẹ), phao nổi trên mặt nước trôi theo lưỡi có độ trễ; cá cắn thì thành 1 sợi căng dần.
- [x] Tông màu ấm cho UI: biển hiệu "XÓM ĐÈN" / nút chính / tem đổi đỏ chói → nâu gỉ sơn mài viền vàng, chữ vàng ấm (menu chính + menu tạm dừng); giấy vở thẻ nghỉ ngà kẻ nâu, mẩu báo ngả vàng, sticker hạng đỏ ớt; nền thẻ nghỉ là bình minh (dải màu chấm ô cờ, mặt trời lặn nửa, vệt phản chiếu) thay 3 khối màu phẳng; nhãn "Đang bán" trên HUD quán đổi nâu.
- [x] NEO nói (`SpeechStrip`): tấm giấy đổi thành màn hình máy xanh đen viền xanh ngọc 1 px (đỏ khi [WARN]/[ERR]), đường quét CRT, vạch quét, góc HUD, glitch nhấp nháy lúc hiện (`NeoScreenFx`), chữ gõ dần có tiếng tích.
- [x] Phong cách UI: viền mỏng 1 px hoặc không viền (brief + các danh sách art đã sửa).
- [x] Biển 3D: thuyền va chạm có vật lý (`SeaBoatImpact3D`): dội ngược theo pháp tuyến (nảy 0,4, ma sát 0,75), đâm lệch thì xoay, thân chòng chành theo lò xo rồi yên, camera rung, nước bắn sáng ở chỗ va, tiếng va; vẫn trừ máu thuyền như cũ. Test `boat_impact_test`.
- [x] `thung_rowing_test` "paddle moves with the stroke" fail từ khi clip Row mới giữ tay trên trước ngực (lưỡi chèo quét quanh tay): test nay đo lưỡi chèo thay vì tay. Lưới giữ khung cũ. Art: `docs/ui_art_needed_fishing.md` (chưa vẽ).
- [x] Tab "Bản đồ" + bản đồ lớn (M): hải đồ giấy (bảng màu Xóm Đèn, ký hiệu viền mực `MapSymbols`, font game), bản đồ lớn trên "PaperPanel".
- [x] Tên loài trong Dex dùng Be Vietnam Pro đậm ("CardLabel") thay VT323.
- [x] Chữ gợi ý / trạng thái trên tấm gỗ khung nấu nướng: Bold, +1 cỡ. (Icon mưa vẫn tạm: việc art.)
- [x] Hoá đơn cuối ca dời sát mép trái (x=8), không che dãy bàn.
- [x] Guide lần đầu "review_tab" (trong PhoneApp): chỉ vào tab Review khi đã có bài đăng.
- [ ] File dài hơn ~200 dòng: đã tách `restaurant_scene_3d.gd` 551→305 (`RinMover3D`, `RestaurantInteract3D`, `RestaurantShift3D`, `RestaurantShop3D`, `RestaurantSetup3D`; phần còn lại là biến + hàm bọc cho test/bot), `sea_scene_3d.gd` 490→330 (`SeaBoatMover3D`, `SeaTrip3D`, `SeaDebug3D`, `SeaSetup3D`), `menu_panel_3d.gd` 330→300 (`MenuPantryStrip3D`), `phone_cards.gd` 236→202 (`PhoneLedger`). Còn: `phone_app.gd` (~260), `phone_review.gd` (~225), `xom_den_review.gd` (~210), các builder 3D (~300).

**P3 — Art**
- [ ] Toàn bộ art UI đang là placeholder → giao Codex theo `docs/UI_ART_BRIEF_CODEX.md` (5 danh sách `docs/ui_art_needed_*.md`).
- [ ] Mèo 3D: chưa đi bốn chân (chỉ bob/sway), chưa có sọc vằn (màu phẳng theo portrait).
- [ ] Tủ lạnh cấp 2 mặt trước kín; chưa rig mặt / ngón tay; mắt tĩnh (chưa chớp, chưa nhìn theo).
- [ ] Rin chưa có clip chờ cá / kéo cá riêng (FishingIdle, Reel).
- [ ] Chân dung mood Vy `che`, `kieu` chưa có (dùng ảnh thường); bản Vy "sau" (tóc buộc cao) chưa có.
- [ ] Kiểm tra / thay nguồn sheet Vy 2D (`tools/ref/vy_spritesheet.webp`, chưa rõ giấy phép) trước khi phát hành công khai.

**P4 — Tương đương 2D / kỹ thuật**
- [ ] Thử thách, thành tựu, Review / xếp hạng chỉ có ở quán 3D (`ShiftCloser` 2D chưa nối).
- [ ] Một số script art chỉ nằm ngoài repo (dựng Rin từ pilot2 `finish_rin2_exact.py`, clip tay `make_rin_arm_clips.py`, `retarget_walk.py`, retarget Walk theo pitch, thêm mắt, Carry đối xứng, sửa trọng số dép) — nếu cần chạy lại phải viết lại vào `tools/art/`. Trong repo đã có `make_rin_faint.py`, `make_rin_row.py`, `recolor_cat_portrait.py` và các tool mắt/tóc/Walk batch.
- [x] Dọn worktree agent cũ: `.claude/worktrees/` đã trống, `git worktree list` chỉ còn nhánh chính.
- [x] `ground_motion_check` chờ theo `roll_seconds` (test cũ chờ 20 khung, cú lăn 0,6 s → FAIL sẵn từ trước).

**Sau MVP (chưa làm, xem §1):** twist app / Thâm Lam, Arc Bảo, Arc Vy phần còn lại (cảnh nhặt cá rơi, đổi ngoại hình, bước 5 trong Arc Bảo), mèo biến mất sau điềm báo + bóng rồng ở cảnh kết, người bạn từ thế giới bên kia.

---

## 10. Bản kinh dị (nhánh `try-horror-1st`) — thiết kế đã chốt 02/11

> Game mới dựng trên bản 3D: góc nhìn thứ nhất, kể chuyện kinh dị dân gian chỉ bằng **3 nơi**:
> phòng ngủ, quán vỉa hè, bến / biển đêm. Phần dưới thay cho đề xuất cũ của §10.
> §8 "thế giới song song / cốt truyện ngoài cảnh kết" được mở cho nhánh này.

### Vòng một ngày

Cả xóm là **một map đi bộ liền** (xem "Map chung" bên dưới): phòng ngủ → cửa → xóm bến → hẻm → phố quán.

1. **Phòng ngủ** (sáng, trời xám): Rin tỉnh dậy trên giường, đọc báo / tờ "Những điều kiêng", E mở cửa ra xóm bến.
2. **Quán** (15:00 → khuya): đi hẻm tới phố là ca tự mở; khách tự tới, tự gọi món; Bảo nấu; Rin bưng và dọn bàn. Hết ca: cả xóm thành đêm.
3. Tối, ở xóm bến: **về phòng, E vào giường = ngủ** (đêm đó tính là ở nhà), hoặc **E ở thúng ông Tư cuối cầu tàu = ra biển đêm**: câu cá, gặp chuyện rợn, tìm manh mối. Cập bến là về lại cầu tàu (đêm), đi bộ về giường ngủ.

Quyết định mỗi đêm (kiểu Exit 8) chính là **giường hay thúng** sau ca, dựa trên điềm báo trong ca, ngoài phố và ở bến.

### Luật vòng lặp (kiểu Exit 8 / Who's At The Door)

- Game diễn ra **mùng 9 → rằm tháng Bảy âm lịch** (tháng cô hồn): 7 ngày. Bộ đếm = **lịch bloc xé** trên tường phòng ngủ.
- Mỗi ngày: ca quán ngắn → chọn đầu phố. **Không có gì lạ → ra bến** (đi biển như mọi đêm). **Có điềm → về nhà ngủ** (kiêng ra khơi). Tối đa một điềm / ngày; có ngày không có gì.
- **Sai = về mùng 9:** ra khơi đêm có điềm → đêm âm, Rin chết ngoài biển, tỉnh dậy mùng 9; đêm bình thường mà ở nhà **hoặc về bến không đủ 3 con cá trong giỏ** (`LoopCalendar.MIN_FISH`) → hồn ma tới nhà: trong màn đen ác mộng có 3 tiếng gõ cửa, tỉnh dậy thấy vệt chân ướt từ cửa tới giường; lịch về mùng 9 (H8).
- **Đêm bình thường đúng = ra khơi + mang về ≥ 3 con.** Bảo nhắc bằng lời mỗi ca ("Tối nay kiếm ít nhất 3 con nghe, mai quán cần cá."); cá mang về hôm sau nằm trên mâm cạnh xe của Bảo; đêm có điềm mà ở nhà thì hôm sau Bảo càu nhàu "Hôm qua mày đi đâu, hết cá bán rồi." (không phạt).
- **Thắng** = qua đủ 7 ngày liên tiếp → đêm rằm (kết). Một ngày cỡ 2–4 phút.
- Rin nhớ mọi vòng: **sổ tay** (hồn ma đã gặp, manh mối) giữ qua reset; ngày, báo, thế giới thì quay lại.
- **Bỏ tiền và nâng cấp** (reset làm chúng vô nghĩa): thuyền / đèn cố định.

### Cốt truyện: "Đêm không trăng ở Xóm Đèn"

- **Bề mặt:** cô hồn tháng Bảy và "sương ăn người": gõ mạn thúng, bóng người đầu cầu tàu, khách không bóng.
- **Sự thật:** không có sương ăn người. **Anh Út, chủ bè tôm hùm** (hiền, hay đùa, khách quen của quán) là kẻ giết người hàng loạt; buôn lậu ngoài vùng sương, giết những ngư dân thấy hắn (ông Tư hai năm trước, người gác đèn năm ngoái, và các ngư dân "mất tích"), cắt dây neo, thả thúng trôi không người, giấu xác dưới bè.
- **Hồn ma là nạn nhân, không hại Rin:** không xác, không đám, không giỗ → **linh hồn kẹt dưới biển**, chỉ tháng cô hồn mới lên được. Họ **chặn Rin ra khơi đúng những đêm hắn đi săn**: điềm báo = lời cảnh báo. Gõ mạn = quay về; bóng đầu cầu tàu = chắn lối; khách không bóng ngồi đúng chỗ anh Út hay ngồi.
- **Vòng lặp:** mỗi lần Rin chết, các hồn ma (ông Tư dẫn đầu) kéo Rin về sáng mùng 9. Rin thấy họ nhờ dấu Nhịp Sóng (nay là khả năng thấy người chết).
- **Hạn chót đêm rằm** (xá tội vong nhân): qua rằm chưa lộ sự thật thì cửa đóng, hồn kẹt thêm một năm.
- **Bỏ ở nhánh này:** cổng song song, cá Ông là sinh vật, Thâm Lam (cùng lắm là tin đồn).

**Manh mối** (mỗi sáng "Bản tin Ngủ Quên" qua khe cửa; ngày càng xa tin càng sâu):

| Ngày | Manh mối |
|---|---|
| Mùng 9 | "Ngư dân thứ ba mất tích trong sương" |
| Mùng 10 | Các vụ đều vào đêm không trăng |
| 11 | Dây neo thúng nạn nhân bị cắt gọn, không phải đứt |
| 12 | Nạn nhân đều bán cá ở cùng một bè trước khi mất tích |
| 13 | Trang nhật ký người gác đèn: "...đèn xanh ở bè, không phải sương..." |
| 14 | "Bè tôm hùm mở rộng, chủ bè mua ghe mới"; Cô Năm: "thằng Út dạo này dư tiền" |
| Rằm | Đêm cuối |

Mảnh phụ: Bảo kể Út trả tiền ướt; mèo không lại gần bàn Út; NEO `[WARN] tín hiệu lạ quanh bè lúc 2:00`.

**Điềm báo (phong tục tháng cô hồn bị lệch):** mâm cúng cô hồn trước quán bị ăn dở; vàng mã bay ngược gió về phía bến; tiếng gọi tên Rin lúc khuya; đồ phơi đêm chưa rút; tiền lẻ rơi trên đường ra bến; đèn hoa đăng trôi ngược vào bờ; đèn hải đăng đổi màu; bóng người đầu cầu tàu; gõ mạn thúng ba lần; mèo nhìn bàn trống.

**Đêm rằm:** anh Út ghé quán mời **trà gừng "cho ấm rồi ra khơi"** (thay thuốc an thần):
- **Uống** → ngoài biển buồn ngủ, chết → kết xấu: Rin thành một hồn kẹt; cảnh cuối tháng Bảy năm sau, qua mắt hồn Rin, một ngư dân trẻ khác bước vào quán.
- **Không uống, ra khơi** → hồn ma dẫn tới bè, NEO quay được Út kéo xác → kết thật: tìm được xác dưới bè, đêm rằm cả xóm thả hoa đăng, hồn ma đứng dọc cầu tàu rồi tan, ông Tư đi cuối.
- **Không uống, ở nhà** → sống, hắn chưa lộ, cửa đóng, hồn còn kẹt → lịch về mùng 9.

### Đã chốt

- **Góc nhìn thứ nhất** ở cả 3 nơi (đã có `FirstPersonView3D`), không thấy tay Rin; PSX look (F8) giữ để dùng cho không khí.
- **Không cutscene, không portrait.** Thoại là **chữ thẳng trên màn hình** (phụ đề: "Bảo: ..."), nhân vật nói trước mặt Rin. Các mốc đang nằm trong cutscene (Nhịp Sóng, mèo, Vy, intro) chuyển thành sự việc + thoại trong thế giới.
- **Quán:** bỏ màn lên thực đơn. Chỉ còn **vài món cố định** (2–3 món của Bảo + bia). Khách tự gọi; Bảo nấu xong món nào thì để lên bàn kê, Rin đem món đó ra đúng bàn. Vy (bạn Bảo) phụ bưng / lau bàn, chậm hơn Rin. **Bia luôn có**: E ở thùng bia là cầm tháp bia (không minigame, không mua). **Bỏ nướng** (lò than, GrillGame).
- **Cô Năm:** đến gần chỉ nói chuyện (lời đồn, điềm báo), không bán gì. Bỏ tạp hoá, tủ lạnh, túi hàng.
- **Câu cá chỉ phục vụ cốt truyện:** cá không thành món, không thành tiền. Cá thường để "đời thường"; cá dị biến / cá của người chết là manh mối và điềm.
- **Không tiền, không nâng cấp** (xem Luật vòng lặp). Bỏ: Sửa quán, thử thách, thành tựu, Review / xếp hạng / đối thủ, kho cá + hư hỏng, đơn đặt cá, món hot.

### Phase

| Phase | Nội dung | Ghi chú |
|---|---|---|
| H1 — Khung 3 nơi + vòng lặp ✅ (map đã gộp: xem "Map chung") | Phòng ngủ 3D (dựng bằng code), lịch bloc + báo qua khe cửa, cửa → "Ra quán"; hai đầu phố ở quán (về ngủ / ra bến); cập bến → phòng ngủ; ngày mới / reset về mùng 9 theo đúng-sai; autosave ở phòng ngủ | Xong: `LoopCalendar` (pure, test `loop_calendar_test`), `BedroomScene3D` + `BedroomBuilder3D`, `NewsData` (`data/story/news.tres`), `StreetEnds3D` (trái VỀ NHÀ, phải RA BẾN; không dùng trong ca), `OnScreenText` (chữ trần trên màn hình). Chơi mới / tiếp tục → phòng ngủ; chỉ autosave ở phòng ngủ; nút "Ra khơi" ẩn; ra bến không tăng ngày. Bot: mùng 9 → cố ý về nhà ngày 2 → reset → rằm → kết. Chưa có điềm (H5) nên mọi đêm "ra bến" là đúng |
| H2 — Quán gọn ✅ (phần chơi) | Bỏ thực đơn, nướng, tạp hoá, tủ lạnh, Sửa quán; món cố định + bia E; Cô Năm chỉ thoại | Xong: `FixedMenuData` (`data/restaurant/fixed_menu.tres`: tôm luộc, ốc hương luộc sả, canh chua cá thu, bia), ca tự mở khi tới quán (`auto_open`, test tắt được), ca 120 s, bia E ở thùng = cầm tháp ngay, bỏ lò nướng, Cô Năm nói lần lượt `data/story/co_nam.tres` (`LinesData`), ẩn nút Thực đơn / Sửa quán, bỏ F1/F2 debug. Code panel thực đơn / chợ / túi / Sửa quán vẫn còn (không gọi tới) → dọn ở H4 |
| H3 — Thoại phụ đề ✅ (3D) | `DialogueBox` → phụ đề không portrait; bỏ phát cutscene, mốc cốt truyện thành sự kiện trong thế giới | Xong: `DialogueBox` thành phụ đề (tên màu + chữ viền, không chân dung, không giấy); quán và biển 3D không còn cutscene; xoá `StoryBridge3D`, `CutsceneStage3D`, `CutsceneMarkers3D`, `DebugJumpMenu` (F9), `StoryTimeline`, F3 cutscene debug và test liên quan. Mốc cũ trong cutscene (Nhịp Sóng, mèo, Vy) hiện không mở được nữa → làm lại bằng sự kiện ở H5/H6 nếu cần |
| H4 — Dọn hệ thống ✅ | Gỡ thử thách, Review, đối thủ, kho cá, đơn cá, món hot, tiền + nâng cấp; (mở rộng theo yêu cầu) bỏ NEO, điện thoại, Nhịp Sóng, nhân viên / Vy / mèo, thời tiết, sự kiện đêm, lưới, nơi ghé có thoại | Đợt 1: xoá bản 2D không còn dùng + UI 3D chết (thực đơn, chợ, túi, Sửa quán, RestaurantShop3D). Đợt 2 (xong): **tiền + nâng cấp** (`GameState.money` / `upgrade_levels`, `UpgradeData`, `data/upgrades/`, tab Nâng cấp, phí cứu hộ, tiền kéo ghe, vá thuyền tốn tiền: F ở bến / ông Tám vá **miễn phí**; thúng + bình dầu 100 cố định: `SeaScene3D.boat_data` / `oil_capacity` export); **thử thách + thành tựu** (`RestaurantGoals3D`, `ChallengeCard3D`, `DailyChallenges`, `Achievements`, `LifetimeStats`, `ShiftLog`, `data/challenges`, `data/achievements`, toast); **Review / follower / xếp hạng / đối thủ** (`RestaurantSocial3D`, `XomDenReview`, `RivalRanking`, `data/social`, `scenes/ui/social`); **đơn cá + khách quen** (`FishOrders`, `GameState.orders`, regular_queue) và **món hot** (`DailyTrend`); **kho cá + hư hỏng** (`GameState.storage`, `MarketStock`, `MenuPlan`, `DishBook`, `KitchenLogic`, `TableBill`…: dỡ cá ở bến chỉ là làm trống khoang); **hoá đơn ca** (`ShiftReceipt3D` + receipt rows): hết ca chỉ còn câu "Bảo: Hết ca rồi…"; khách vẫn trả bill nhưng **không thành tiền**: cộng vào `earned` ẩn → `day_history` cho thẻ kết (EndingStats / RunClipping); **điện thoại** (PhoneApp, J, M, bản đồ, ghim) + **NEO** (avatar, màn máy, mọi câu "NEO:" / [WARN] / [ERR]; `SpeechStrip` chỉ còn giấy; nhắc dầu còn một câu của Rin "Đèn leo lét rồi... về thôi."); **QuestTracker** (bỏ hẳn: bản kinh dị không có chữ nhiệm vụ); **Nhịp Sóng** (WaveMark / WavePower, C); **nhân viên / Vy / mèo** (StaffRoster, data/staff, PetCat, thoại mèo / Vy); **thời tiết** (WeatherData / Catalog: một đêm lặng), **sự kiện đêm** (ghe chết máy, chai thư, sứa, cá heo), **lưới** (Q), **nơi ghé có thoại** (miếu, chòi ông Tám, hải đăng; PoiDialog): mô hình vẫn đứng làm cảnh; **bè anh Út giữ làm cảnh, bỏ mua / bán cá** (HoldUI hết chế độ bán); lò nướng / CookingOverlay (bia E là xong), F4 debug, phím 1-3 đổi thuyền; input `open_phone`, `open_map`, `wave_power`, `drop_net`, `repair_boat`. Save v3: bỏ các trường trên (save cũ vẫn đọc được, trường thừa bị bỏ qua; test). Bot: không mua nâng cấp, không thả lưới, in `rating`. Dò phụ thuộc (đường dẫn `res://` + `class_name`) rồi xoá ~220 file không còn ai gọi: cả `scenes/restaurant/` (2D), gần hết `scenes/sea/` (2D), `scenes/cutscene/`, `scenes/rest/`, dữ liệu món không thuộc thực đơn cố định. **Giữ:** `DialogueBox` / `DialoguePortrait` / `DialogueLibrary` / `Dialogue` (không ai gọi nữa nhưng là hạ tầng thoại có thể dùng cho cảnh kết H7), `data/boats/ghe_*.tres` (test chèo thúng), `PersonRig3D` biến thể vy/staff/cat (art). Chuỗi câu cá (FishFightGame, CastCinematic3D, SeaCatch3D, HoldUI, GridInventory) chỉ sửa tối thiểu vì sắp được thay bằng câu cá góc nhìn thứ nhất. Sửa 2 dòng trong `dark_night_3d.gd` (bỏ `phone_app`, câu NEO [ERR] → "Cái gì... rè rè trong tai vậy?"). Test xoá: challenges, social, orders, trend, phone, staff, receipt, cooking, places, wave, night, asset/secondary/restaurant art preview; viết lại save, speech (SpeechStrip), restaurant3d_debug_smoke |
| H4b — Âm thanh rè ✅ | Nền kinh dị tổng hợp bằng code | `HorrorBed` (systems/audio): băng nhiễu, đĩa than lách tách, radio hỏng (dải giữa ngắt quãng + huýt dò sóng), glitch (hụt tiếng / vấp), âm trầm lệch nhịp; `Sfx.bed("room" / "street" / "sea")` chạy cùng ambience; tạo khi cần lần đầu (~0,1 s), không tạo khi headless. **Âm thanh xóm (map liền):** `SfxEnvRecipes` (tạo khi dùng lần đầu): cửa gỗ mở / đóng, bước chân gỗ / cát / đất (3 kiểu mỗi loại, `Sfx.step("wood")`), xe máy chạy ngang xa (doppler), chó sủa xa, gà gáy, chuông gió, tre kẽo kẹt; loop mưa mái tôn, ve / dế chạng vạng, gió lùa dừa + tre, nước vỗ cầu tàu, xóm đêm xa (radio hát nhỏ, chó sủa); nền mới `house` (nghe qua vách), `lane`, `waterfront` (nền cũ không đổi); `SfxSynth` thêm `crackle`, `hp`, `am`, `fade`, `lp` cho sóng tone; test `sfx_library_test` |
| H5 — Điềm báo ✅ | Điềm trong ca và ngoài phố (data `.tres`), chọn theo đêm | Xong: `OmenData` / `OmenCatalog` (`data/omens/`, 9 điềm: quán = mâm cúng bị ăn dở, bảng LED hiện "CHÁO TRẮNG", xe máy đậu quay mặt vào quán đèn sáng không ai xuống; phố = vàng mã bay ngược gió về bến, tiền lẻ rơi thành vệt tới bảng RA BẾN, tiếng gọi "Rin ơi" từ phía bến; bến = hoa đăng trôi ngược vào bờ, hải đăng xanh, bóng người đầu cầu tàu). `OmenPicker` (pure, test `omen_test`): không có điềm mùng 9 và rằm, các ngày khác 50% (`chance` trong catalog), không lặp điềm hai đêm liền, seed theo (số vòng, ngày) nên chơi lại / bot ra giống nhau; chọn ở `BedroomScene3D._ready` → cờ `omen_tonight` + `omen_id`. **Điềm giả:** mâm cúng, đốt vàng mã trong thùng, hoa đăng là phong tục (`custom = true`): đêm thường hiện 1–2 cái ở dạng đúng (rợn mà đúng), đêm có điềm hiện 1 cái + điềm sai (`OmenPicker.customs` / `state`); các vật khác (bảng LED, xe máy, lá khô, tiếng gọi "Tèo ơi", hải đăng vàng, đèn cọc đầu cầu) đêm nào cũng ở dạng thường để so. Cảnh: `scenes/omens3d/` (`RestaurantOmens3D` một dòng trong quán, `DockOmens3D` một dòng trong `SeaSetup3D`). Cô Năm có câu riêng cho mâm cúng / xe máy. Bến: chưa rời bến thì **R = thôi, về nhà ngủ** (`DockTurnBack3D`, tính là ở nhà) để điềm ở bến vẫn công bằng. Bot: biết hết, đêm có điềm về nhà, ngày 2 vòng đầu cố ý chọn sai rồi kiểm tra về mùng 9 |
| H6 — Đêm âm + khách lạ (đêm âm ✅) | Biến thể biển khi ra bến đêm có điềm; khách lạ sau khuya | Xong đêm âm: `DarkNight3D` (scenes/sea3d, chỉ gắn khi có `omen_tonight`, đêm thường không đổi): sương dày xanh bệnh, nước tối, trăng đỏ thấp, đèn đảo tối (`DarkNightLook`, số trong Resource), dầu đèn cháy x2.2, nền âm `sea_dark` (HorrorBed: radio + glitch nhiều hơn, drone trầm 41 Hz); quanh mép đèn: gõ mạn 3 tiếng (`knock3`), thì thầm ("...về đi...", "...hắn đang ở ngoài này..."), nhiễu radio + đèn chớp + NEO `[ERR]`, bóng người đứng trên mặt nước / đầu + mắt lướt qua, nhìn thẳng là biến (`DarkNightFigure3D`); sau 60 s xa bến / ra xa 55 m / dầu còn 20% / 3 s sau khi câu → `SeaTrip3D.taken_by_the_sea`: đèn chớp tắt, gõ mạn, tay ngoi lên mép thúng, "Buông ra!", thúng bị kéo chìm, tối dần (`DarkNightTaken3D`, ~6 s) → phòng ngủ → reset mùng 9. Cập bến bình thường đêm đó vẫn là reset (luật `LoopCalendar`). Test `dark_night_test`. **Còn:** khách lạ ở quán sau khuya |
| H6b — Xóm bến, ác mộng, manh mối ✅ | Nhà Rin cạnh bến; sai thì tỉnh dậy như ác mộng; đêm thường có việc nhỏ cho manh mối | `WaterfrontScene3D` + `WaterfrontBuilder3D` (sáng: ra quán; tối: cửa nhà = ngủ, thúng = ra khơi; điềm ở bến `DockOmens3D` chuyển về đây, có hải đăng gần + xa), quán chỉ còn một lối "VỀ XÓM" (đầu phải), phòng ngủ ra cửa là xóm; `NightmareWake3D` (đen + tim đập, thở hắt, nằm nhìn trần rồi bật dậy rung, chỉ "Hộc... hộc..."); ở nhà sai đêm → báo sáng có `NewsData.missing_item` + Cô Năm đồn (cờ `news_missing`, một buổi sáng; H8 thay bằng hồn ma gõ cửa + vệt chân ướt); `NightErrand3D` (đêm thường: dấu sáng ~20 m, E vớt chai thư / dây neo / trang nhật ký, `data/story/clues.tres`, sổ tay `note_clue_<n>` giữ qua reset). Nguyên tắc: thông tin truyện đến từ đọc (báo, chai thư, nhật ký) và nghe người khác nói / đồn — Rin không tự thoại ra. Test `night_errand_test` |
| H7 — Kết ✅ | Đêm rằm: trà gừng của anh Út (uống / không) → 3 kết | `RamNight` (pure, test `ram_night_test`): cờ `ram_tea` (drank / refused, chưa nói = không uống) + ra bến / ở nhà + `ram_exposed` → kết; `LoopCalendar` giao rằm cho nó (ở nhà, hoặc ra mà không tới bè = reset). Thoại trong `data/story/ram_lines.tres` (`RamLinesData`). `scenes/ram3d/`: `RamGuest3D` (một dòng trong quán: anh Út tới khi còn 45% ca / lúc đóng ca, bàn riêng cạnh bảng, E → phụ đề + chọn 1/2; Bảo nói một câu khi ổng tới; Cô Năm có câu rằm), `RamShore3D` (tối rằm ở xóm bến: 3 người thả hoa đăng, nói khi Rin tới gần), `RamSea3D` (SeaSetup3D một dòng; không có việc vớt đồ đêm rằm). **Uống + ra khơi:** `RamDrowse3D` mờ + tối + mí mắt sụp, thúng nặng tay và tự xoay, R ở bến vô hiệu, gõ mạn 3 lần + thì thầm, ~40 s thì ghe đèn xanh của Út áp mạn ("Ngủ đi em..."), mắt nhắm, tiếng nước. **Không uống + ra khơi:** vệt đèn ma từ bến tới bè + hồn đứng trên nước; cách bè 11 m: `RamReveal3D` Út kéo xác quấn lưới ra mép bè dưới đèn xanh, chớp nhiễu, thả xuống, nhìn thẳng Rin ("...Rin?"), Rin chèo lui vào tối. Sau đó `RamEpilogue3D` (cảnh riêng, camera cố định, chữ tự chạy): kết thật = rạng sáng, cả xóm kể chuyện tìm xác dưới bè, thả hoa đăng, 7 hồn đứng dọc cầu tàu tan dần, ông Tư cuối (≥ 4 manh mối thì ông nói một câu); kết xấu = tháng Bảy năm sau qua mắt hồn Rin dưới nước, một ngư dân trẻ đi lên lối RA QUÁN, Út đứng chờ mời trà rồi quay nhìn xuống nước. Rồi màn kết (thẻ chữ theo kết, kết xấu nền tối "Hết?", run card giữ nguyên). **Ở nhà (uống hay không):** ngủ qua, ác mộng tỉnh dậy + thì thầm "...qua rằm rồi... thêm một năm nữa...", về mùng 9 (uống + ở nhà = như không uống). Không dùng NEO / điện thoại. Bot: rằm từ chối trà → ra bè → kết thật (`RAM ENDING`) |
| H8 — Câu cá góc nhìn thứ nhất + luật 3 con ✅ | Câu cá 3D từ thúng thay minigame 2D; đêm thường phải mang về ≥ 3 con | **Câu:** `Fishing3D` (scenes/fishing3d, node "Fishing" trong biển; `tick()` là cả bước khung hình để bot/test lái): chuột trái (action `cast`) quăng phao tới chỗ đang nhìn, 6–12 m, kẹp vào nước trong tầm thúng (`FishingSpot3D`); phao nhấp nhô, cá cắn sau 3–8 s (gần bọt khí x0,45; nước quanh bến 12 m không cắn); cắn: đầu cần rung, phao chìm, dấu "!" vàng 1,2 s — bấm trong lúc đó là móc, trễ là mất (phao nổi lại, chờ tiếp), bấm trước khi cắn là thu dây; giữ chuột kéo, thả cho chùng (`BiteReel3D` + `ReelLogic` thuần trong systems/fishing: lực căng tăng khi kéo, cá vùng chạy theo đợt — mạnh hơn với cá to / dị biến (`strength_of`), căng tối đa > 0,6 s là đứt dây; kéo hết dây là lên cá; số trong `ReelTuning`); cần cong + dây từ trắng ngả đỏ (`Rod3D`, ImmediateMesh) + một vạch nhỏ dưới tâm (`ReelBar`); cá lên tay trước mặt, quay nhìn giỏ cá (`FishBasket3D` trong thúng, cá xếp chồng + số) bấm E "E  Bỏ vào giỏ"; đang cầm cá thì không quăng được; WASD lúc chờ = thu dây; đèn vẫn cháy dầu khi chờ cá. Loài + cỡ vẫn từ bãi cá (`SeaShoals3D`, `CatchRoll`), vẫn ghi `GameState.record_catch` (thẻ kết đếm cá) + cá thu phát sáng vẫn gọi `Story.on_fish_caught`. **Luật 3 con:** `LoopCalendar.MIN_FISH = 3`; cập bến (`SeaTrip3D._go_home`) gọi `choose(true, giỏ)` → cờ `night_catch`; `take_result`: đêm thường ra khơi < 3 con hoặc ở nhà = reset + `last_calm_miss`; đúng thì để lại `shop_fish` (số cá) / `bao_no_fish` (ở nhà đêm có điềm). Phòng ngủ: `last_calm_miss` → `NightmareWake3D` gõ 3 tiếng trong màn đen (`knock3`) + `WetFootprints3D` (vệt chân ướt cửa → giường, không chữ). Quán: `RestaurantFish3D` (mâm cá trên ghế đẩu cạnh xe Bảo, số con = `shop_fish`; Bảo nói một lần mỗi ca, trừ rằm). **Bỏ:** `FishingOverlay3D` + scenes/fishing3d cũ, cả `scenes/fishing/` (FishFightGame, FishingMinigame, HaulGame, MinigameBase, view/rig/line/gauges/feel/school physics), `FishPortrait`, `CastCinematic3D`, `SeaCatch3D`, khoang lưới (`GridInventory`, `InventoryItem`, `HoldUI`, hold grid view/painter, `NewCatchCard`, Tab/H, E dỡ cá ở bến), tin báo người mất tích (`NewsData.missing_item` / `news_missing`) + câu đồn của Cô Năm; test cũ (fish_fight, fishing_minigame, fishing3d_inventory, fishing3d_overlay_smoke, cast_cinematic_3d, grid_inventory). Test mới: `reel_logic_test`, `fishing3d_test`, `ghost_visit_test`; viết lại loop_calendar / game3d_loop / sea3d_parity / sea3d_hazards / smoke. Bot: đêm thường câu 3 con qua đúng hàm của input (cast → force_bite → press → kéo khi dây chưa căng → drop_in_basket), kiểm tra vệt chân ướt chỉ có sau đêm thường sai, in số cá trên mâm |
| Research 1–8 ✅ | Áp dụng mục 1–8 "Top 10" của `docs/HORROR_RESEARCH.md` | **1.** Tờ "Những điều kiêng" (giấy của bà) ghim trên tường cạnh cửa phòng ngủ (`BedroomBuilder3D.NOTE`, texture `paper_diary_page`), E đọc qua `PaperReader` (kiểu mới "note"); chữ trong `data/story/kieng_note.tres` (`NoteData`), dạy luật mà không gọi tên cơ chế. Phòng ngủ: E chọn thứ đang nhìn (cửa / báo / tờ giấy, `BedroomScene3D.target()`). **2.** `Sfx.duck(giây, mức)`: hạ nền + ambience gần im 1–2 s trước gõ mạn (`DarkNight3D`), tiếng gọi tên, gõ cửa trong `NightmareWake3D`, lúc tới bè ở `RamReveal3D`; im bặt hoàn toàn đúng một lần: lúc anh Út nhìn thẳng Rin (1,5 s). **3.** `Sfx.play_at(tên, vị trí, host)` (`AudioStreamPlayer3D`, im khi headless): gõ mạn ở phía mạn thúng hướng về bè, gõ cửa ở cửa phòng, tiếng gọi "Rin ơi" từ cuối phố phía bến (tiếng gọi "Tèo ơi" từ nhà xa phía bên kia); công thức âm chuyển sang `SfxRecipes` (Sfx.SOUNDS / LOOPS vẫn dùng như cũ), thêm `call`, `slap`, `tock`, `plip`, `gust`, `coins_wood`. **4.** Đêm lặng không có trạng thái thua: `ReelLogic.calm` (đặt khi móc cá, không có `omen_tonight`): lực căng kẹt ở `calm_tension_cap` 0,9 (không đứt), kéo khi căng không ăn dây, dây chỉ còn co lại tới 0 trong `calm_max_seconds` 14 s; đứt dây chỉ ở đêm âm. **5.** `CalmNightSounds3D` (đêm lặng, không rằm): 25–60 s một tiếng giả (cá quẫy sau lưng, mái chèo chạm thúng một cái, phao giật không cá, tiếng tõm xa), không bao giờ là `knock3`. **6.** `OmenData.subtlety` (0 rõ – 1 khẽ) cho cả 9 điềm; `OmenCatalog.allowed`: ngày ≤ 3 chỉ điềm ≤ 0,4, vẫn tất định theo (vòng, ngày). Điềm khẽ có tín hiệu thứ hai: tiền lẻ / vàng mã → tối ở xóm bến bà Sáu nói + tiếng đặt ở cầu tàu (`OmenEcho3D`, `echo_line` / `echo_sound`; đêm tiền lẻ còn vệt tiền trên ván cầu tàu); hoa đăng / bóng cầu tàu → câu Cô Năm ở quán. **7.** Sai đêm → cờ giữ qua reset `note_missed` (id điềm hoặc "calm"); báo mùng 9 có một ô "Người già dặn: ..." (`OmenData.missed_hint`, `NewsData.calm_missed_hint`, `PaperReader` "aside"); `NightmareWake3D` có gõ cửa còn 4,6 s. **8.** `LoopCalendar.dread_level()` (0 mùng 9 → 1 rằm): đêm âm mùng 9–10 chỉ có tiếng; trước 13 tháng Bảy bóng đứng xa ≥ 15 m; tiếng giả đêm lặng dày hơn theo ngày. Mặt anh Út (`guest_rich`) chỉ có trong các cảnh rằm. Test: thêm vào `omen_test`, `reel_logic_test`, `fishing3d_test`, `ghost_visit_test`, `loop_calendar_test`, `dark_night_test`; bot kiểm tra ô gợi ý trên báo sau lần reset |
| NPC: PSX pack ✅ | Thay model mọi NPC (trừ Rin) bằng gói nhân vật PSX (rig Mixamo), dùng lại clip cũ | `PsxCharacterVisual` (scenes/story3d, cùng API `RinPilotVisual` mà `PersonRig3D` cần; `CAST`: id biến thể → file). Bảo = Male_46, anh Út = Male_35, chú Hai / ông Tám = Male_49, hồn ông Tư = Male_45 (`ong_tu`), Cô Năm = 51_Female, khách = 9 model (`guest_1..9`, nam lẻ / nữ chẵn, `PersonRig3D.next_guest_variant()`; mỗi đơn đổi khách + bạn ngồi cùng), người chết đuối = Male_57 / 31_Female (`drowned`, xen kẽ; `RamFx3D.ghost` mặc định, giữ texture dưới lớp ma). **Retarget lúc import:** BoneMap → `SkeletonProfileHumanoid` cho cả FBX của gói (Mixamo) lẫn nguồn clip `clip_source.glb` (bản sao `bao.glb` rig batch: Idle / Walk / Carry), đổi tên xương theo profile, skeleton `%GeneralSkeleton`, overwrite axis + fix silhouette (trừ cột sống / chân: gói giữ dáng tự nhiên, clip bỏ track Spine..Head). `tools/psx_chars/` (bone map + bật retarget trong `.import`). Ngồi (`SeatedAnimation3D`) chia track vị trí cho `motion_scale`, gập gối bằng chia đôi cho bàn chân chạm đất; bước chân (`GroundGait3D`, `GroundFootPlant3D`) tra xương qua `RinPilotVisual.bone()` ("Foot.L" → "LeftFoot"), đo tốc độ theo từng model. Rig Rin (Quaternius, chân gắn vào Root) không hợp profile nên không làm nguồn clip. Test `psx_characters_test`. **Giấy phép gói chưa rõ** (`assets/models/psx_chars/SOURCE.md`): model batch cũ + `BatchCharacterVisual` giữ lại làm phương án lùi; Cô Năm (đứng yên) trượt chân nếu phải đi |
| Menu + Cài đặt ✅ | Menu chính, tạm dừng, cài đặt, phiếu chơi thử cho bản kinh dị | Menu chính: nền `title_keyart` (đẩy vào chậm, đèn cầu tàu chập chờn), "RIN" + "Tháng Bảy ở Xóm Đèn", Tiếp tục / Chơi mới (bấm 2 lần nếu có bản lưu) / Cài đặt / Thoát (`MainMenuView`, `HorrorUi`); bỏ nền đêm cũ + `HelpPanel` (danh sách phím nằm trong Cài đặt). `GameSettings` (systems/settings, tĩnh, `user://settings.cfg`: controls/mouse_sensitivity, invert_y; audio/volume, muted; video/psx (mặc định bật), fullscreen) + `SettingsPanel` dùng chung; `FirstPersonView3D` đọc độ nhạy / đảo trục; PSX áp cho mọi người (`SceneRouter.set_psx_look`, không chạy headless), F8 debug + F11 lưu vào cài đặt. Esc (`PauseMenu`): Tiếp tục / Cài đặt / Về menu (2 lần) / Thoát, SceneRouter tự gắn vào cảnh 3D chưa có (phòng ngủ, xóm bến). `PLAYTEST.md` viết lại. Test `settings_test` |
| Sổ tay + thẻ kết có tranh ✅ | N mở sổ tay của Rin; kết rằm có tranh | `RinNotebook` (scenes/ui, FirstPersonView3D mở bằng action `notebook` = N; tạm dừng game): bìa `notebook_cover` chữ tay "SỔ TAY / Rin" (font Patrick Hand, OFL), E / click mở trang đôi `notebook_page`, A/D lật, N/Esc đóng; mỗi manh mối vớt được ghi dưới ngày âm (`note_clue_<n>` = ngày n), rồi các câu "Người già dặn: ..." đã nghe (`LoopCalendar` giờ giữ mọi lần sai: `note_missed_<id>`), trống thì "Chưa ghi gì."; logic thuần `NotebookPages` (chọn, xếp, ngắt dòng theo thước đo font, chia trang), test `notebook_test`; HelpEntries có "N Sổ tay". Màn kết rằm: `EndingPainting` (`ending_true` / `ending_drowned`) hiện dần từ đen 3,5 s, các câu kết viền tối ở một phần ba dưới, rồi tranh tối đi cho run card |
| Map chung ✅ | Một map góc nhìn thứ nhất liền: phòng của Rin trong nhà → cửa → xóm bến (cầu tàu, thúng ông Tư, hải đăng) → hẻm → phố quán; biển đêm vẫn là cảnh riêng | `VillageScene3D` (`scenes/village3d/`, **extends `RestaurantScene3D`**: phố quán giữ nguyên toạ độ x -20..20 và toàn bộ code ca / phục vụ / Bảo / xe khách / A* / điềm / anh Út; `RestaurantRoomBuilder3D` mở một khe ở tường cuối phố phía đông z 1..6 khi host có `street_exit`). Bố cục `VillageLayout3D`: hẻm x 20..47 (rộng ~5,4 m, đất `lane_dirt`; nhà vôi xanh `blue_lime_wall`, tường gạch `brick_wall_old`, rào tre, bụi chuối, 2 cột điện + dây võng, miếu nhỏ ven đường — hình khối tạm, chờ model), xóm bến = các mảnh của `WaterfrontBuilder3D` đặt ở (64, 0, -4.5) (đất 34×12 m, cầu tàu ~13 m tới thúng, 2 hải đăng, biển 120×110 m lệch về đông để không chạy dưới dãy quán), phòng = `BedroomBuilder3D` ở (61.5, 0, 6.9) (5×4 m, sàn `tiles_cement_floor`, khe cửa ở vách bắc, mái tôn) — cửa phòng chính là cửa nhà nhìn ra biển; tường vô hình quanh bãi, mép bờ, hai bên cầu tàu; đầu tây phố có mặt nhà chắn, đường nhựa nối dài ±34 m cho xe khách. `VillageDoor3D` (E mở / đóng từ hai phía, bản lề, va chạm theo cánh, tiếng `door_open` / `door_close`). `VillageSpots3D`: E theo thứ đang nhìn trong phòng (cửa, báo, tờ kiêng, giường khi đã hết ca) và đứng cạnh thúng (sau ca, chưa ra biển đêm nay); còn lại E là của quán. `VillageLighting3D`: SÁNG (trời xám, sương) → CA (ánh sáng cũ của quán, từ lúc Rin bước vào phố lần đầu: `SHIFT_X` = 18) → ĐÊM (trời trăng của biển, đèn đường / đèn hiên / cửa sổ nhà sáng) sau ca; đổi pha chớp đen ~1 s; trong phòng dùng môi trường tối của phòng (vẫn thấy trời qua cửa); đèn bật / tắt bằng ẩn hiện vì PS1 look chép material một lần. `VillageAudio3D`: ambience + nền `house` / `lane` / `waterfront` / `street` theo vùng (tạo sẵn lúc nạp: `Sfx.prebuild_beds`), tiếng bước mỗi 0,72 m theo mặt đất (`Sfx.step`: gỗ cầu tàu, cát xóm bến, đất ở hẻm / phố / phòng). **Đổi ngày = nạp lại cả cảnh sau màn đen** (giường hoặc cập bến), đơn giản và chắc hơn reset tại chỗ: mỗi sáng dựng lại điềm (`OmenPicker.start_day` trong `VillageDay3D.judge_morning`), quán trống, ca chưa mở, điềm bến / đồ rằm; `VillageDay3D.NIGHT_FLAG` = nạp ở cầu tàu lúc đêm (từ biển về: không phán, ca coi như đã xong, anh Út không ngồi lại). Phán đêm vẫn lúc tỉnh dậy: giường gọi `choose(false)` nếu chưa ra biển; cập bến `choose(true, cá)` như cũ; bị biển bắt (đêm âm) thì tỉnh thẳng vào buổi sáng. Điềm bến (`DockOmens3D`), hoa đăng rằm (`RamShore3D`) hiện từ lúc hết ca; tiếng vọng điềm khẽ (`OmenEcho3D`) chờ Rin xuống xóm bến. Autosave chỉ buổi sáng. Sửa: `DockOmens3D` cho đèn hải đăng nhấp nháy cả khi PS1 look đã đổi material. **Bỏ:** `BedroomScene3D`, `WaterfrontScene3D` (+ .tscn), `StreetEnds3D` (bảng "VỀ XÓM"), `RestaurantShift3D.walk_home`, `sailing`, `Walker3D.make_player/step`. Test: viết lại `game3d_loop_test` (biển → cầu tàu đêm → giường → sáng → cửa → hẻm → ca tự mở → phục vụ → hết ca = đêm → thúng → biển), `ghost_visit_test`, `dark_night_test`; smoke chạy `village_scene_3d.tscn`. Bot đi cùng luồng (đặt Rin dọc đường, E qua `VillageSpots3D`). **Cập nhật 03/11:** HUD quán chỉ hiện trong ca; giảm ánh sáng sớm; đạo cụ hẻm đã dùng model Hunyuan. Không có NPC đi lại trong hẻm |
| Giấy, sổ tay, phụ đề ✅ | Chữ trên giấy vừa khung, font tự nhiên; sổ tay mở phẳng; câu thoại ngắn thành phụ đề | `PaperLayout` (vùng chữ đo trên PNG) + `PaperFit` (đo bằng font thật, ngắt dòng, giảm cỡ từng bước, không cắt; hết cỡ thì nén dòng): báo in font Old Standard TT (OFL, Bold cho măng-sét + tít, Regular cho ô "Người già dặn"), thư ông Tư / nhật ký / tờ kiêng viết tay Patrick Hand nằm trên dòng kẻ của giấy, mực nâu đen hơi phai. `NotebookSpread`: sổ mở ngang hai trang (cắt từ `notebook_page.png`, nối đầu + cuối trang trên một dòng kẻ, lề đỏ bên trái mỗi trang, bìa xanh lộ viền, bóng gáy), chữ ngồi trên dòng kẻ, ngày bút chì đỏ gạch chân; bìa giữ nguyên. `SpeechStrip` thành phụ đề như `DialogueBox` (không hộp, viền chữ, tên màu phía trên), một câu một lúc: câu mới chờ câu đang mới hiện ≥ 1,6 s. `PaperFit.fit_label3d` để sau nối cho ngày trên lịch phòng ngủ. Test `paper_test` (mọi trang báo × gợi ý, mọi manh mối, tờ kiêng, sổ tay ở 640x360 / 1280x720 / 1920x1080 + đủ glyph), `speech_test` |
| Phụ đề kinh dị ✅ | Phụ đề gõ dần rồi mờ; giọng người chết | `SubtitleText` + `SubtitleTyper` (thuần): hiện từng từ ~16 chữ/s, ngừng ngắn sau , . …; giữ 1,3 s + 0,045 s/chữ (tối đa 6 s) rồi mờ 0,4 s; E / click / câu kế tiếp hiện hết câu; headless hiện ngay. `SpeechStrip.say_as(speaker, text, opts)` (opts: seconds, dead, name, key) cho mẹo phụ đề; `OnScreenText.say` giờ đi qua `SpeechStrip`. **Người chết:** `data/story/speakers.tres` (`SpeakerTable`: màu tên + danh sách `dead`: Ông Tư, drowned, ...; câu không tên bọc "..." cũng là người chết) → chữ xanh xám nhạt, run nhẹ (`TrembleEffect`, dấu đi theo chữ), gõ chậm 9 chữ/s, tên "...". (Phụ đề âm thanh đã làm rồi bỏ theo yêu cầu 03/11.) Số trong `data/story/subtitle_tuning.tres`. Test `speech_test` |
| Vy trở lại ✅ | Vy là nhân viên cố định từ mùng 9, bạn cũ của Bảo (Bảo rủ ra phụ, "có bao cơm") | `VyStaff3D` (scenes/restaurant3d, node "VyStaff"; có cả ở `VillageScene3D` vì kế thừa quán): ngày nào cũng có, không thuê, không cờ, qua reset vẫn vậy. Trước ca / ban đêm không có trên phố; ca mở thì đi bộ vào từ đầu tây phố (x -12), hết ca đi ra lại rồi biến mất. Mỗi lần **một việc**: có món chín trên bàn kê → lấy món của bàn ít kiên nhẫn nhất (`RestaurantService3D.staff_pick`, đánh dấu `order["staff"]`, Rin không lấy được: `next_ready` bỏ qua, đĩa biến khỏi bàn kê) → đem tới bàn (`staff_serve`, im lặng); không có thì lau bàn dơ gần nhất (2,5 s, `clean_table(quiet)`; Rin dọn trước thì thôi). Chậm hơn Rin: đi 1,15 m/s, bưng 0,95 (Rin 1,8 / chạy 3,2), cầm món 0,8 s, đặt 0,7 s, nghỉ 3 s giữa hai việc (số là `@export`). Rin đứng chắn đường thì đứng chờ tối đa 1,2 s; cạnh chỗ cần tới thì làm luôn tại đó. Có thân va chạm (blocker của `PersonRig3D`). **Thoại:** E khi nhìn vào cô (gần 1,8 m, rảnh tay; ở bàn kê có món thì E vẫn là nhận món) → một câu phụ đề "Vy: ..." theo ngày + số lần hỏi trong ngày (`VyTalk3D`, `data/story/vy.tres` 14 câu: bạn cũ của Bảo, mì gói hồi ở trọ, "anh Rin"); từ ngày 5 (13 tháng Bảy) câu đầu mỗi ngày là câu bất an nhẹ (`vy_late.tres`: "bữa nay sao giống bữa qua quá"...). Cô đứng lại quay về phía Rin 1,6 s khi nói. Điềm / rằm không đổi. Arc cũ (cháu ông Tám, tiểu thư → ấm, xin việc ngày 4) **không dùng** trong bản kinh dị. Test `vy_staff_test`; bot cho Vy làm cùng (in số đĩa / bàn của Vy mỗi ngày, chỉ gọi khách tới lượt 40 để ca kịp xả) |
| Dị bằng hình ảnh + jump scare ✅ | Nhân vật cử động sai, không gian đổi khi Rin không nhìn, 4 cú hù có lý do; liều tăng theo ngày | **Bộ công cụ** (`scenes/uncanny3d/`): `UncannyActor3D.attach(rig)` gắn vào mọi `PersonRig3D` (rig PSX, tự gắn lại khi đổi model): `stare_at` (đầu + cổ quay theo Rin quá vai, tới 150°: `UncannyHeadLook3D`, SkeletonModifier3D), `freeze` (giữ nguyên dáng, hết thở: `UncannyPoseHold3D`), `choppy(fps)` (cơ thể chỉ cập nhật 6–8 lần/giây), `glitch_face` (đầu thành nhiễu điểm ảnh, quad shader `uncanny_face_glitch.gdshader`, thân sạch); `UncannyMoves3D`: `wrong_walk` (trượt không bước / đi lùi chân bước tới), `dash_to` (đứng im → lao 0,3 s → khựng), `move_when_unseen`, `remove_shadow`, `ghost_body` (không va chạm); `UnseenCheck` (thuần, systems/story: frustum + lề 8° + tia che khuất); `UnseenTrick3D` (làm một việc khi mọi điểm đã khuất đủ lâu, có thể nhiều bước); `UncannyScene3D`: xoay / dời đồ khi khuất (dép quay ra biển, ghế đẩu quay cùng một hướng), đóng cửa không tiếng (`VillageDoor3D.set_open(..., silent)`), thêm / bớt một người giữa hai lần nhìn, tắt đèn 2 khung hình trong lúc người đổi dáng; `UncannyEyes3D` (mắt trong tối, tắt khi đèn gần đó bừng lên), `UncannyReflection3D` (bóng người lộn ngược chỉ có dưới nước khi cúi nhìn ở cầu tàu); `SubtitleTricks` (thuần: lặp nguyên câu, gọi nhầm "Tư", câu không ai nói) qua đường phụ đề "Bảo: ..." có sẵn; `SingleFrameFlash3D` (một khung hình thay bằng cảnh ngay sau lưng Rin, có người đứng đó) — **tắt được: Cài đặt → "Hiệu ứng nhấp nháy"** (`GameSettings` video/flash, mặc định bật). **Đạo diễn** `UncannyDirector` (thuần, tất định theo (vòng, ngày) như OmenPicker; số trong `UncannyDose` `data/story/uncanny_dose.tres`): mùng 9–10 chỉ dời đồ / đóng cửa khi khuất; 11 thêm người thừa, khách mất bóng, mắt trong tối, bóng dưới nước, đèn chớp đổi dáng; 12 thêm cử động sai (nhìn theo, đứng hình, giật cục, trượt, nhiễu mặt) trên khách và bóng đêm âm; 13–14 thêm 1 hiệu ứng nặng/đêm (hiện sát bên ~1 m sau mỗi lần ngoảnh đi, lao tới rồi khựng, khung hình chớp), luôn hạ tiếng ~1 s trước (`Sfx.duck`); đêm có điềm chỉ giữ cử động sai (lời cảnh báo), đêm thường là nghi ngờ nhưng không giống điềm; **không đổi điềm** (OmenPicker giữ nguyên). Đêm "bóng người đầu cầu tàu" từ 12: bóng nhích về phía bờ mỗi lần Rin ngoảnh đi (chắn lối ra thúng). Anh Út chỉ có dấu nhỏ ở rằm (mắt nhìn theo trong tầm tự nhiên, nụ cười giữ hơi lâu sau chén trà), không lộ mặt thật trước `RamReveal3D`. Mẹo phụ đề: một lần mỗi vòng, ngày 13 hoặc 14, trên câu của Bảo. Gắn: `UncannyVillage3D` (một dòng trong `VillageScene3D._ready`: buổi tối / đêm) + `UncannyShift3D` (trong ca), `UncannySea3D` (một dòng trong `SeaSetup3D`). **4 cú hù** (không tiếng hét: âm mới `hull_thump`, `fish_thrash`, `breath_close`, `drip`, `dead_thud` trong `SfxEnvRecipes`): (a) sai đêm bị biển bắt: mặt người chết đuối choán màn hình 0,3 s ngay trước màn đen (`WrongNightScare3D`, 3 biến thể xoay theo số lần reset; cập bến đêm có điềm thì mặt hiện trong màn đen của `NightmareWake3D`, cả lần tỉnh < 5 s); (b) mùng 13, một lần mỗi lần chơi (cờ `note_scare_tu` giữ qua reset): ở xóm bến ban đêm, tiếng im, hơi thở + nước nhỏ giọt sau lưng; quay lại là hồn ông Tư đứng sát, chỉ tay ra phía bè, rồi biến (`TuGhostScare3D`, `UncannyPointArm3D`); (c) `RamReveal3D`: Út quay lưng nhìn xác chìm, 1 s im bặt, đèn Rin bắt được hắn quay lại — đầu quay quá vai trước, thân theo sau; (d) hù giả một lần (cờ `note_scare_fake`), đêm thường ngày 2 hoặc 3 lúc đang chờ cá: tiếng im, cú đập ướt vào thúng, một con cá nhảy vào quẫy rồi trượt ra (`FakeFishScare3D`, không vào giỏ). Không bao giờ hai cú hù hai ngày liền (`UncannyDirector.scare_allowed`, cờ `uncanny_scare_day`). Test `uncanny_test` (liều theo ngày, tất định, ≤ 1 nặng/đêm, không nặng trước 13, UnseenCheck, ông Tư một lần + giữ qua reset, không hù liền ngày, tắt nhấp nháy, đầu quay 150° trên rig thật); xem từng hiệu ứng: `scenes/test/uncanny_review.tscn` (Space; `-- --shots` lưu ảnh vào build/shot/). Bot: chờ `waking` xong rồi mới phục vụ |
| Model horror Hunyuan ✅ | Review và tích hợp 25 model online miễn phí | 68.998 tam giác reduced ở `assets/models/ready/`; cá trong tay/giỏ/quán, giỏ/cần/phao, nội thất, nhà hàng xóm, rào/chuối/cột điện/miếu, lưới phơi/bậc đá; nhà Rin kín dùng epilogue, nhà chơi được giữ phòng/cửa thật. `ConceptModel3D` tô màu có nhận sáng bằng concept + texture lặp cho mặt bên/mái, metadata export qua `horror_models.gd`; cần uốn bằng shader và đầu dây bám đầu cần. Giữ PSX NPC đã có rig. Review 3 góc mỗi model + ảnh gameplay; test `horror_models_test`, bộ test/smoke ALL OK và bot kết thật BOT OK. Chi tiết/giới hạn: `docs/HORROR_MODEL_INTEGRATION.md` |
| Đồng bộ style ✅ | Mọi model cùng một tông PS1 làng chài đêm: bớt màu, không trắng sạch / không bóng, dơ, đế tối, cùng mật độ texel; quán cũ hết lệch; người chết có look riêng | Một chỗ định số: `StyleGuide` (`systems/art/style_guide.gd`, `data/art/style_guide.tres`): giữ 78% độ màu, trần bão hoà 0.5 / sáng 0.72 (HSV, sRGB), nâng đen 0.03, kéo 18% về palette "Xóm Đèn", tint theo pha (sáng / ca / đêm / biển), roughness 0.8–1, metallic chỉ khi ≥ 0.6, vết dơ 2 lớp + lốm đốm + tối chân tường 0.4 m, 64 texel/m (texture sắc hơn bị gộp texel), bảng `recolor` cho đồ quán cũ. `StylePass3D` (scenes/world3d): `SceneRouter` móc `node_added`, mỗi MeshInstance3D được chấm một lần (deferred) trước `PsxLook3D` (nó gọi `apply_mesh` trước khi chép); StandardMaterial3D đục + có sáng → `psx_vertex` (đã tách `psx_style.gdshaderinc`, thêm bản 2 mặt, triplanar, grade), dùng chung theo "look" (`StyleMaterials`); `ConceptModel3D` giữ shader, chỉ chỉnh `tint` (cân kênh về xám + trần sáng). Bỏ qua: đèn / vật phát sáng, trong suốt, unshaded, meta `style_skip` (vũng nước omen). Quán: bàn khăn nhựa ngả vàng + chân gỉ, ghế đỏ / xanh phai, xe đẩy kem dầu mỡ, keg nhôm xỉn, bóng dây ngả vàng + đèn yếu hơn, bảng thực đơn tối và vàng, LED tối, đĩa mẻ. Người chết: `GhostLook3D` + `ghost_look.gdshader` (da xám xanh nhạt, áo ướt tối, rìa nhoè dither kiểu PS1, rung nhẹ như nước, giọt nước rơi, không phát sáng) cho ông Tư, `drowned_m/f` (tự động trong `PsxCharacterVisual`), bóng đêm âm, hình nhân ở cầu tàu, bàn tay; `RamFx3D.ghost` trả ShaderMaterial (`set_ghost_alpha`). Xem lại: `scenes/art_pilots/style_review.tscn` (chụp mọi khu cùng camera + bảng từng material, `-- --no-style` = trước), test `style_test` |

Mỗi phase xong: chạy test + bot, cập nhật mục này, dừng chờ duyệt.

### Còn mở

- ~~Vy, nhân viên, mèo, Nhịp Sóng giữ ở mức nào sau H3.~~ Đã bỏ hết ở H4 (theo yêu cầu "bỏ NEO và vài thứ khác cho đỡ phức tạp"). **Vy đã trở lại** (dòng "Vy trở lại" trong bảng phase): nhân viên cố định từ mùng 9, bạn cũ của Bảo; arc cũ (cháu ông Tám, tiểu thư chảnh → ấm, xin việc ngày 4) không dùng trong bản kinh dị.
- [x] **Đồng bộ style mọi model** (xong, xem "Đồng bộ style ✅") (yêu cầu 03/11: quán đang lệch tông): kiểm tra và sửa để mọi model (Hunyuan + `ConceptModel3D`, model quán cũ, PSX NPC, đồ khối tạm) cùng một theme / tông màu / style PS1 làng chài 1990 đêm tháng Bảy. Cách làm: chụp cùng góc, cùng ánh sáng cho từng khu (phòng, bến, hẻm, quán) + bảng so màu trung bình / độ bão hoà / độ sáng mỗi model; định một bảng tông chung (palette "Xóm Đèn", texture cùng độ phân giải / cùng mức pixel, không model nào bóng hay quá sạch); chỉnh bằng material chung (tint, desaturate, độ dơ, mức texel) thay vì sửa từng ảnh; ưu tiên các model quán (đồ cũ từ bản sáng sủa) cho khớp xóm. Có ảnh trước / sau.
- [ ] **Hoàn thiện thế giới + mép thế giới** (duyệt 03/11, làm sau khi có danh sách khảo sát chỗ bị cắt): (1) mép xóm chắn bằng vật thật (nhà, rào tre, bụi chuối, cổng khoá, ghe úp, đường ngập) thay tường vô hình, phía sau hàng dừa / mái nhà xa trong sương, không bao giờ thấy khoảng trống; (2) đi ra khỏi xóm theo đường ở hai đầu phố / cuối hẻm vào sương thì **vòng lại** vào xóm (kiểu Exit 8, không chữ giải thích); cố lần 2-3 thêm chi tiết dị (vàng mã bay ngược, bóng trong sương); (3) biển: ra quá xa thì sương dày, đèn tối, dòng nước đẩy về, cố nữa thì thúng tự quay mũi về hải đăng; (4) lưới an toàn: rơi dưới y < -5 → đen 0,5 s, đặt lại chỗ đứng an toàn cuối; có test.
- [ ] **Mọi nhân vật đều có vai trò** (đề xuất 03/11, làm sau đợt "dị bằng hình ảnh"): mỗi người gắn một loại manh mối / điềm + 1 câu E mỗi ngày bằng phụ đề, không ai giải thích luật. Bảo = tin trong quán (Út trả tiền ướt); Vy = nghe lỏm khách kể; Cô Năm = buôn chuyện, tell thứ hai cho điềm khó; anh Út = khách quen ngồi một bàn mỗi ca, vắng đêm âm (bàn trống = điềm), rằm mời trà; ông Tư = bàn thờ trong phòng, bóng đầu cầu tàu, ba tiếng gõ; ông Tám = ngồi bến buổi sáng nói kiêng, sau reset nhắc đúng loại điềm vừa bỏ lỡ; chú Hai = người đi hẻm, tell cho tiếng gọi tên, ngày cuối "đi biển không về"; người gác đèn = hồn ở hải đăng (đèn đổi màu, nhật ký mùng 13); khách không bóng ngồi chỗ anh Út đêm âm.
- [ ] **Đổi nốt đồ 3D còn là khối tạm (Box/Cylinder/Sphere) sang model thật** (concept → Hunyuan → `ConceptModel3D`, như 25 model đã gắn). Trước hết: món Rin bưng (đĩa / tô / tháp bia trên tay, `person_rig_3d.gd`), đồ trên bàn quán và quầy (`restaurant_room_builder_3d.gd`, `restaurant_fish_3d.gd`, dây đèn `restaurant_string_lights_3d.gd`), đồ điềm báo (`omen_props_3d.gd`: mâm cúng...), đá ngầm / bè / đồ trên biển (`sea_world_builder_3d.gd`, `submerged_rock_3d.gd`), bóng người đêm âm (`dark_night_figure_3d.gd`, nếu không dùng gói PSX). Không đổi: sương, bọt nước, dấu chân ướt, khối va chạm vô hình. Cách làm: lập danh sách đầy đủ bằng `grep -rlE 'BoxMesh|CylinderMesh|SphereMesh' scenes`, viết brief concept cho Codex, dựng local (`docs/LOCAL_HUNYUAN_TONIGHT.md`), rồi gắn.
