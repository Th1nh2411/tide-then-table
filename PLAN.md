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
- **Arc Vy (nữ chính, nhân viên quán) — tiểu thư đi làm thêm.** Vy, sinh viên năm cuối ở thành phố, nhà khá giả
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

Người chơi trải hết MVP trong khoảng 45 phút (5 ngày; đo bằng bot chơi trọn, xem "Nén nhịp" ở dưới). Kết thúc bằng một cảnh ngắn: Rin thấy một xoáy nước phát sáng giữa vùng sương mù ngoài khơi.

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
> - **Bè tôm hùm anh Út** (rạn đá): bán hết khoang ngay ngoài biển với 50% (giá gốc × cỡ × chất lượng) để lấy chỗ.
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
> - **Hướng dẫn** (bản cũ — nay thay bằng gợi ý "lần đầu gặp" `Guide`, xem mục mới bên dưới): chữ hướng dẫn trên màn hình (gợi ý minigame câu/nấu, khoang, bếp, hộp thoại, bảng menu, "[E] Vào bếp", gợi ý dưới điện thoại) chỉ hiện **ngày 1**; ngày 1 có hướng dẫn theo bước ở biển (`TutorialHints`) và ở quán (`RestaurantTutorial`: mở quán → vào bếp → nấu → món lên kệ → bàn bẩn → buổi tối). Toàn bộ điều khiển nằm trong màn **"Hướng dẫn"** (`HelpPanel`: Biển / Quán / Điện thoại / Mẹo), mở từ menu tạm dừng (Esc) và menu chính. Đã lược: "[J] điện thoại" cạnh tiền, "[E]" trên nút bến, nhắc ở bến, thông báo khi bấm E sai chỗ.
> - **Hội thoại (khung chung)**: `Dialogue` (.tres trong data/dialogues/, kịch bản dạng chữ "Tên: lời thoại", điều kiện: từ ngày, cần cờ, nói 1 lần, bật cờ khi xong, độ ưu tiên) → `DialogueLibrary` (thuần: tách dòng, chọn đoạn, nhớ đã xem trong story_flags → được lưu) → `Talker` (gắn vào nhân vật: danh sách đoạn + câu nói vặt) → `DialogueBox` (khung dưới màn hình, chữ chạy, E/Space/click qua câu, Esc bỏ qua, tạm dừng game). Trong quán Rin đi tự do (A/D) cả lúc chưa mở / đã đóng; E cạnh người có Talker để nói chuyện. Hiện có Bảo: app báo lỗi (ngày 2), con mèo ở bến (ngày 3, bật cờ `heard_about_cat`), ánh sáng xanh (sau điềm báo) + câu nói vặt. Test: scenes/test/dialogue_test.tscn.
> - **Cutscene kiểu Stardew Valley** (`Cutscene` = Dialogue có kịch bản lệnh, data/cutscenes/; `CutsceneScript` tách lệnh; `CutscenePlayer` diễn ngay trong thế giới: tạm dừng game, ẩn HUD, camera riêng trượt/zoom tới điểm đánh dấu `CutsceneMarkers`, `CutsceneActor` đi lại + biểu cảm ! ? ... tim nốt nhạc, khung thoại có chân dung + lựa chọn, mờ dần; Esc bỏ qua nhưng vẫn giữ cờ / tên mặc định / lựa chọn đầu). Lệnh: fade_in/out, tint, camera, spawn, move_to, face, emote, speak, narrate, choice/label/goto, pause, name_pet, set_flag.
> - **Bảo tới quán**: cutscene "bao_arrival" sau khi đóng bảng tổng kết ca ngày 1 (trong quán, nhân vật phóng to 1.6x): Bảo đẩy cửa vào, gặp lại Rin, xin làm phục vụ → cờ `bao_joined`; ngày 1 không có Bảo (`Waiter.is_hired()`: có cờ hoặc từ ngày 2 — cho save cũ), hướng dẫn ngày 1 chỉ cách tự bưng / tự dọn.
> - **Mèo của quán**: cutscene "cat_arrival" sau khi kết thúc đêm 2 (rạng sáng ở bến): mèo mập ăn vụng cá (chỉ trong phim, không mất cá) → Rin vuốt ve → nhận nuôi, người chơi đặt tên (mặc định "Mỡ", cờ `pet_name`, `cat_adopted`). Từ đó mèo ngồi trước quầy (`PetCat`), nói chuyện được (có "!"), "mèo chiêu tài" khách kiên nhẫn x1.1; Bảo có thoại về mèo (ngày 3); mèo ấm bất thường (ngày 4), nhìn về đông bắc sau điềm báo; app báo "[WARN] cảm biến nhiệt: sinh vật trong quán 60°C". Chưa làm: mèo biến mất sau điềm báo, bóng rồng ở cảnh kết.
> - **Nâng cấp trong điện thoại** (tab "Nâng cấp" = app "Chợ Đồ Nghề"): chỉ bán **đồ nghề đi biển** (thuyền, cần câu, đèn), mua được ở mọi nơi (J), có hiệu lực từ chuyến sau.
> - **Sửa quán** (kiểu Dave the Diver): nút cố định "Sửa quán" khi quán không phục vụ (trước giờ mở / sau khi bán xong). Vào chế độ sửa: ẩn người và bảng; bàn ghế, trang trí, bếp, tủ lạnh có viền xanh nhấp nháy; click đồ → danh sách cấp (cấp đang có / +giá), chọn là **xem trước** ngay (số bàn, đèn lồng/tranh/hoa, bếp than → gas → bếp công nghiệp có chụp hút, tủ lạnh to dần). Thanh dưới: "Hủy" (trả về như cũ) / "Xác nhận (-Xk)" (khóa nếu thiếu tiền). Chỉ nâng lên, không hạ. Áp dụng ngay cho ca hôm nay nếu sửa trước giờ mở (`RenovationMode`).
>   Test: scenes/test/night_test.tscn.

