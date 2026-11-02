# Rin: tài liệu nghiên cứu thiết kế kinh dị (02/11)

Viết cho bản kinh dị (PLAN.md §10). Mỗi bài học có ghi nguồn. Ký hiệu nguồn:
- **[mở]**: đã mở và đọc trang.
- **[tìm]**: chỉ thấy qua đoạn trích / tóm tắt của kết quả tìm kiếm, chưa đọc trọn bài.

Mình không trích câu nào ngoài các câu có trong những nguồn đó. Câu tiếng Anh giữ nguyên trong ngoặc kép.

---

## 1. Thiết kế dị thường / vòng lặp (Exit 8, Platform 8, Who's At The Door, Observation Duty)

**1.1 Một lựa chọn nhị phân, luật nằm trên tường.** Exit 8 bỏ ý tưởng chụp ảnh hay bắn dị thường (không hợp bối cảnh, tốn công) để chỉ còn "proceed or turn back". Luật nằm trên tấm biển ngay chỗ bắt đầu, sai một lần là về Exit 0, cần 8 lần đúng liên tiếp.
*Áp dụng cho Rin:* Giữ đúng hai lựa chọn ở `WaterfrontScene3D`: cửa nhà hoặc thúng. Đặt luật thành **vật trong thế giới**: tờ "Những điều kiêng tháng cô hồn" dán cạnh lịch bloc trong `BedroomScene3D` (ví dụ: "Thấy điều lạ thì đừng ra khơi"). Nhờ vậy không cần tutorial mà vẫn công bằng.
Nguồn: [Wikipedia: The Exit 8](https://en.wikipedia.org/wiki/The_Exit_8) [mở]; [Automaton: Exit 8 làm trong 9 tháng](https://automaton-media.com/en/news/20240214-27192) [mở]

**1.2 Dải độ khó: từ rất khẽ tới rất rõ, và bỏ những cái "ác".** Dị thường của Exit 8 trải từ đổi chữ trên biển, poster lặp, tỉ lệ người đi đường, tới mất điện. Ở Platform 8, Kotake bỏ một dị thường vì "too difficult", và thêm biển "Don't get off" sau khi phát hành vì thấy một dị thường "a little mean-spirited". Ông coi việc streamer kẹt cả giờ ở dị thường "894" là "a good thing": trong khảo sát của ông, 22% người chơi phải tra đáp án.
*Áp dụng cho Rin:* Gắn mỗi `OmenData` một trường `subtlety` (1 rõ, 2 vừa, 3 khẽ). Cho `OmenPicker` chọn điềm rõ ở mùng 10–11, điềm khẽ ở 13–14. Điềm nào chỉ thấy được khi đứng đúng một chỗ (ví dụ hải đăng xanh nhìn từ trong quán) thì phải có thêm một manh mối thứ hai (tiếng gọi, Cô Năm nhắc) để không thành "ác".
Nguồn: [Automaton: phỏng vấn Kotake về Platform 8](https://automaton-media.com/en/interviews/interview-the-exit-8-developer-kotake-create-on-the-perks-of-being-a-solo-dev-and-how-platform-8-came-to-be/) (đọc qua bản wp-json) [mở]; [Wikipedia](https://en.wikipedia.org/wiki/The_Exit_8) [mở]

**1.3 Tỉ lệ đêm lặng / đêm có điềm quyết định giọng game.** Platform 8 đảo tỉ lệ của Exit 8 ("what would happen if I reversed that ratio") cho nhiều dị thường dẫn tới thua hơn, và người chơi thấy nó đáng sợ hơn Kotake định. Người đánh giá Exit 8 nói chính những vòng yên lại gây hoang tưởng ("impossible to not grow paranoid"), có người thấy nó "oddly relaxing".
*Áp dụng cho Rin:* 50% hiện tại là hợp lý. Đừng tăng `chance` chỉ để "đáng sợ hơn". Nỗi sợ nằm ở **đêm lặng** khi người chơi phải tin là không có gì. Phong tục thật đứng cạnh (mâm cúng đúng, hoa đăng đúng: `custom = true`) là đúng hướng. Thêm 1–2 "phong tục đúng" mỗi đêm lặng, để đêm lặng cũng rợn.
Nguồn: [Automaton: Platform 8](https://automaton-media.com/en/interviews/interview-the-exit-8-developer-kotake-create-on-the-perks-of-being-a-solo-dev-and-how-platform-8-came-to-be/) [mở]; [Wikipedia: phần đón nhận](https://en.wikipedia.org/wiki/The_Exit_8) [mở]

**1.4 Thua phải nhanh, rõ, không trừng phạt thêm.** Exit 8 không có cái chết. Cảnh đáng sợ nhất (người tường) chỉ kết bằng màn tối dần. Lời phàn nàn chính của báo chí là phải chơi lại từ đầu sau khi bỏ sót một dị thường khẽ.
*Áp dụng cho Rin:* `NightmareWake3D` nên ngắn (≤ 5 s tới lúc điều khiển được lại). Sau một lần reset, cho báo sáng mùng 9 (hoặc trang sổ tay) gợi ý **loại** điềm vừa bỏ sót, không nói tên, ví dụ "Hôm qua... có gì đó ở cầu tàu?". Một reset dạy được một điều thì mới công bằng.
Nguồn: [Wikipedia](https://en.wikipedia.org/wiki/The_Exit_8) [mở]

**1.5 Bối cảnh quen thuộc và "nửa kinh dị".** Kotake muốn dị thường ở mức "borderline horror" và "unsettling" (lấy cảm hứng từ P.T., The Shining). Một dị thường lấy ý từ dàn đèn trần ở một ga có thật. Who's At The Door (SKONEC) được giới thiệu là nhấn vào căng thẳng tâm lý khẽ thay vì hình ảnh ghê rợn: mỗi lần gõ cửa, chọn mở cửa hay uống thuốc, 8 ngày, khoảng 1 giờ chơi.
*Áp dụng cho Rin:* Điềm nên là **phong tục lệch một chi tiết** (mâm cúng thiếu đúng một chén cháo, nhang cắm ngược) chứ không phải ma hiện. "Tiếng gọi Rin ơi" có thể theo cấu trúc Who's At The Door: một tiếng gõ ở cửa phòng ngủ buổi sáng, nghe giọng để quyết định.
Nguồn: [Automaton: Exit 8](https://automaton-media.com/en/news/20240214-27192) [mở]; Who's At The Door: [bản tin Asiae](https://view.asiae.co.kr/en/article/2025062508552458136) và [Deku Deals](https://www.dekudeals.com/items/whos-at-the-door) [tìm] (chưa tìm được phỏng vấn thiết kế; chi tiết luật chưa xác minh)

**1.6 Gốc thể loại: Observation Duty.** Exit 8 lấy cơ chế dị thường từ I'm on Observation Duty. Bản số 6 của dòng game này làm đơn giản cách báo cáo dị thường để người chơi khỏi phải nhớ tên từng loại.
*Áp dụng cho Rin:* Đừng bắt người chơi gọi tên điềm. Chỉ cần chọn đầu phố. Sổ tay thì nên tự ghi "điềm đã gặp" sau mỗi lần đoán đúng hoặc sai, để người chơi tự xây danh sách.
Nguồn: [Wikipedia](https://en.wikipedia.org/wiki/The_Exit_8) [mở]; Observation Duty 6: [gamerjournalist](https://gamerjournalist.com/all-anomalies-in-im-on-observation-duty-6/) [tìm] (chưa có phỏng vấn Notovia)

---

## 2. Nhịp kinh dị và nỗi sợ khi gần như không có chiến đấu (Dredge, Amnesia/SOMA, PS1)

**2.1 Để đầu người chơi làm phần lớn việc.** Thomas Grip nói chìa khoá là "To let the mind do most of the work". Mở đầu "starts so slow and generally uneventful" khiến người chơi "noticing every little sound and finally starting to imagine things". Không bao giờ chắc mình an toàn ("can never be sure") là điều cốt lõi.
*Áp dụng cho Rin:* Ở `DarkNight3D`, trong 20–30 s đầu đừng cho gì xảy ra ngoài âm thanh. Hạ tần suất gõ mạn / thì thầm ở đêm âm, và cho 1–2 tiếng "giả" (cá quẫy, mái chèo chạm thúng) cả ở **đêm lặng**, để người chơi không bao giờ chắc.
Nguồn: [Game Developer: Road to the IGF, Thomas Grip](https://www.gamedeveloper.com/game-platforms/road-to-the-igf-thomas-grip-of-frictional-games-talks-i-amnesia-i-) [mở]

**2.2 Dựng không khí rồi đẩy nhẹ, không nói hay chiếu quá nhiều.** Grip, khi nói về Amnesia: Rebirth: "build a mood and environment that makes the player's imagination run wild", rồi đẩy người chơi "without saying or showing too much"; nỗi ám ảnh nên "brew over a much longer period".
*Áp dụng cho Rin:* Vòng 7 ngày chính là "thời gian dài" đó. Tăng nỗi sợ theo **ngày** chứ không theo từng đêm: mùng 9–10 chỉ có tiếng; 11–12 có bóng xa; 13–14 mới có `DarkNightFigure3D` lại gần. Đặt một biến `dread_level` theo ngày trong `LoopCalendar` cho `DarkNight3D` / `HorrorBed` đọc.
Nguồn: [Game Informer: phỏng vấn Frictional về Rebirth](https://gameinformer.com/exclusive-interview/2020/04/09/why-frictional-games-returned-to-the-world-of-amnesia-with-rebirth) [mở]

**2.3 Quái lộ mặt thì mất sức.** Đội Dredge nói người chơi tưởng tượng ra những thứ lạ hơn đội có thể làm, nên quái hay yếu đi sau khi lộ. Họ giới thiệu mối nguy lớn từ từ: "the longer we could keep things unknown or unpredictable, the better". Grip cũng chê Alien: Isolation vì cho người chơi nhìn quái ở cự ly 1 m (nguồn thứ cấp).
*Áp dụng cho Rin:* Hồn ma (và anh Út) chỉ nên lộ trọn **một lần**: ở `RamReveal3D`. Mọi lần khác, `DarkNightFigure3D` biến khi nhìn thẳng là đúng. Thêm luật: bóng không bao giờ ở gần hơn ~15 m trước ngày 13.
Nguồn: [Game Developer: Dredge, leveraging the unseen](https://www.gamedeveloper.com/production/leveraging-the-unseen-to-turn-players-worst-fears-against-them-in-dredge) [mở]; [DSOGaming: Frictional về Alien: Isolation](https://www.dsogaming.com/news/frictional-games-dev-on-alien-isolation-horror-game-suffers-from-two-major-horror-design-issues) [tìm]

**2.4 Ngày an toàn giả để kéo người chơi ở lại lâu hơn.** Dredge dựa trên tương phản ("open versus closed"). Ban ngày hiếm khi nguy hiểm, tạo cảm giác an toàn giả mà đội dùng để giữ người chơi ngoài khơi lâu hơn dự định. Vòng lặp cốt lõi là "... Go Out > Get Fish > ... > Get Caught At Night".
*Áp dụng cho Rin:* Quán là "ban ngày": giữ quán ấm (đèn vàng, tiếng xe, Bảo đùa) để biển đêm lạnh hơn. Ở đêm lặng, đặt cá đẹp nhất ở xa hơn tầm đèn một chút: muốn câu đủ 3 con nhanh thì phải đi xa bến.
Nguồn: [Game Developer: Dredge](https://www.gamedeveloper.com/production/leveraging-the-unseen-to-turn-players-worst-fears-against-them-in-dredge) [mở]; [Game Developer: Trawling in the deep](https://www.gamedeveloper.com/design/trawling-in-the-deep-how-black-salt-games-made-spooky-fishing-rpg-i-dredge-i-) [mở]

**2.5 Sương / tầm nhìn quanh người chơi.** Dredge viết shader sương riêng, tâm đặt ở người chơi chứ không ở camera. Với quái nằm dưới mặt nước, họ dùng một thanh trượt làm méo hình để quái tĩnh trông như đang trồi lên.
*Áp dụng cho Rin:* Ở `DarkNightLook`, cho sương đặc hơn theo khoảng cách tới **thúng**. Thay vì tạo mô hình động cho "tay dưới nước", làm méo / gợn nước lên vùng đó (shader nhiễu UV đơn giản), rẻ hơn mà rợn hơn.
Nguồn: [Game Developer: Dredge](https://www.gamedeveloper.com/production/leveraging-the-unseen-to-turn-players-worst-fears-against-them-in-dredge) [mở]

**2.6 PS1 low-poly: mờ là để tưởng tượng.** Các bài viết về Puppet Combo / Murder House cho rằng mô hình mờ, ít chi tiết để trí tưởng tượng lấp chỗ trống. Có nhà phê bình thấy lối này đã thành lặp lại.
*Áp dụng cho Rin:* Bật PSX look (F8) mặc định cho cảnh đêm. Hạ độ phân giải texture của mô hình ma (người chết đuối, tay) thấp hơn các vật thường, để chúng luôn "khó nhìn rõ".
Nguồn: [Bloody Disgusting: phỏng vấn Puppet Combo](https://bloody-disgusting.com/interviews/3639670/interview-love-slashers-vhs-survival-horror-fuels-work-developer-puppet-combo/) [tìm]; [Kotaku: Murder House](https://kotaku.com/murder-house-is-everything-terrifying-about-low-poly-ho-1847950021) [tìm] (bài chặn 403; đây là lập luận của người viết, không phải dev)

---

## 3. Âm thanh kinh dị với âm tổng hợp / hạn chế

**3.1 Âm thanh quan trọng hơn hình.** Frictional nói âm thanh quan trọng hơn hình ảnh trong việc dựng không khí đáng sợ. Amnesia dùng nhiều foley và những "đoạn âm kể chuyện" (nghe lại quá khứ của lâu đài mà không có hình).
*Áp dụng cho Rin:* Một manh mối có thể là **chỉ có tiếng**: ở `NightErrand3D`, khi E vớt chai thư, phát 2 s tiếng radio rè đọc tên tàu. Tổng hợp bằng `SfxSynth` (nhiễu lọc dải + tiếng bíp), không cần giọng thật.
Nguồn: [GameGrin: phỏng vấn Frictional](https://www.gamegrin.com/articles/interview-with-frictional-games/) [tìm]; Splice về Amnesia [tìm] (trang chặn 403)

**3.2 Gần im lặng mạnh hơn im lặng tuyệt đối, và tiếng động giữa yên mới đáng sợ.** Các bài phân tích cho rằng gần im lặng (tiếng phòng, gió) gây sợ tốt hơn im bặt kỹ thuật số; im bặt nên dùng một lần. Tương phản giữa gần im và một tiếng đột ngột làm cú hù có tác dụng.
*Áp dụng cho Rin:* Thêm vào `HorrorBed` một trạng thái `duck(seconds)`: hạ băng nhiễu / radio xuống gần 0 trong 1–2 s **trước** gõ mạn (`knock3`). Im bặt hoàn toàn chỉ dùng **một lần cả game**: lúc anh Út nhìn thẳng Rin ở `RamReveal3D`.
Nguồn: [bugnet: The case for silence in game audio](https://bugnet.io/blog/the-case-for-silence-in-game-audio) [tìm]; [IRPR Sound: horror](https://sounddesign.irpr.agency/styles/horror/) [tìm] (bài blog, không phải dev nổi tiếng)

**3.3 Khi người chơi không bao giờ thoải mái được, mọi tiếng đều thành tín hiệu.** Byron Bullock (Alien: Isolation) nói vì con alien không theo kịch bản nên "the player can never get comfortable", và mọi tiếng trong ống thông gió hay mỗi tiếng bíp của máy dò đều làm người chơi căng thẳng. Máy dò còn bíp nhanh hơn khi con alien lại gần.
*Áp dụng cho Rin:* Tiếng **phao** (bobber) có thể làm "máy dò" của Rin. Ở đêm âm, phao thỉnh thoảng giật một nhịp **không có cá** ("!" không hiện) theo nhịp gõ mạn. Ở `DarkNight3D`, cho tốc độ nhiễu radio của `HorrorBed` tăng theo khoảng cách tới `DarkNightFigure3D` gần nhất.
Nguồn: [The Sound Architect: Alien: Isolation](https://www.thesoundarchitect.co.uk/alienisolation/) [tìm] (chứng chỉ trang hết hạn, chỉ có đoạn trích)

**3.4 Tiếng có hướng là cách chỉ đường.** Một luận văn về âm thích ứng trong game kinh dị cho rằng âm không gian, ambience thích ứng và im lặng có chủ đích đều giúp tạo hồi hộp.
*Áp dụng cho Rin:* Tiếng gọi "Rin ơi" và gõ mạn nên là `AudioStreamPlayer3D` đặt ở **hướng bến / hướng bè**, không phải 2D. Người chơi nghe ra hướng là đã có một manh mối (ghi sổ tay: "tiếng gọi từ phía bè").
Nguồn: [HBO kennisbank: luận văn Saxion](https://hbo-kennisbank.nl/details/saxion_scripties:f71ead1d-712c-4b24-b625-d168d4ece85d) [tìm]

---

## 4. Cảm giác câu cá góc nhìn thứ nhất (Dredge, Webfishing, Cast n Chill)

**4.1 Ba pha, mỗi pha một cảm xúc.** Davide Aversa chia mọi minigame câu cá thành Approach-Lure → Bite → Catch, ứng với ba trục: thư giãn, bất ngờ, hưng phấn. Cho thấy cá trong pha chờ thì tự nhiên hơn nhưng giảm bất ngờ.
*Áp dụng cho Rin:* Pha chờ ở biển đêm là chỗ **đặt nỗi sợ**: người chơi đứng yên, nhìn phao, nghe nước. Đừng cho thấy cá dưới nước. Cú "!" là khoảnh khắc bất ngờ duy nhất, nên phải có tiếng (tõm + rung camera nhẹ), không chỉ là chữ.
Nguồn: [Game Developer: Taxonomy of fishing mini-games](https://www.gamedeveloper.com/game-platforms/taxonomy-of-fishing-mini-games) [mở]

**4.2 Câu cá không được gây ức chế.** Joel Mason (Dredge): "fishing should not be frustrating", "we never wanted to make it too hard or twitchy", minigame "have no failure state"; nếu không làm gì thì "it'll still complete itself", làm hỏng chỉ làm chậm lại.
*Áp dụng cho Rin:* Vì câu cá chỉ phục vụ truyện, bỏ hẳn việc đứt dây ở đêm lặng: căng dây quá chỉ làm cá kéo lùi. Mỗi con ≤ 15 s. Đứt dây chỉ dành cho đêm âm / cá của người chết (thành một điềm).
Nguồn: [Game Developer: Trawling in the deep](https://www.gamedeveloper.com/design/trawling-in-the-deep-how-black-salt-games-made-spooky-fishing-rpg-i-dredge-i-) [mở]; [Premortem: Dredge](https://premortem.games/2023/03/30/unique-blend-of-genres-in-haunting-fishing-adventure-dredge-by-black-salt-games) [mở]

**4.3 Đo xem người chơi hiểu minigame mất bao lâu, không có tutorial.** Đội Dredge xem người test để đo thời gian hiểu minigame mà không cần hướng dẫn. Người test đầu tiên trúng mục tiêu đầu sau khoảng 0,5 giây. Người chơi vẫn xin tutorial dù đọc pop-up còn lâu hơn tự hiểu.
*Áp dụng cho Rin:* Thêm vào `tools/bot` một bài đo: lần câu đầu, đếm thời gian từ cú "!" tới lúc giữ chuột. Gợi ý trong thế giới (cần câu rung, dây kêu căng) thay cho chữ "Giữ chuột trái".
Nguồn: [Premortem: Dredge](https://premortem.games/2023/03/30/unique-blend-of-genres-in-haunting-fishing-adventure-dredge-by-black-salt-games) [mở]

**4.4 Chống nhàm khi phải câu N con: thay đổi nhỏ và tín hiệu phụ.** Cast n Chill có ba kiểu mồi (phao, kéo, jig), mắc đáy không mất mồi, và con chó sủa xuống nước khi có cá lớn bên dưới. Có người chơi Webfishing cho rằng câu cá chỉ là nền cho phần trò chuyện.
*Áp dụng cho Rin:* 3 con mỗi đêm, mỗi con nên khác nhau: con 1 bình thường; con 2 kèm một sự kiện (thùng trôi, tiếng thì thầm); con 3 là "cá lạ" nhỏ (vảy có vết dây, nuốt nhẫn). Như vậy cú câu thành chỗ **nhận manh mối**. Cá cầm tay nên có một chi tiết để nhìn (cái mắt đục, vết dây).
Nguồn: [4Gamer: Cast n Chill](https://www.4gamer.net/games/967/G096700/20260120034/) [tìm]; [Shacknews: Cast n Chill review](https://www.shacknews.com/article/144913/cast-n-chill-review-score) [tìm]; [Webfishing wiki](https://webfishing.wiki.gg/wiki/Fishing) [tìm] (chưa thấy phỏng vấn dev Webfishing hay Cast n Chill)

---

## 5. Kể chuyện qua môi trường, chữ tìm được và lời đồn

**5.1 Hình dạng màn chơi là hình dạng câu chuyện.** Bài GDC của Fullbright về Tacoma viết rằng khi kể chuyện qua môi trường là trung tâm, "the shape of the level describes the shape of the story". Gaynor: "We can make a whole game that is nothing but environmental storytelling", và cảnh báo về sáo rỗng kiểu vết máu cạnh khẩu súng.
*Áp dụng cho Rin:* Ba nơi đã kể chuyện sẵn: phòng (quá khứ), quán (hiện tại, anh Út ngồi đó), bè (sự thật). Đặt vật kể chuyện theo trục **quán → bến → bè**: bàn anh Út có tiền ướt; bến có đoạn dây neo cắt gọn; bè xa có đèn xanh. Tránh sáo rỗng: không có vết máu.
Nguồn: [GDC Vault: Tacoma talk](https://gdcvault.com/play/1025178/contactUs) [tìm]; [PC Gamer: Steve Gaynor](https://www.pcgamer.com/au/gone-home-steve-gaynor-interview) [tìm]

**5.2 Tiến triển bằng hiểu biết, không bằng đồ.** Outer Wilds hướng tới khám phá không có nhiệm vụ, tiến triển "a more diegetic and player-determined approach" trong một vòng lặp thời gian. Các nguồn thứ cấp mô tả tiến triển của nó chỉ bị giới hạn bởi hiểu biết của người chơi.
*Áp dụng cho Rin:* Sổ tay giữ qua reset là đúng. Thêm **cửa hiểu biết**: những vật chỉ tương tác được khi sổ tay có đủ manh mối. Ví dụ đã đọc "dây neo cắt gọn" thì lần sau ra bè thấy được dao trên bè; đã đọc nhật ký gác đèn thì nhận ra đèn xanh. Thế giới reset nhưng **ánh nhìn của Rin** thì không.
Nguồn: [GDC Vault: Sparking Curiosity, Kelsey Beachum](https://gdcvault.com/play/1027008/Independent-Games-Summit-Sparking-Curiosity) [mở]; [GDC: Curiosity-Driven Exploration](https://gdconf.com/article/attend-gdc-and-learn-how-outer-wilds-nailed-curiosity-driven-game-design/) [mở]

**5.3 Xác nhận theo lô để chặn đoán mò.** Obra Dinn chỉ xác nhận số phận theo nhóm 3, để người chơi phải chắc chắn chứ không đoán mò. Theo bài của Automaton (tiếng Nhật), Pope từng thử một hệ thống gợi ý rồi bỏ vì không ổn.
*Áp dụng cho Rin:* Sổ tay có thể có trang "Ai là kẻ giết người?" chỉ hiện xác nhận khi người chơi nối đúng **3 manh mối** (đêm không trăng + dây cắt + cùng bán cá ở bè). Đúng thì mở câu thoại riêng của ông Tư ở kết thật (thay ngưỡng "≥ 4 manh mối" hiện tại).
Nguồn: [Wikipedia: Return of the Obra Dinn](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) [tìm]; [Automaton JP: hệ thống gợi ý bị bỏ](https://automaton-media.com/articles/newsjp/20231019-268684/) [tìm]

**5.4 Giữ mơ hồ là một phần không khí.** Mason (Dredge): "Keeping things vague and mysterious not only adds to the atmosphere"; cả game và truyện được dựng quanh không khí.
*Áp dụng cho Rin:* Mỗi bản tin sáng chỉ **một** câu mới. Lời đồn của Cô Năm nên mâu thuẫn nhau một chút ("sương ăn người" / "thằng Út dư tiền"), để người chơi tự phân xử. Đừng bao giờ để Rin tóm tắt.
Nguồn: [Premortem: Dredge](https://premortem.games/2023/03/30/unique-blend-of-genres-in-haunting-fishing-adventure-dredge-by-black-salt-games) [mở]

**5.5 Lặp mà không nhàm: thứ đã biết đổi nghĩa.** (Suy luận từ 5.2 + 1.3, không có nguồn trực tiếp.) Báo mùng 9 giống hệt nhau mỗi vòng, nhưng người chơi đọc nó khác đi khi đã biết thêm.
*Áp dụng cho Rin:* Sau khi có manh mối n, cho một **chi tiết nhỏ khác** trong cảnh quen hiện ra (anh Út bỏ tiền ướt lên bàn, ảnh ông Tư trên bàn thờ) dù ngày đã reset. `NewsData` thêm dòng phụ theo cờ sổ tay, ví dụ "...thúng nạn nhân tìm thấy gần bè" chỉ hiện khi đã có `note_clue_3`.

---

## 6. Kinh dị dân gian Việt / Đông Á

**6.1 Biến nghi lễ đời thường thành nỗi sợ.** Red Candle lấy cúng đồ ăn cho người chết làm chất liệu chính, hỏi điều gì xảy ra nếu ma thật sự tới nhận đồ cúng.
*Áp dụng cho Rin:* Điềm "mâm cúng bị ăn dở" đi đúng hướng. Thêm biến thể theo cùng logic "ma tới thật": cháo trắng trong mâm còn ấm bốc hơi giữa đêm; vàng mã đã đốt mà tro xếp thành chữ; nhang cháy hết mà khói vẫn còn.
Nguồn: [Siliconera: Detention](https://www.siliconera.com/detention-developers-talk-bringing-taiwanese-history-chinese-mythology-horror/) [mở]

**6.2 Hồn chết oan kẹt ở nơi chết, lặp lại khổ đau.** Ma của Detention lấy từ hồn người chết oan bị trói vào nơi chết, "entering an endless loop of suffering" tới khi oán được giải. Điều này khớp hẳn với hồn kẹt dưới biển của Rin.
*Áp dụng cho Rin:* Mỗi hồn ma lặp đúng **cử chỉ lúc chết** (giơ tay khỏi nước, kéo dây neo đứt, cầm đèn gác). Người chơi nhận ra hồn nào là ai qua cử chỉ, không qua chữ. Kết thật (thả hoa đăng = "giải") khớp với logic này.
Nguồn: [Siliconera: Detention](https://www.siliconera.com/detention-developers-talk-bringing-taiwanese-history-chinese-mythology-horror/) [mở]

**6.3 Cụ thể địa phương tạo cộng hưởng.** Đội Detention muốn một game "particularly Taiwanese", chọn thời kỳ vì "a greater sense of locality", và nói bối cảnh đó làm "easier to give players emotional resonance". Devotion dựng lại nội thất căn hộ Đài Bắc thập niên 80 sau khi nghiên cứu và phỏng vấn. Người chơi nhắc tới những chi tiết như bồn tắm gạch mosaic, chuông cửa tiếng chim.
*Áp dụng cho Rin:* Đầu tư vào **5–6 vật rất Việt** ở phòng ngủ và quán, đúng thời gian: lịch bloc, quạt con cóc, đài radio cassette, mâm cúng bằng nhôm, ghế nhựa đỏ, hộp quẹt Zippo nhái. Một vật quen nhìn kỹ mới thấy lệch thì đáng sợ hơn mười con ma.
Nguồn: [New Bloom: phỏng vấn Detention](https://newbloommag.net/2017/02/22/interview-detention-game/) [mở]; [Wikipedia: Devotion](https://en.wikipedia.org/wiki/Devotion_(video_game)) [tìm]

**6.4 Người ngoài văn hoá vẫn vào được nếu không khí đủ.** Red Candle mong người chơi nước ngoài bị cuốn vào dù không quen thần thoại, rồi tự tìm hiểu.
*Áp dụng cho Rin:* Không giải thích phong tục bằng chữ. Để `HelpPanel` (nếu còn) hoặc tờ "Những điều kiêng" trong phòng (1.1) làm chỗ duy nhất có lời giải thích, viết như giấy dán của bà / mẹ.
Nguồn: [Siliconera: Detention](https://www.siliconera.com/detention-developers-talk-bringing-taiwanese-history-chinese-mythology-horror/) [mở]

*Không tìm được nguồn nào về game dùng tháng cô hồn trực tiếp (Detention không nhắc tới Ghost Month trong các bài mình mở được).*

---

## Top 10 thay đổi (nhiều tác dụng, ít công trước)

1. **Tờ "Những điều kiêng" trong phòng ngủ** (`BedroomBuilder3D`, một mặt phẳng có chữ): luật vòng lặp dạy bằng vật, như biển ở Exit 0. *(1.1, 6.4)*
2. **`HorrorBed.duck()` trước mỗi stinger** (gõ mạn, tiếng gọi): 1–2 s gần im lặng; im bặt hoàn toàn chỉ một lần ở `RamReveal3D`. *(3.2)*
3. **Âm điềm thành 3D có hướng** (tiếng gọi, gõ mạn về phía bè / bến). *(3.4)*
4. **Câu cá đêm lặng không có trạng thái thua**, mỗi con ≤ 15 s; đứt dây chỉ ở đêm âm. *(4.2)*
5. **Tiếng "giả" ở đêm lặng** (cá quẫy, chèo chạm thúng, phao giật không cá) để người chơi không bao giờ chắc. *(2.1, 3.3)*
6. **`subtlety` trong `OmenData`**, cho `OmenPicker` xếp điềm rõ trước, khẽ sau; điềm khẽ phải có tín hiệu thứ hai. *(1.2)*
7. **Gợi ý sau reset**: báo / sổ tay mùng 9 nhắc mơ hồ loại điềm vừa bỏ sót; giữ `NightmareWake3D` ≤ 5 s. *(1.4)*
8. **`dread_level` theo ngày trong `LoopCalendar`**: bóng chỉ lại gần sau ngày 13; mùng 9–10 chỉ có tiếng. *(2.2, 2.3)*
9. **Con cá thứ 3 mỗi đêm mang một chi tiết manh mối** (vết dây, nhẫn) xem được khi cầm trên tay. *(4.4)*
10. **Cửa hiểu biết trong cảnh**: vật / chi tiết mới chỉ hiện khi sổ tay có cờ `note_clue_<n>`, và dòng phụ trong `NewsData` theo cờ. *(5.2, 5.5)*

Để sau, công lớn hơn: trang sổ tay "nối 3 manh mối" kiểu Obra Dinn (5.3), hồn lặp cử chỉ lúc chết (6.2), shader méo nước cho "tay dưới nước" (2.5).

---

### Ghi chú về nguồn
- Không tìm được phỏng vấn thiết kế của SKONEC (Who's At The Door), Notovia (Observation Duty), dev Webfishing hay Cast n Chill, Giant Sparrow (Edith Finch). Các phần đó dựa trên tin báo / review và đã đánh dấu [tìm].
- Các bài Automaton về Exit 8 được đọc qua API wp-json của trang, vì trang HTML bị cắt.
- Bài "The Exit 8 dev reveals..." không có số lượng dị thường; số lượng chính xác chưa xác minh.