> **Quán nâng cấp + lưu 2 lần:**
>
> - **Bàn ghế** (450k/1200k): 4 → 6 → 8 bàn, bàn đặt vào các chỗ có sẵn trên vỉa hè (`StreetRoom.setup_tables`).
> - **Đèn lồng & trang trí** (600k/1500k): khách tới nhanh hơn (khoảng cách x0.85 / x0.72), khách sang 15% / 30% (áo vàng, cà vạt, trả x1.5, kiên nhẫn x0.75); cấp 1 treo đèn lồng, cấp 2 thêm tranh + chậu hoa.
> - **Bếp** (550k/1350k): minigame nấu chạy chậm x0.85 / x0.72 (dễ hoàn hảo).
> - **Phục vụ kiểu Dave the Diver** (luật phục vụ vẫn dùng; phần bố cục/điều khiển góc ngang bên dưới đã được thay bằng quán vỉa hè ở mục kế tiếp): khách vào → ngồi đọc menu 1.5–3s → gọi món (chỉ món còn phục vụ được: phần còn lại + món trên kệ − phiếu đang chờ; hết thì gọi rau muống) → chờ (kiên nhẫn 45s, chỉ giảm lúc chờ) → ăn 4–6s → trả tiền + tip → bàn **bẩn**. **Bếp nằm ngay trong quán** (không có màn hình bếp riêng): Rin đi A/D vào khu bếp bên trái; **bảng menu đánh số** trên tường bếp (tên món + số phần còn lại; món hết vẫn giữ số, mờ đi; rau muống; khách quen viền vàng ở cuối); **bấm số hoặc click** dòng nào thì nấu món đó (không dùng E để nấu); minigame hiện thu nhỏ ở góc trên trái phía trên bếp (quán vẫn chạy, Rin đứng yên khi nấu); món lên **kệ bếp** (4 chỗ); **đứng trước đĩa** trên kệ (mũi tên xanh nhỏ chỉ đĩa, nhắc ghi bàn nào gọi) bấm E để cầm, **E ở sọt rác** vứt món đang cầm, E ở bàn đặt món. Thanh **phiếu order** ở trên cùng (viền xanh = món đã có trên kệ). **Không dùng chữ nhắc**, chỉ dấu hiệu (`ServiceMarkers`): cầm món thì bàn gọi món đó + phiếu của nó nhấp nháy viền xanh kèm mũi tên; món không ai gọi thì sọt rác viền đỏ; đứng trước đĩa thì mũi tên xanh trên đĩa và bàn của nó sáng mờ; phím "E" nhỏ hiện trên chỗ E sẽ tác động (sọt rác, bàn đúng, bàn bẩn). **Bảo** tự bưng theo thứ tự khách vào, rảnh thì dọn bàn bẩn; **E ở bàn bẩn**: Rin dọn. Đóng quán (sớm hoặc hết giờ): không nhận khách mới, khách trong quán vẫn được phục vụ và ăn xong mới về (hoặc tự bỏ về khi hết kiên nhẫn), bếp vẫn mở tới khi khách cuối rời quán; món còn trên kệ bỏ đi. (`DishShelf`, `DiningTables`, `KitchenStation`, `Waiter`, `RinWalker`, `ShelfDisplay`; test: scenes/test/restaurant_test.tscn)
> - **Quán vỉa hè nhìn từ trên xuống (3/4)** — thay hẳn quán góc ngang: ô 16px chuẩn Stardew, 40x23 ô phủ kín màn hình (cửa sổ 1920x1080, F11 toàn màn hình). Mặt tiền nhà (cửa cuốn, biển "HẢI SẢN TƯƠI SỐNG", mái hiên sọc, xe máy dựng) ở trên, **vỉa hè rộng** ở giữa (bàn 2x2 ô `StreetRoom.TABLE_SIZE`, 2 ghế nhựa phía trên: ghế khách + ghế phụ, khách ngồi quay mặt ra đường; 8 chỗ bàn xếp 2 hàng x 4 cột, 4 bàn đầu là 2 cột sát xe đẩy, mỗi cấp Bàn ghế mở thêm 1 cột bên phải (4 → 6 → 8 bàn) — sau này mở rộng tiếp sang phải), mép dưới chỉ thấy **một phần đường** (làn gần + nửa làn xa, xe máy chạy qua). Bếp lộ thiên bên trái: thùng đá (nâng cấp Tủ lạnh: thùng xốp → thùng nhựa → tủ đông), **xe đẩy có bếp trên xe** (rộng 4 ô, chỉ hàng bánh xe chặn đường, mặt bàn vẽ cao thêm 1 ô và y-sort với người: Rin đứng sau xe bị xe che chân; nâng cấp Bếp: lò than → bếp ga → bếp ga đôi; tủ kính + biển đỏ quay ra đường), **bàn kê món đặt dọc cạnh xe** (5 ô, mỗi ô 1 đĩa). Rin đi **WASD**, **Shift lướt** (dash ~3 ô, hồi 0.45s, vệt gió + bụi), **E** vào ô đang quay mặt (viền trắng + phím E nhỏ); đứng gần xe đẩy mà bấm số / click món trên **hàng món luôn hiện trên cùng** (mờ khi xa xe) thì Rin tự ra **sau bếp, quay mặt ra đường** nấu; minigame hiện nhỏ đè lên mặt đường; món nấu xong nằm trên tay Rin → tự mang ra bàn (bàn gọi món đó nhấp nháy xanh) hoặc đặt lên bàn kê (bản cũ — nay Rin chỉ nướng ở lò than, xem "Đổi vai"). Khách phần lớn **đi xe máy tới** (chạy dưới đường → đỗ sát lề, đầu xe ra đường → đi bộ vào bàn → ăn xong ra xe chạy đi), số còn lại đi bộ dọc vỉa hè. **Đổi vai (sau này):** Bảo là đầu bếp đứng sau bếp trên xe đẩy từ ngày 1 (`ChefBao`): tự nấu món hấp/xào/rau muống theo phiếu cũ nhất, có thanh tiến độ + chảo + hơi nóng, xong để lên bàn kê (đầy thì chờ), hết rau thì hô Rin sang tạp hoá; tốc độ/chất lượng theo nâng cấp Bếp (7s → 5.5s → 4s, x1.0 → x1.15). Rin là phục vụ: tự bưng, dọn bàn, **nướng** món nướng ở **lò than** `N` ngay dưới xe đẩy (minigame) và rót tháp bia; trên hàng món, món của Bảo có ô "B" cam, món của Rin có số. **Minigame rót tháp bia** (`BeerPourGame`, chạy trong `CookingOverlay`): giữ Space/chuột trái thì bia dâng + bọt dâng, giữ lâu bọt càng nhanh; nhả thì bọt xẹp (1 phần thành bia) — nhả dưới vạch chỉ là nghỉ; nhả khi mép bọt trong dải vàng là chốt: trong dải xanh + bọt mỏng = Hoàn hảo x1.1, còn lại Ổn x1.0, hết giờ mà thấp = Vơi x0.8; tràn miệng ly = mất `spill_litres` (1 lít) trong tủ và rót lại từ đầu. Bot trong `cooking_test`: rót nhịp ngắn = Hoàn hảo ~3s, rót liền = Ổn, không nhả = tràn. Bàn khách (bàn inox có giấy, tương ớt, nước mắm; bàn y-sort với người như xe đẩy; ghế chặn người đi, A* chỉ mở ghế ở đầu đường đi cho khách ngồi/rời); xe máy cỡ thật (~32px, người lái cao như nhân vật). Trang trí: dây đèn (cấp 1), + chậu cây cạnh bàn (cấp 2). **Tạp hoá Cô Năm** bên phải (tiệm mở cửa, mái hiên xanh; quầy `V` + két `G` trên vỉa hè, `MarketStall` + `MarketStock`): rau muống và bia con mèo luôn có trên menu, Rin đứng dọc trước quầy (2 hàng, quay hướng nào cũng được, `MarketStall.reach`) bấm E mở danh sách hàng — các ô quầy không tương tác, phím E hiện trên đầu cô; bia không cần nấu (`DishData.instant_serve`: bấm số ở bếp là cầm ra) (`MarketPanel`, hiện chỉ có rau; nút "Mua" hoặc phím 1-9 = 1 phần 10k, E/Esc đóng; mua trước giờ mở hoặc giữa ca, quán vẫn chạy); nấu/lấy món trừ 1 phần, hết thì báo "sang tạp hoá mua"; rau thừa bỏ cuối ngày, bia (`keeps_overnight`) để dành qua ngày — lưu trong `GameState.pantry` (save); mỗi lần mua = `market_pack` phần (bia: bình 20 lít 150k, kho tính theo lít, mỗi tháp `portion_units` 3 lít), tiền mua tính vào "Tiền chợ". Hàng nút ghim (Sửa thuyền / Chuẩn bị menu / Sửa quán) dời sang giữa mặt tiền để không che tạp hoá. **Bố cục (sắp xếp lại):** **bếp ở giữa vỉa hè** — hàng sau là thùng rác + xe đẩy (Bảo đứng sau bếp) + bàn kê món nằm ngang 5 ô; trước đó là lối đi trống rộng 2 ô; thùng đá ở góc trên bên trái bếp; bình bia (vòi rót tháp) đặt trên đầu phải xe đẩy; hàng trước là lò than 2 ô bắt đầu thẳng mép trái xe đẩy (đứng trước lò thì viền trắng bao cả lò) (Rin đứng ở lối đi quay xuống để nướng / rót). **Đổi chỗ:** bàn kê dài nằm bên trái (sát bàn khách, tủ lạnh sát tường ngay trên), thùng rác + xe đẩy (Bảo, bình bia đầu phải) sang bên phải; lò than vẫn dưới đầu trái xe đẩy. **Thông báo thành lời Rin tự nói + debug cutscene:** mọi dòng chữ thông báo (biển + quán) giờ là bong bóng thoại nhỏ trên đầu người nói (`SpeechLine`, không dừng game, tự mờ): mặc định Rin tự nói ("Sóng to quá... Thuyền thúng chỉ ra tới đây thôi. Phải nâng cấp thuyền mới đi xa hơn được.", "Phải dừng thuyền lại mới thả lưới được.", "Khoang đầy rồi!", "Có ai gọi bia đâu."...), "Bảo: ..." / "Cô Năm: ..." nằm trên đầu họ, tin của app ("[MSG]...") ghi "Rin's Catch". Debug (bản debug): F3 ở biển / quán chạy lần lượt mọi cutscene của scene đó (bỏ qua điều kiện), F4 bật/tắt Nhịp Sóng + nạp đầy lượt (`CutsceneDebug`). **Bị cắn thành cutscene cuối chuyến + tách ngày (thay điểm câu truyện):** cuối đêm câu thứ 3, Rin còn đứng trên ghe vừa cập bến thì thấy một con cá thu phát sáng lượn sát mạn ghe, ráng thả thêm một cần; nó đớp, vọt lên ngoạm tay Rin rồi lặn mất (chỉ trong truyện: không vào khoang / Dex, không mở điềm báo) → vết cắn sáng, cảnh chậm, thấy đốm sáng xa ở đông bắc → ngất; rạng sáng Bảo thấy Rin nằm bất tỉnh trong ghe, cõng về (`wave_faint`, mốc bám thuyền "@boat+x,y"). Đêm câu vẫn trọn vẹn. Lịch: ngày 1 khai trương + cảnh bia sau ca; đêm 2 nhận mèo; ngày 2 bắt đầu bán bia; đêm 3 bị cắn; ngày 3 tỉnh dậy dưới mưa → Nhịp Sóng + giờ cao điểm đầu tiên, sau ca Cô Năm kể chuyện sương (có nhánh: vệt sóng nhói, Rin giấu tay, "giống hệt con cá đêm qua"); ngày 4 Vy tới xin việc (dời từ ngày 3); đêm 4 điềm báo (vệt sóng sáng theo nhịp); từ đêm 5 vào xoáy nước. **Siêu năng chắc chắn sớm (điểm câu truyện):** từ đêm 2, gần bến (thuyền thúng tới được) có **một** điểm câu riêng của cốt truyện: bọt sáng xanh, mũi tên "???" ở mép màn hình, 1 lượt, minigame rất dễ; dù kéo được hay hụt, con cá thu phát sáng đó cũng ngoạm tay Rin rồi lặn mất → Rin ngất → chiều đó chạy dưới mưa → có Nhịp Sóng từ ngày 2. Con cá này **tách biệt** với cá thu phát sáng thật: không vào khoang, không ghi Dex, không hiện thẻ NEW, không kích hoạt điềm báo. Cá thu phát sáng thật vẫn giữ nguyên ở vùng xa (hiếm ~2%/lượt, khó, câu được thì mở điềm báo như cũ). Chưa câu điểm truyện thì đêm sau nó lại xuất hiện; tới ngày 4 vẫn né thì điềm báo ở bến làm Rin ngất (lưới an toàn). Đã có vệt sóng thì điềm báo chỉ làm vệt sáng theo nhịp quầng sáng. Giờ cao điểm ở quán từ ngày 3. **Cutscene bị cắn → ngất → tỉnh dậy dưới mưa:** câu được cá thu phát sáng lần đầu thì ngay sau thẻ NEW, nó ngoạm tay Rin (`wave_faint`, camera bám thuyền "@boat"): vết cắn sáng xanh, cảnh chậm lại, Rin thấy quầng sáng ngoài sương (chính là điềm báo) rồi ngất trên ghe; gần sáng ông Tám thấy ghe trôi, kéo về bến không lấy tiền (màn nghỉ ghi lại), đêm câu kết thúc luôn. Chưa bị cắn tới ngày 4 thì ở bến quầng sáng chạm tay Rin, Rin ngất cạnh thùng cá, Bảo ra tìm thấy (`fog_omen`). Chiều đó tới quán (`wave_awaken`): màn đen "Ba giờ chiều?! Trễ mở quán rồi!", trời đổ mưa, Rin quên dù chạy dọc phố, vệt sóng trên tay sáng lên, mưa chậm dần rồi **đứng yên giữa không trung** (giọt thành hạt nước lơ lửng, xanh màn hình, tắt tiếng mưa, tim đập), Rin chạm giọt nước, nhận ra; mưa đổ ập lại, Bảo gọi vô — Rin có năng lực từ ca đó. Cutscene có thêm lệnh `rain`, `slow`, `sfx`, `ambience`, mốc "@group" (`CutsceneEffects`), diễn viên "rin_faint". Cô Năm kể chuyện sương dời sang sau ca ngày 3 (trước đêm điềm báo). **Nhịp Sóng — siêu năng của Rin (người dùng chọn, đưa một phần "dị biến cơ thể" vào phạm vi):** đêm điềm báo (luôn có, muộn nhất ngày 4) để lại vệt sóng xanh trên tay Rin: nếu đã câu được cá thu phát sáng thì nó cắn tay Rin ngay lúc câu ("Á! Con cá cắn vào tay Rin..."), không thì trong cutscene điềm báo quầng sáng loé lên chạm vào tay (lệnh cutscene mới `if_flag`); app báo `[ERR] bio-signature mismatch: user`. Phím **C**: mọi thứ chậm lại ~0.35 trong vài giây thật — ngoài biển chỉ khi đang câu / kéo lưới (3 giây), ở quán cả phố chậm (khách, kiên nhẫn, Bảo, xe, minigame nướng / rót) còn Rin vẫn chạy nhanh (4 giây). Màn hình ngả xanh, sóng loang từ chỗ Rin, viền tối, âm thanh trầm + tim đập. Mỗi đêm và mỗi ca riêng: 2 lần, +1 mỗi 3 con cá dị biến (tối đa 4); dấu vệt sóng + chấm ở góc dưới trái. Có năng lực rồi thì khó hơn để đáng dùng: cá to / cá dị biến kéo khó hơn (vùng xanh x0.8), món nướng từ 80k nướng nhanh hơn + vùng hẹp hơn, quán có **giờ cao điểm** (giây 70–110 của ca, khách tới dày gấp ~2.5, báo "Giờ cao điểm!"). Thoại: Vy hỏi vết trên tay, mèo Mỡ mắt sáng theo nhịp vệt sóng, ông Tám ("cá Ông đánh dấu con rồi"). Hướng dẫn: mũi tên lần đầu chỉ vào vệt sóng góc dưới trái (biển: "C khi câu: chậm lại", quán khi đang bán: "C: cả phố chậm lại"), gợi ý lần đầu trong minigame câu, thông báo giờ cao điểm lần đầu kèm "(C: Nhịp Sóng)", bảng Hướng dẫn có mục "Nhịp Sóng". Test: scenes/test/wave_test.tscn. **Bắt được loài mới kiểu Pokémon:** minigame câu có khung hình con cá (`FishPortrait`, vẽ riêng cá / tôm / mực / ốc / cua hoặc ảnh "fish/<id>"): lúc chờ cá cắn luôn là bóng đen + "?"; dính câu thì loài đã có trong Dex hiện màu, loài mới vẫn là bóng + "?" và tên "???". Lần đầu bắt được một loài: thẻ **NEW!** (`NewCatchCard`) hiện bóng đen, từ từ lộ ra kèm chớp sáng, rồi badge NEW!, tên + cân nặng (Space/E/click đóng; bấm sớm = bỏ qua đoạn lộ; lưới nhiều loài mới thì lần lượt); con đó trong khoang có nhãn NEW tới khi đóng khoang. **Món theo cách nấu + mở khoá + nướng có hình:** cảnh bia chuyển sang ngay sau ca bán đầu tiên (khách cuối hỏi bia, Cô Năm hẹn mai lấy; bia bán từ ngày 2). Mỗi hải sản 2–3 món theo cách nấu (16 món): **luộc/nấu** (Bảo) + **nướng** (Rin) có từ đầu, **hấp** cần Bếp cấp 1, **xào/rang** cần Bếp cấp 2; giá luộc < nướng < hấp < xào. Món chỉ mở khi đã câu được hải sản đó (`DishBook`: Dex + cấp bếp); về bến, màn nghỉ hiện thẻ **"Món mới!"** (hình + tên + giá, mỗi món báo 1 lần; nâng bếp xong sáng hôm sau cũng báo). Bảng chọn món hiện món có cá mà bếp chưa nấu được dạng mờ "cần Bếp cấp N"; phone tab Menu ẩn món chưa biết; khách quen ăn món đắt nhất bếp làm được. Món: tôm luộc 55 / tôm nướng muối ớt 65 / tôm rang muối 90 (cấp 2); mực luộc 45 / mực nướng sa tế 55 / mực hấp gừng 70 (cấp 1); ốc hương luộc sả 55 / ốc nướng mỡ hành 70; cua luộc 85 / cua hấp bia 105 (1) / cua rang me 125 (2); canh chua cá thu 65 / cá thu nướng 80 / cá thu sốt cà 100 (2); cháo cá mú 115 / cá mú hấp xì dầu 150 (1). **Minigame nướng có hình** (`GrillView`): bên trái thanh kim là vỉ than với hải sản to (cá / tôm / mực / ốc vẽ riêng): lúc mở hải sản rơi xuống vỉ, mặt dưới sém dần theo kim (viền đổi màu, khói dày khi sắp cháy), mỗi lần bấm = lật (hoạt cảnh lật + tiếng xèo), mặt vừa nướng lật lên thấy vàng / sống / cháy, có vệt vỉ; khung overlay tự nở 2 bên, giữ đáy, không che lò. Bot chơi trọn: vẫn kết ngày 4–5 (~35–46 phút), không lỗi. **Gọn quán + bản đồ lớn + dấu món nướng:** bỏ nút "Sửa thuyền" trên màn quán; nút sửa nằm trong tab "Thuyền" của điện thoại (ở quán: sửa luôn; ngoài biển: chỉ khi đang ở bến, xa bến thì nút xám "về bến để sửa"; F ở bến vẫn dùng được). Phím **M** mở bản đồ lớn (`MapOverlay`, ở biển lẫn ở quán, game dừng, M/Esc đóng, bấm để ghim): tên vùng biển, chú thích ký hiệu, khoảng cách về bến, vòng sáng chỗ thuyền. Món Rin phải tự nướng có **ngọn lửa nhỏ** trên phiếu order, bong bóng gọi món và bảng LED; còn món nướng đang chờ thì lò than viền cam nhấp nháy + ngọn lửa nhún trên lò. **Sửa trùng nhân vật trong cutscene:** ngoài biển (gặp mèo, điềm báo) Rin + mèo vẽ trên thuyền vẫn hiện cạnh Rin của cutscene ở bến → thuyền không vẽ người lúc cutscene chạy (`CutscenePlayer.started`/`playing`); ở quán nhân viên (Vy) và khách giờ cũng ẩn trong cutscene (`hidden_groups` "staff", "customers"). Đã chụp lại cả 7 cutscene có nhân vật. **Code nạp ảnh (`Art`):** có PNG trong `assets/sprites/` thì vẽ ảnh, không có thì vẽ tạm như cũ; ảnh luôn kéo vừa khung trong game nên vẽ 1x hay 2x đều được; PNG mới bỏ vào chưa import vẫn đọc được. Đã nối: nhân vật quán + cutscene (sheet 4 cột: xuống / lên / trái (phải = lật) / "bận" — khách ngồi, Bảo nấu), khách thường (nhiều dáng) / sang / quen, nhân viên (riêng từng người hoặc chung), mèo (quán, thuyền, cutscene), xe đẩy theo cấp bếp, bình bia, lò than (khung dọc), tủ lạnh theo cấp, thùng rác, bàn + bàn bẩn, ghế, bàn kê, gạch vỉa hè (biến thể), lề, đường, mặt tiền, khung bảng LED, quầy + két tạp hoá, chậu cây, đĩa món, cá trong khoang (tự xoay khi xoay cá), 3 thuyền (mặt boong xoay theo hướng lái), Rin trên thuyền. Tên file + cỡ: ASSETS.md "Tên file". Test: scenes/test/art_test.tscn; đã chụp màn hình với ảnh giả (đúng vị trí, lật, xoay). **Bot "đi tour" + màn kết bản thử + âm thanh tạm:** bot chơi trọn (`TOUR=1`) ghé mọi thứ ít nhất 1 lần trong 5 ngày: miếu (cả 2 lựa chọn), chòi ông Tám, hải đăng, bè tôm (chọn con để bán / bán hết / để về quán), chai thư, ghe chết máy (kéo về), sứa (mất bền) → sửa ở bến, cá heo, thả + kéo lưới, các thời tiết, mọi tab phone, mua đồ nghề trong phone, đăng tin tuyển + thuê, Sửa quán (xác nhận / hủy), bảng tạp hoá + cất tủ lạnh, nói chuyện Bảo / Vy / mèo, menu Esc — không lỗi script, không kẹt. Màn kết: sau "Còn tiếp..." lời Rin mờ đi, hiện thẻ ngắn (`EndingStats`: số ngày · phút chơi, số cá · loài, số bàn khách · tổng thu) + lời cảm ơn người chơi thử; thời gian chơi `GameState.play_seconds` (lưu save, không tính menu chính/màn kết). **Âm thanh tạm (người dùng đồng ý, bỏ khỏi "Ngoài phạm vi"):** không dùng file, tạo bằng code lúc mở game (`Sfx` autoload + `SfxSynth`): click mọi nút, chữ thoại, mũi tên hướng dẫn, phao nhấp / cá cắn, câu được (hoàn hảo / thường) / tuột, thả lưới, va đá, dỡ cá, xoáy nước; ở quán: đĩa, thùng rác, mua / cất đồ, xèo xèo khi nướng, tiếng rót khi giữ rót bia, tràn ly, tiền khách trả, khách bỏ đi; nền: sóng biển (biển, menu chính, màn nghỉ), tiếng phố (quán). Nút "Âm thanh: Bật/Tắt" trong menu Esc (lưu user://settings.cfg). Chưa có nhạc nền. Thoát game qua `SceneRouter.quit_game()` (tắt tiếng trước, tránh rò rỉ). Test: scenes/test/sfx_test.tscn. **Nén nhịp MVP (bot chơi trọn từ "Chơi mới" tới xoáy nước):** trước: kết ở ngày 8, ~81 phút, 2 chiến lược mua đều vậy vì chặn ở điềm báo ngày 7 (chưa lần nào câu được cá thu phát sáng 3%), ngày 5–7 chỉ chờ truyện. Sửa: điềm báo ngày 7 → **4** (sương mở ngày 5), cá thu phát sáng 3% → 6%, Ghe chèo/Ghe máy 900k/2400k → **700k/1800k**; Cô Năm kể chuyện sương ngày 5 → 4 (ngay sau đêm điềm báo, trước khi sương mở), thoại Vy về sương từ ngày 3. Sau: cả 2 chiến lược (ưu tiên thuyền / mua đều) kết ở **ngày 5, ~45 phút**, có Ghe máy ở tối ngày 3–4, mỗi ngày ~10–13 phút. Bot cũng kiểm lưu/tải ở đầu mỗi đêm + màn nghỉ (khớp). Sửa kẹt ván: thuyền hư + hết tiền → cứu hộ vá tạm 20%. **Biển cùng tỉ lệ + góc nhìn với quán:** camera thuyền zoom x2 (Rin cao 16x32 trên màn hình như ở quán, đội nón lá đứng trên thuyền), thuyền vẽ kiểu 3/4 (mặt boong xoay theo hướng lái, thành thuyền luôn lộ ra phía dưới màn hình, có bóng trên mặt nước; Rin và mèo luôn đứng thẳng). Luật chơi giữ nguyên (toạ độ, tốc độ, dầu); đèn thu nhỏ cho hợp tầm nhìn mới (bán kính 150/55 → 100/40). **Mèo luôn có mặt (khi đã nuôi):** ở quán nằm trên nóc tủ lạnh (trước bị Bảo che), ngoài biển cuộn tròn ở đuôi thuyền, mắt sáng xanh nhẹ xuyên màu đêm. **Truyện ngày 4–6 + tách file + danh sách asset:** Vy có thoại khi đang làm ở quán (E cạnh Vy, "!" khi có chuyện mới; `StaffData.dialogues`/`idle_lines`, StaffCrew gắn Talker): `vy_app` (ngày 4, app Rin's Catch và log [ERR]), `vy_fog` (ngày 3, ông nội kể dải sương sáng xanh), `vy_cat` (ngày 5, đã nuôi mèo: mắt mèo sáng xanh), `vy_omen` (sau điềm báo: dặn đem đèn dư dầu). Cutscene **Cô Năm kể chuyện sương** (lúc tới quán ngày 4: "góc trời sáng xanh", cá Ông, "thuyền chưa chắc thì đừng ra xa" → Rin nghĩ tới ghe máy) và **khách quen ở lại uống trà** (sau ca có lần đầu giao đơn cá: chuyện cá Ông giữ cửa biển, "biển cho thì lấy vừa đủ"). Tách file: restaurant_scene.gd 415 → 319 (`RestaurantEvening`, `RestaurantDebug`, `ShiftReport` có test, `ArrivalCutscenes`), street_room.gd 335 → 225 (`StreetRoomPainter`), customer_manager.gd 291 → 216 (`PartyFactory`, `PartyOrders`, `PartyCheckout`). `ASSETS.md`: danh sách asset cần vẽ (quy ước cỡ, nhân vật, quán, biển, cá trong khoang, UI, cảnh riêng, thứ tự ưu tiên). **Rau để qua ngày, héo dần như cá:** rau trong tủ lạnh/túi lưu theo lô có độ tươi (`MarketStock`: `{"units", "fresh"}`, bia vẫn là số lít), mua vào tươi 100, mỗi đêm mất độ tươi theo cấp Tủ lạnh như cá (`MarketStock.age` trong `GameState.advance_day`, hỏng thì bỏ, tính vào số "đã hỏng" lúc ra khơi); Bảo nấu lô cũ nhất trước, giá × `KitchenLogic.freshness_multiplier` (tủ cấp 0: đêm 1 vẫn giá đủ, đêm 2 x0.7, đêm 3 hỏng); bảng Cô Năm ghi "tươi N"; không còn bỏ rau lúc đóng quán; save cũ (rau là số) tự thành lô tươi 100. **Chơi thử 3 ngày đầu bằng bot (menu → intro → đêm 1 → nghỉ → khai trương → bán → tổng kết → tối → đêm 2 → mèo...):** luồng đúng kịch bản; sửa: mũi tên hướng dẫn ẩn khi đang chơi minigame (`Guide.blocked`), bảng chọn món gọn (nền đặc, tiêu đề 1 dòng, chỉ hiện món làm được, 1 dòng "Luôn có", nút Tự chọn/Xóa/Mở quán/Đóng), bảng tổng kết 3–5 dòng (sao, thu/chi/lãi, phục vụ/bỏ đi, ghi chú ngắn). **Khách không mất kiên nhẫn khi đang hướng dẫn:** lúc một mũi tên "lần đầu gặp" đang hiện ở quán (`Guide.is_showing()`), kiên nhẫn của khách đứng yên (`Customer.patience_paused`). **Gọn màn hình:** nhiệm vụ chính + phụ thành ô nổi góc trên trái (`QuestTracker`, nội dung từ `QuestLog`): bình thường mờ, chỉ 1 dòng "> bước tiếp theo" + "+N đơn đặt cá"; rê chuột vào thì rõ và mở đủ (bước chính có [x]/[ ], từng đơn cá), không chặn click. Nhiệm vụ chính theo truyện: Quán Rin & Bảo (bán ngày đầu, mua Ghe chèo, mua Ghe máy) → Ánh sáng trong sương (chờ sương mở, có Ghe máy) → Vào sương mù (vào xoáy nước sáng). Bỏ dòng đơn cá trên HUD biển và tab "Đơn" trong phone. Quản lý nhân viên + đăng tin tuyển dụng chuyển vào phone (tab "Nhân viên", hiện từ ngày 3; mỗi người 1 dòng, câu xin việc hiện khi rê chuột), bỏ nút "Nhân viên" và bảng nổi ở quán; gợi ý lần đầu "J → Nhân viên". **Hướng dẫn kiểu "lần đầu gặp" + cutscene các mốc đã chốt:** bỏ các câu hướng dẫn dài ngày 1 (`RestaurantTutorial`, `TutorialHints`); thay bằng `Guide` (vòng sáng + mũi tên nhún + 1 dòng 3–6 chữ ngay trên thứ cần làm, hiện 1 lần cho mỗi việc, lưu flag "tip_<id>", tắt khi làm đúng hoặc sau ~14s): quán (`RestaurantGuide`): bảng LED, Mở quán, cầm món, mang ra bàn, lò than, vòi bia, tạp hoá khi hết hàng, mua sỉ, tủ lạnh, dọn bàn, nút Nhân viên, Sửa quán, Ra khơi; biển (`SeaGuide`): lái, điểm câu, thả lưới, kéo lưới, Tab xem khoang, khoang đầy, bè tôm, ô Bán, dầu cạn → bến, bến. Gợi ý trong minigame rút ngắn và hiện lần đầu chơi mỗi loại (`Guide.once`). Cutscene: **khai trương** (ngày 1, Bảo + Cô Năm sang chào, chỉ bảng LED), **nhập bia** (ngày 2, khách hỏi bia, Cô Năm dặn rót từ từ), **Vy xin việc** (ngày 3, chọn "Nhận Vy làm luôn" thì thuê ngay, "Để anh tính" thì Vy nằm trong danh sách ứng viên), **điềm báo sương mù** (cuối chuyến biển sau khi có điềm báo: quầng sáng "thở" trong sương đông bắc, app báo [ERR]); thay 2 thoại `bao_beer`, `bao_vy`. Sửa rò rỉ script lúc thoát (vòng tham chiếu `TableOrder` ↔ `Customer`). **Bot đêm câu + menu theo cấp Bếp + bán chọn ở bè:** bot đi câu (điểm câu, dầu, khoang thật; tay nghề 80%): đồ ngày 1 = 12–15 con/đêm (~7 phần hải sản, ~500k tiền món), cần 1 + đèn 1 = 18–23 con, ghe chèo = 34–44 con (24 phần làm được), ghe máy = 40–62 con (32 phần) — menu 3 món chỉ bán được 10–15 phần, nên **số món trên menu theo cấp Bếp: 3 → 4 → 5** (`menu_slots_by_kitchen`; độ đa dạng 4/5 món giá x1.05/x1.1) và **bè tôm hùm anh Út cho chọn con để bán**: "Chọn con để bán" mở khoang ở chế độ bán (ô "Bỏ" thành ô "Bán" xanh ghi giá; kéo cá vào hoặc chuột phải; nút "Bán hết khoang"; game dừng trong lúc bán). **Nhân viên (người dùng chọn làm, bỏ khỏi "Ngoài phạm vi"):** từ ngày 3 có nút ghim "Nhân viên" (lúc chưa mở quán) mở `StaffPanel`: đang làm (kỹ năng, lương/ca, "Cho nghỉ" = đi luôn), ứng viên (câu xin việc, "Thuê"), đăng tin tuyển dụng 1 lần/ngày — tờ rơi 50k / hội nhóm việc làm 200k / trung tâm việc làm 500k → tối đa 2 ứng viên hạng 1/2/3 chưa gặp (`StaffCatalog`, `data/staff/*.tres`; hạng cao đi nhanh hơn, dọn nhanh hơn, có tip thêm, lương 90–420k/ca). Tối đa 2 người làm cùng lúc. **Vy** (nhân vật nữ chính, sinh viên năm cuối xóm trên) tự tới xin việc ngày 3 (`arrives_on_day`), giỏi ngang hạng 2 mà lương 200k, tip +15%; Bảo có thoại ngày 3 nhắc. Nhân viên (`StaffWorker`, `StaffCrew`) lúc quán mở: lấy đĩa cũ nhất trên bàn kê mà bàn đang chờ gọi → bưng ra (không tranh đĩa/bàn với nhau, Rin lấy trước thì bỏ), rảnh thì dọn bàn bẩn, không có việc thì về chỗ đứng cạnh bàn kê; Bảo không nấu dư khi đĩa đang trên tay nhân viên (`CustomerManager.in_hands`). Lương trừ cuối ca (dòng "Lương" trong tổng kết, tính vào lãi); tip cộng `tip_bonus`. Lưu trong `GameState.staff` (`StaffRoster`, test: scenes/test/staff_test.tscn). Bot (ngày 5): 6 bàn + Vy → phục vụ 14–18 bàn thay vì 11–12, thu 1.9 → 2.4 triệu; 8 bàn + 2 người ở bếp cấp 0 vẫn còn khách bỏ đi vì nghẽn chuyển sang bếp của Bảo (7s/món) và lượng hải sản; bếp cấp 2 + 9 phần cá + Vy & Hùng: lãi 2.0–2.6 triệu so với ~2.0 triệu khi không có nhân viên, tip gấp đôi. **Mở dần theo ngày + cân lại tiền (bot mô phỏng ca, 4 bàn, ~14 con cá/đêm = 6 phần hải sản):** khách theo giai đoạn `CustomerManager.stages` (`data/restaurant/service_day1/2/3/5.tres`, lấy giai đoạn cuối có `from_day` ≤ ngày): ngày 1 = 1 người, 1 món, không gọi thêm, khách thưa (8–14s), chưa bán bia (`DishData.unlock_day` = 2; ngày 2 Bảo có thoại "!" giới thiệu bia); ngày 2 = 20% gọi 2 món; ngày 3–4 = 10% đi 2 người, 20% gọi thêm; ngày 5+ = đầy đủ. Bot: ngày 1 Rin rảnh 62%, tối đa 3 phiếu; ngày 5 rảnh ~30%, chờ lâu nhất 45–59s; lãi/ca ~1–1.6 triệu. Giá nâng cấp x3 (tổng ~13.7 triệu, mỗi nâng cấp ~1–2 ngày lãi): thuyền 900k/2400k (nay 700k/1800k), cần 350k/1050k, đèn 450k/1200k, tủ lạnh 450k/1200k, bàn ghế 450k/1200k, trang trí 600k/1500k, bếp 550k/1350k. Lên 6 bàn chưa lời hơn (Rin là chỗ nghẽn) — sẽ gỡ bằng tính năng thuê nhân viên (dự kiến). **Tách CustomerManager:** số cân bằng khách (tần suất, nhóm, gọi món, tip, khách sang, khách quen, mèo) dời vào `ServiceTuning` (`data/restaurant/service_tuning.tres`); chọn món → `OrderPicker`, tính tiền → `TableBill` (thuần, có test trong restaurant_test), đi vào/ra → `PartyWalker`, chữ bay → `FloatingText`. **Mua sỉ ở tạp hoá:** mỗi món chợ có thêm gói sỉ rẻ hơn (`DishData.bulk_packs` / `bulk_cost` / `bulk_label`): rau 1 phần 10k hoặc 10 phần 80k, bia 1 tháp (3 lít) 25k hoặc 10 tháp (30 lít) 200k (thay bình 20 lít 150k cũ). Bảng Cô Năm mỗi dòng có 2 nút giá (nút sỉ chữ xanh), phím 1-9 mua lẻ, Shift + số mua sỉ. Rau thừa vẫn bỏ cuối ngày nên mua sỉ rau là đánh cược. **Nhóm khách + nhiều món (kiểu nhậu):** mỗi bàn 1–2 khách (`pair_chance` 0.15, hầu hết đi 1 mình; khách thứ 2 ngồi ghế phụ `o`, đi xe máy thì ngồi sau; khách quen đi 1 mình), gọi 1 món mỗi người, đôi khi thêm 1 (`extra_dish_chance` 0.35, tối đa `max_lines` 3); mỗi món là 1 dòng `TableOrder` trong `CustomerManager.waiting` (Bảo / lò / vòi bia làm theo dòng cũ nhất). Món ra tới đâu ăn tới đó (từng đĩa 4–6s), mỗi đĩa mang ra +0.3 kiên nhẫn; kiên nhẫn chỉ giảm khi còn món chờ mà trên bàn không còn gì ăn. Ăn hết mà không còn món chờ: 35% gọi thêm 1 lượt (`more_round_chance`, hay gọi bia/rau, chữ "Thêm món!"; tối đa 1 lượt, không gọi khi đã đóng quán), không thì trả tiền cả bàn 1 lần (+ tip nếu còn kiên nhẫn). Hết kiên nhẫn: bỏ các món chờ, trả tiền phần đã ăn (không tip). Phiếu order gộp theo bàn (1 chấm mỗi món chờ, vòng xanh = đĩa đã có trên bàn kê); bong bóng trên đầu khách chính cũng vậy. **Bàn ghế bên trái** (4 cột x 2 hàng, cách nhau 2 ô), nâng cấp mở bàn gần bếp trước. Tạp hoá vẫn bên phải. Màn quán không hiện giờ, tiền hay dòng kho (kho xem trong phone). Tường mặt tiền cao 5 hàng ô (bỏ bớt 1 hàng đường dưới cùng; 2 làn xe ở hàng 19/21, vạch giữa hàng 20). **Mua về phải cất tủ lạnh:** đồ mua ở tạp hoá vào túi trên tay Rin (túi nilon xanh), tủ lạnh (`F`, sát tường ngay trên bàn kê dài) nhấp nháy xanh; E ở tủ lạnh để cất (`MarketStall.bag` → `stock`), cất rồi Bảo mới nấu rau / Rin mới rót bia (chưa cất thì Bảo nhắc "cất vô tủ lạnh"); hết ca túi tự cất. Bảng tạp hoá ghi "tủ N +M túi". **Bỏ nút "Chuẩn bị menu"**: bấm chuột vào bảng hiệu LED để chọn món (trước giờ mở quán bảng có viền vàng nhấp nháy + mũi tên nhún nhảy; rê chuột vào thì viền sáng dày hơn, bảng nhích lên, con trỏ bàn tay). **Bảng LED menu nhỏ** (`MenuBoard`, ô `E` 4 ô sát lề đường ở giữa, trước bếp, cao 40px, y-sort với người; sàn dưới bếp không tô tối nữa): chữ chạy "QUÁN RIN & BẢO · HẢI SẢN TƯƠI SỐNG" (đo độ rộng thật), hình các món hải sản + số phần, hết = mờ + X đỏ; phiếu order ở mép trên bên trái. Không còn hàng ô món / phím số: **E ở lò than** = nướng món nướng của phiếu cũ nhất đang chờ, **E ở vòi bia** (`U`, bình bia cạnh thùng đá) = rót tháp cho bàn gọi bia sớm nhất; không ai gọi thì báo; phím E hiện trên lò / vòi khi có việc. **Thùng rác 1 ô** ngay bên trái xe đẩy, sát chỗ đứng nấu: E vứt món đang cầm; cầm món không ai gọi thì xô nhấp nháy đỏ (món thừa trên bàn kê bỏ đi lúc đóng quán). (`StreetRoom`, `RoomGrid`, `StreetBackdrop`, `StreetProps`, `StreetPerson`, `RinChef`, `Waiter`, `Customer`, `CustomerBikes`, `KitchenStation`, `ServiceHud`, `ServiceMarkers`) **Hội thoại kiểu Nine Sols:** hộp thoại thành chân dung lớn ở góc dưới (Rin bên trái, người khác bên phải, trượt vào khi đổi người nói, nhấp nhô + nhép miệng khi chữ đang chạy, chớp mắt) + bong bóng kem bo tròn có đuôi chỉ về người nói, thẻ tên, ▼ nhấp nháy khi hết câu; lời dẫn là hộp tối không chân dung; nền tối dần ở đáy màn hình; chữ chạy không bị chậm theo cảnh slow-mo. Chân dung tạm vẽ bằng code (Rin đội nón lá, mèo); art thật: `assets/sprites/portraits/<id>.png` (+ `<id>_<nét mặt>.png`, ghi "Rin (vui): ..." trong thoại) — `DialoguePortrait`. **Dọn trước khi chơi thử:** bong bóng thoại mỗi người một cái (Bảo nói chen không làm mất câu của Rin), câu kế của cùng người chờ câu trước hiện đủ 1 giây; Rin tự nói theo tình huống (dầu 25% / 10%, khoang 80%, khách đầu tiên bỏ về, 15% cuối ca) thay dòng cảnh báo dầu cố định; nét mặt chân dung: 24 câu thoại đã ghi "(vui)/(lo)/(ngac_nhien)/(buon)/(boi_roi)", `emote` trong cutscene tự đổi nét mặt câu kế; tách code: `ShiftCloser` + `RestaurantTools` (restaurant_scene 357 → 322 dòng), `CutsceneCamera` + `CutsceneNamePrompt` (cutscene_player 297 → 234 dòng); lưu game giữ số nguyên (lịch sử ngày, cờ truyện) sau khi nạp; bot chơi trọn game thành công cụ `tools/run_bot.sh` (đo lại: kết ở ngày 5, ~48 phút); bản chơi thử: `export_presets.cfg` (macOS universal, Windows 1 file), `tools/export.sh`, phiếu `PLAYTEST.md`. **Soát bằng ảnh chụp (cửa sổ thật):** bong bóng đặt chỗ ngay lúc nói (trước đây nói xong mà game dừng liền thì kẹt ở góc trên trái), bong bóng của Rin ngoài biển nhích lên khi đang có chỉ dẫn lần đầu trên thuyền, dầu tụt qua cả 25% lẫn 10% cùng lúc thì chỉ nói câu 10%, dòng debug biển ẩn trong cutscene. **Chỉ dẫn sửa thuyền + dỡ cá:** lần va đầu tiên mỗi chuyến Rin nói (lần đầu kèm cách sửa: về bến bấm F hoặc điện thoại), chỉ dẫn lần đầu trỏ vào ô "Thân thuyền" rồi "F: sửa thuyền" khi về bến; khoang 80% Rin nhắc "về bến dỡ bớt cá rồi ra câu tiếp" + chỉ dẫn trỏ về bến; Hướng dẫn có mục THUYỀN. **Kéo dây dễ hơn (đo bằng bot phản xạ 0.3s):** vùng xanh 0.35/0.15 → 0.4/0.2, cá chạy 0.15/0.6 → 0.13/0.5, dây mòn 0.2 → 0.15/s, được ra ngoài 0.3 → 0.45s, tuột cuộn 0.06 → 0.045, cá lao tối đa 0.85 → 0.75 tốc độ kim. Người mới: mực/cá thu ~100% (trước: cá thu 36% với người chơi khá), cá mú ~30% cần gốc → ~95% sau 1 lần nâng cần, cá thu phát sáng vẫn hiếm (~40–60% khi đã nâng). Hình con cá đang câu dựng dọc bên phải minigame. **Lưới bắt tôm/cua, cần câu đánh nhịp kiểu phím đàn:** tôm và cua chuyển sang lưới (gần bờ lưới ra chủ yếu tôm, vùng đá chủ yếu cua, ốc hương cả hai; mỗi con có cân nặng riêng, cua vùng đá to hơn), cá thu cắn câu cả ở vùng đá; chỉ dẫn "Q: thả lưới" từ đêm đầu. Minigame kéo dây và bấm nhịp bị thay bằng `RhythmGame`: mỗi cú giật là một nốt rơi xuống làn A S D F (mực 2 làn, cá thu 3 làn dồn từng tràng, cá mú 4 làn có nốt giữ, cá phát sáng đổi nhịp), bấm trúng thì "Kéo" đầy + một nốt nhạc, trượt/bấm nhầm thì "Dây" mòn; hình con cá giật theo. Đo bằng bot lệch nhịp ±75ms (người mới): mực 97%, cá thu 85%, cá mú 32% → 81–90% khi nâng cần, cá phát sáng 16% → 64–72%. Bot chơi trọn game thả 2 lưới mỗi đêm. **NEO + món nổi + thưởng sưu tầm (lấy ý từ Dave the Diver / DREDGE):** app Rin's Catch có trợ lí AI NEO (kiểu JARVIS, góc dưới trái, hologram + tiếng "ting", [WARN]/[ERR] màu đỏ) lo mọi nhắc nhở hệ thống: dầu, khoang, sửa thuyền, đơn đặt cá, khách quen tới, giờ cao điểm, sắp đóng quán; chào lần đầu ra khơi. Món nổi trong ngày: chọn lúc ra khơi trong các món Rin làm được (đã bắt nguyên liệu + bếp nấu được; đêm đầu: hải sản gần bờ), bán x1.5, khách gọi gấp 3, NEO báo ở biển + quán, vòng đỏ trên bảng LED, chữ HOT trong bảng chọn món. Thưởng sưu tầm: loài mới (giá gốc x2, 40–200k), mốc 3 loài +100k, đủ 6 loài +300k, kỷ lục cá to +50k; Dex trong app ghi mốc kế. Món bếp chưa nấu được ẩn hẳn (bảng chọn món + app), nâng bếp mới hiện. **Hướng art:** bảng màu "Xóm Đèn" = Apollo (Lospec, 46 màu) + 6 màu riêng (đỏ biển hiệu, vàng nón lá, xanh ngọc phát sáng x2, trắng đèn tuýp, xanh ghế nhựa) ở `assets/palette/` (.gpl cho Aseprite, .hex, .png); F7 (debug) xem cả game bằng bảng màu này (`PalettePreview`, shader); `tools/pixelize.py` làm sạch ảnh AI (xoá nền, đúng cỡ, ép bảng màu, bỏ viền mờ, ảnh xem trước ở build/pixelize). Cách làm vẽ tay + AI ghi ở ASSETS.md. **Bảng màu gọn lại 52 → 37:** bỏ bớt xám (10 → 8), tím (6 → 2), xanh lá (6 → 3), đỏ (6 → 3), 1 cam, xanh ghế nhựa và lõi xanh ngọc (trùng màu); thử 36 thì mặt đường quán ngả đỏ nên giữ 2 xám xanh. Giới hạn màu mỗi hình (nhân vật 10, chân dung 16, hải sản 6) + `pixelize.py --max-colors`.
> - **Lưu 2 lần**: lúc ra khơi (tiếp tục ở biển) và ở màn sáng sau chuyến câu (tiếp tục ở quán, `resume_at`). SAVE_VERSION 2.

> **Tiện ích (sau Phase 9):** Esc = menu tạm dừng (Tiếp tục / Về menu — bấm 2 lần / Thoát + bảng phím) ở biển và quán. Mũi tên mép màn hình chỉ Bến, Lưới, và xoáy nước "???" kèm khoảng cách (m). Ngày 1 có gợi ý theo ngữ cảnh. "Chơi mới" khi đã có save phải bấm 2 lần.

> **Thân thuyền (sau Phase 9):** đâm đá/đảo nhanh hơn 25px/s thì mất độ bền (0.3%/px/s, đâm chéo nhẹ hơn). Dưới 50% thuyền chậm dần (tối thiểu 60% tốc độ). 0% = hư: cứu hộ kéo về (-150k, +1 giờ game) và vá tạm miễn phí lên 20% (`BoatCondition.tow_patch`, để hết tiền vẫn ra khơi được, không kẹt ván). Sửa: thúng 2.5k/%, ghe chèo 4k/%, ghe máy 7k/%, sửa được bao nhiêu theo tiền có; sửa ở quán (nút) hoặc ở khu bến (F), không sửa khi đang ra khơi. Sáng ra thuyền còn hư thì không chạy được tới khi sửa. Độ bền được lưu.

> **Câu lâu hơn (sau Phase 9):** câu cần có 2 giai đoạn: **chờ cá cắn** (phao nhấp = cá rỉa, phao chìm hẳn = giật; giật sớm 1 lần được tha, 2 lần cá bỏ đi; không giật kịp = mất mồi) rồi mới đánh cá. TENSION có 3 giai đoạn theo thời gian vật lộn, không có thanh sức (vùng vẫy mạnh + lao bứt có báo trước → giằng co → đuối sức; cá khó: khỏe 5s, đuối từ 10s; cá dễ: 2s / 4.5s), ra ngoài vùng xanh thì thanh kéo tụt. Màn hình chỉ còn 2 thanh: Kéo, Dây. Đồng hồ đứng yên khi câu (dầu không cháy). Nút/phím **Khoang [Tab]** trong lúc câu sẽ tạm dừng game.

> **Tự thả dây vào đàn cá — kỹ năng + gamble (nhánh `feature/varied-fishing-fights`):** một lượt mở giao diện trên xuống có thuyền/Rin và 6 cá cùng bơi, không còn tính nết hay trạng thái/đòn riêng. A/D đưa thuyền và dây sang ngang, W/S nâng-hạ lưỡi; giữ lưỡi gần con muốn bắt để cá tự cắn (không có nút tự móc cá). Dây câu có quán tính, kéo trễ và đung đưa khi thuyền di chuyển; cá trong đàn có kích cỡ khác nhau, chọn con nào thì cân nặng mẻ câu đổi theo. Sau khi cá cắn: A/D bám ngang để giữ dây thẳng, W kéo lên, S nhả dây hạ căng. E là cú tất tay xanh/vàng/đỏ; cá gần mặt nước + dây thẳng + ít căng/choáng làm xanh rộng, vàng đổi tiến độ lấy Choáng, đỏ bị giật ngược. Choáng giữ giữa các lượt trong một đêm, đầy = Rin bất tỉnh và chuyến biển kết thúc bằng cứu hộ miễn phí. Câu liên tiếp cùng điểm làm đàn cảnh giác và khó hơn, đổi lại con cuối đàn lớn hơn. `FishFightGame` thay cả `BiteGame` lẫn `RhythmGame` trong luồng cần câu; lưới vẫn dùng `HaulGame`.

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
| Rau muống xào tỏi      | Luôn có trên menu; rau mua ở tạp hoá Cô Năm 10k/phần hoặc sỉ 10 phần 80k, thừa bỏ đi cuối ngày | STIR     | 30  |
| Tháp bia con mèo        | Luôn có; bia hơi mua ở tạp hoá: lẻ 1 tháp (3 lít) 25k, sỉ 10 tháp (30 lít) 200k; rót ở vòi (minigame rót tháp `BeerPourGame`), thừa để dành (lưu `GameState.pantry`) | —        | 25  |

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

- Khi đủ điều kiện (câu được cá thu phát sáng lần đầu, HOẶC tới ngày 4), đặt cờ cốt truyện. Từ ngày hôm sau, vùng `FOG` ở rìa map mở ra: sương mù (lớp phủ trắng mờ) và ở giữa có một xoáy nước phát sáng.
- Trong vùng FOG có vài điểm câu chỉ ra cá biến dị.
- Lái thuyền vào xoáy nước → màn hình sáng trắng, hiện vài dòng thoại ngắn của Rin và dòng chữ "Còn tiếp...", rồi quay về main menu.

**Xong khi:** đạt điều kiện thì vùng FOG và xoáy nước xuất hiện, cảnh kết chạy đúng.

---

## 8. Ngoài phạm vi MVP (KHÔNG làm)

Lặn biển, thế giới song song, dị biến cơ thể (trừ Nhịp Sóng đã làm), dụng cụ kết hợp hải sản, các cách bắt khác (lưới, bẫy, bắt ốc theo thủy triều), nâng cấp không gian quán, special guest, nhân vật phụ, hệ thống hội thoại, map nhiều vùng biển, thời tiết, nhạc nền + âm thanh thật (hiện chỉ có tiếng tạm tạo bằng code), art thật, cốt truyện ngoài cảnh kết Phase 9.

---

> **Art nhân vật (2026-10-15):** sprite người 16x32 theo tỉ lệ Stardew (kín khung: đầu 11 / thân 8 / chân 13, chi tiết ở ART_PLAN "Tỉ lệ người"); Rin, Bảo đã chuyển (`tools/reproportion.py`), Vy: hàng trước đổi màu từ ảnh mẫu `tools/ref/vy_spritesheet.webp` (chưa rõ giấy phép, xem ART_PLAN), hàng sau / ngang vẽ tay (`tools/make_vy_sheet.py`); đi bộ ping-pong 1-2-3-2 (`Art.WALK_CYCLE`, `tools/walk_frames.py`), đi chéo giữ hướng ổn định (`StreetPerson.facing_for`), lật sprite sang phải hết lệch (Godot 4.7 giữ rect width âm tại chỗ). Sheet quán Rin / Bảo + hàng ngang Vy làm lại bằng PixelLab (khung bước thật, `tools/pixellab_walk.py`); Rin lấy lại tóc gốc 8 dòng (`tools/rin_hair.py`, đầu 14 dòng).

## 9. Tiến độ

- **Art (2026-10-22):** runtime dùng ảnh approved **128x128** hiển thị 1:1 trong khung thoại 128. Rin có approved base/vui, Vy có approved base; Bảo vẫn là asset tạm 512 cho tới khi có approved riêng. Giữ màu và alpha của approved.
  Chi tiết và việc tiếp theo ở `ART_PLAN.md`.
- **Debug nhảy cảnh (2026-10-22):** F9 ở bất cứ đâu (bản debug) mở `DebugJumpMenu`: chọn ngày → "Đêm (biển)" / "Quán", hoặc bấm một cutscene bất kỳ. `StoryTimeline` (pure) dựng lại game như đã chơi tới lúc đó (cutscene trước đã xem + cờ của chúng, điềm báo ngày 4; không tự thuê Vy). Sau khi nhảy, autosave tắt tới khi tắt game (`SaveSystem.autosave_off`). Cutscene mới phải thêm mốc [ngày, lúc] vào `StoryTimeline.WHEN`; test: scenes/test/story_timeline_test.tscn.

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
| 9 — Cảnh kết             | ✅           | Điềm báo (cá thu phát sáng / ngày 4) → hôm sau mở FOG góc đông bắc (3 điểm cá biến dị + xoáy nước); xoáy → fade trắng → thoại Rin → "Còn tiếp..." → menu; F2 debug mở sương                                |

- **Portrait rollback — 2026-10-22:** runtime quay về ảnh approved 128×128 trong `build/portraits/128/approved/`; Rin base/vui và Vy base đã được cài lại. Bảo chưa có approved mới nên giữ asset tạm. Các sheet lớn chỉ được thu 128×128 để tham khảo trong `build/portraits/ref/`.
