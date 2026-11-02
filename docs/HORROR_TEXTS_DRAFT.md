# Xóm Đèn — bản nháp chữ cho horror build

Ngày soạn: 2026-11-02. Nguồn: `PLAN.md` §10, `data/story/news.tres`, `data/story/clues.tres`, `data/story/ram_lines.tres` và chín resource điềm trong `data/omens/`.

Chờ duyệt; chưa đưa vào dữ liệu game. Nội dung trong cột lời là chữ đề xuất; ID, điều kiện và ghi chú là metadata biên tập, không hiển thị. Không có lời giải thích hay tự thoại của Rin.

Quy ước ngày: D1 = mùng 9, D2 = mùng 10, D3 = 11, D4 = 12, D5 = 13, D6 = 14, D7 = rằm tháng Bảy âm lịch. `calm` = đêm yên; `omen` = đêm có điềm; `after_wrong` = sáng sau một đêm chọn sai, dù lịch đã quay về mùng 9. Ngày sớm nhất của `after_wrong` tính theo ngày lịch đang hiển thị sau reset; cờ riêng ngăn phát vào buổi sáng thường. Các lựa chọn cùng một nhóm là biến thể thay nhau, không ghép thành bài dài.

## 1. Bản tin Ngủ Quên — 7 ngày × 3 trang

Mỗi trang gồm một câu tít và một câu tin. Báo của buổi sáng rằm chưa biết kết quả đêm rằm; không dùng tin tìm thấy xác trước cảnh kết thật. D1–D5 không nêu tên anh Út.

| ID | Ngày | Câu tít | Câu tin |
|---|---|---|---|
| news_d1_a | D1 — mùng 9 | Thêm một ngư dân Xóm Đèn mất tích trong sương. | Chiếc thúng dạt về bến lúc sáng, trong khoang còn đôi dép. |
| news_d1_b | D1 — mùng 9 | Ba chiếc thúng đã về bờ mà người chưa về. | Người nhà vẫn chong đèn chờ ở bến. |
| news_d1_c | D1 — mùng 9 | Xóm Đèn lại có nhà để phần cơm nguội. | Cuộc tìm kiếm ngoài biển chưa có tin mới. |
| news_d2_a | D2 — mùng 10 | Những đêm mất người đều không thấy trăng. | Người già trong xóm đối lại ngày cũ mới nhận ra. |
| news_d2_b | D2 — mùng 10 | Ba cuộc tìm kiếm cùng bắt đầu sau một đêm tối trời. | Chưa nhà nào nhớ đã thấy trăng khi người thân rời bến. |
| news_d2_c | D2 — mùng 10 | Lịch cũ hé ra một điểm giống nhau giữa các vụ mất tích. | Cả ba người đều đi vào đêm không trăng. |
| news_d3_a | D3 — 11 | Dây neo chiếc thúng mất chủ có vết cắt thẳng. | Người vá lưới nói đầu dây ấy không giống bị sóng giật đứt. |
| news_d3_b | D3 — 11 | Đầu dây neo được giữ lại để xem xét. | Các sợi bị cắt ngang cùng một chỗ, không tưa ra. |
| news_d3_c | D3 — 11 | Một nhát dao có thể đã khiến chiếc thúng trôi tự do. | Người nhà xin giữ nguyên sợi dây tìm thấy ở mũi thúng. |
| news_d4_a | D4 — 12 | Những người mất tích từng ghé cùng một bè ngoài khơi. | Họ đều đem cá tới đó bán trước chuyến cuối. |
| news_d4_b | D4 — 12 | Sổ bán cá cũ dẫn về một điểm hẹn chung. | Tên ba ngư dân nằm cạnh cùng một dấu nhận hàng. |
| news_d4_c | D4 — 12 | Đường đi cuối của ba người cùng ngang qua một bè cá. | Một người chèo đêm nhớ đã thấy thúng họ cặp ở đó. |
| news_d5_a | D5 — 13 | Trang nhật ký gác đèn nhắc tới ánh xanh ngoài bè. | Dòng cuối còn đọc được ghi rằng đó không phải sương. |
| news_d5_b | D5 — 13 | Người gác đèn mất tích từng ghi lại một chiếc ghe đi khuya. | Ghe tắt đèn khi rời bè rồi bật lại một ánh xanh. |
| news_d5_c | D5 — 13 | Vật trôi từ hải đăng mang theo một lời chưa nói hết. | Người viết đã nhìn thấy ánh xanh ở bè trước khi mất tích năm ngoái. |
| news_d6_a | D6 — 14 | Bè tôm hùm của anh Út vừa dựng thêm sàn mới. | Người trong xóm nói ổng còn mới mua một chiếc ghe. |
| news_d6_b | D6 — 14 | Anh Út mua ghe mới giữa mùa nhiều nhà mất người. | Chưa ai rõ tiền mở rộng bè từ đâu ra. |
| news_d6_c | D6 — 14 | Những chuyến bán cá cuối cùng đều ghé bè anh Út. | Nhật ký người gác đèn cũng đánh dấu vùng nước ấy. |
| news_d7_a | D7 — rằm | Xóm Đèn chuẩn bị hoa đăng cho đêm rằm tháng Bảy. | Bảy phần đèn được để riêng cho những người chưa có mồ. |
| news_d7_b | D7 — rằm | Người nhà xin tìm dưới bè tôm hùm trước khi qua rằm. | Họ mang theo đầu dây bị cắt và trang nhật ký gác đèn. |
| news_d7_c | D7 — rằm | Đèn ở bến sẽ được giữ sáng suốt đêm nay. | Xóm Đèn chờ một chuyến trở về đã trễ nhiều năm. |

## 2. Manh mối nhặt ngoài biển — 12 món

Ngày là điều kiện mở nội dung mới; ngày cụ thể ghi trên giấy có thể đã nhòe. Thư của ông Tư được viết hai năm trước, trước khi ông bị hại; nhật ký của người gác đèn được viết năm ngoái. Giấy cũ trôi về hiện tại, không phải người chết vừa viết thêm. Các vật tự cung cấp thông tin bằng chữ còn lại trên vật hoặc nhãn mô tả khi nhặt.

| ID | Ngày sớm nhất | Loại | Nguồn / vật | Nội dung đọc |
|---|---|---|---|---|
| clue_01 | D1 — mùng 9 | letter | Chai thư ông Tư, hai năm trước | Rin, nhớ chừa ngọn đèn cho ông nghe con. Có về trễ cũng đừng xuống mé nước đứng chờ. |
| clue_02 | D1 — mùng 9 | object | Chiếc dép mắc rong | Một chiếc dép cao su đã bạc màu, quai được vá bằng dây cước. Rong quấn kín chỗ vá. |
| clue_03 | D2 — mùng 10 | diary | Trang đầu nhật ký gác đèn, năm ngoái | Đêm không trăng lại có thúng trôi qua chân đèn. Tôi gọi mãi, không ai ngẩng lên. |
| clue_04 | D2 — mùng 10 | letter | Chai thư ông Tư, hai năm trước | Bữa không trăng, ông thấy có ghe đi mà che hết đèn. Ông chờ nó qua rồi mới chèo về. |
| clue_05 | D3 — 11 | object | Khúc dây neo còn nút buộc | Đầu dây phẳng, các sợi bị cắt ngang một lượt. Nút buộc ở đầu kia vẫn còn chặt. |
| clue_06 | D3 — 11 | diary | Trang nhật ký dính muối, năm ngoái | Thúng dạt vô mà dây neo bị cắt ngọt. Chỗ nước đó không có đá ngầm. |
| clue_07 | D4 — 12 | letter | Mảnh thư ông Tư gấp tư, hai năm trước | Ông đem cá ra bè, thấy người ta chuyển mấy bao hàng lúc khuya. Có chiếc thúng cặp vô rồi bị kéo tuốt vào sương. |
| clue_08 | D4 — 12 | object | Mảnh sổ nhận cá bọc trong vải dầu | Ba tên người mất tích nằm dưới cùng một dấu nhận cá ở bè. Phần tên người nhận đã mục mất. |
| clue_09 | D5 — 13 | diary | Trang nhật ký loang dầu, năm ngoái | Đèn xanh ở bè, không phải sương. Dưới sàn có thứ gì quấn lưới, cột thêm đá. |
| clue_10 | D5 — 13 | letter | Đoạn cuối thư ông Tư, hai năm trước | Người trên ghe quay lại nhìn ông rồi, con à. Nếu ông không về, đừng tin cái thúng trống nói hết được chuyện. |
| clue_11 | D6 — 14 | diary | Trang cuối nhật ký gác đèn, năm ngoái | Tôi nhận ra Út dưới đèn xanh, đang kéo một người quấn lưới xuống mép bè. Nó cũng ngước lên thấy đèn của tôi. |
| clue_12 | D6 — 14 | object | Nhãn hàng còn mắc dưới mảnh sàn bè | Nhãn ghi «Bè tôm hùm — Út»; mặt sau dính dầu máy và một sợi lưới siết chặt. Mắt lưới kẹt trong nút dây cột đá. |

## 3. Lời đồn trong xóm — 40 câu

Lời `calm` là chuyện thường và manh mối, không khuyên ở nhà trong một đêm yên. Lời `omen` chỉ phát khi đã có điềm; lời nhắc cụ thể về vệt chân chỉ dùng sau `last_calm_miss`. Hai kiểu sáng sau chọn sai tách bằng điều kiện phụ để không gán vệt chân cho nhánh chết ngoài biển.

### Cô Năm — 20 câu

| ID | Ngày sớm nhất | Trạng thái | Điều kiện phụ | Lời |
|---|---|---|---|---|
| nam_01 | D1 | calm | — | Tối con đi thì buộc quai giỏ cho chắc nghe. Hôm qua cô thấy rong mắc đầy chân cầu. |
| nam_02 | D1 | calm | — | Phần cháo ngoài cửa là cô để cúng. Con bưng món cứ đi vòng bên này nha. |
| nam_03 | D2 | calm | — | Đốt giấy xong cô dội nước vô thùng rồi. Tro nguội mới đem đổ được, con. |
| nam_04 | D3 | calm | — | Đầu dây mà tưa là một chuyện, bị cắt ngọt lại một chuyện khác. Hồi đó ông con phân biệt rành lắm. |
| nam_05 | D4 | calm | — | Mấy nhà mất người đều còn giữ sổ bán cá. Hỏi tới lần bán cuối, ai cũng chỉ ra ngoài bè. |
| nam_06 | D5 | calm | — | Cậu gác đèn mất năm ngoái hay ghé mua dầu. Bữa cuối cậu xin thêm giấy, nói phải chép lại chuyện gì đó. |
| nam_07 | D6 | calm | — | Thằng Út dạo này dư tiền dữ. Mới đóng thêm sàn bè, giờ lại có ghe mới. |
| nam_08 | D2 | omen | omen_id = mam_cung | Cái chén lật úp mà cháo không đổ xuống đất miếng nào. Con coi dấu ướt trên mép khay kìa. |
| nam_09 | D2 | omen | omen_id = xe_khong_nguoi | Cô ngồi đây từ lúc chiếc xe tới. Chỉ nghe máy tắt, hông nghe chân ai bước hết. |
| nam_10 | D2 | omen | omen_id = vang_ma | Gió tạt khói vô nhà mà giấy cứ chạy ra bến. Để cô khép cửa, con đứng lùi vô nghe. |
| nam_11 | D2 | omen | omen_id = led_chao | Bảo có nấu cháo trắng đâu con. Cái bảng đó vừa tắt rồi tự sáng lại. |
| nam_12 | D2 | omen | omen_id = goi_ten | Ai kêu con mà giọng nghe ướt vậy? Tối nay thôi ở nhà với ngọn đèn đi con. |
| nam_13 | D2 | omen | omen_id = hoa_dang | Hoa đăng người ta thả ra ngoài, sao cái này cứ tìm vô bờ? Con đừng đẩy nó ra nữa. |
| nam_14 | D2 | omen | omen_id = bong_cau_tau | Người đó đứng chắn ngay đầu cầu từ nãy. Con quay lại đi, chừa chỗ cho họ. |
| nam_15 | D1 | after_wrong | last_calm_miss | Dép con khô mà từ cửa tới giường toàn dấu nước. Đêm qua có ai đứng ngoài hông? |
| nam_16 | D1 | after_wrong | last_calm_miss | Cô nghe ba tiếng gõ bên nhà con rồi im ru. Người tới chắc có chuyện chưa nói được. |
| nam_17 | D1 | after_wrong | last_calm_miss | Cô đem khăn khô qua nè. Dấu chân nhỏ tới cửa phòng con rồi mất tiêu. |
| nam_18 | D1 | after_wrong | Chết ngoài biển đêm có điềm | Cô vừa trông con đi ra bến, quay vô đã thấy cửa nhà con đóng. Mặt con sáng nay xanh quá. |
| nam_19 | D1 | after_wrong | Chết ngoài biển đêm có điềm | Con ngồi xuống cho hết run đã. Chén nước này cô mới rót, còn ấm. |
| nam_20 | D1 | after_wrong | Chết ngoài biển đêm có điềm | Hồi sáng cô gặp con, áo còn nhỏ nước. Giờ lại thấy con từ nhà đi ra. |

### Bảo — 10 câu

| ID | Ngày sớm nhất | Trạng thái | Điều kiện phụ | Lời |
|---|---|---|---|---|
| bao_01 | D1 | calm | — | Tối kiếm ít nhất ba con nghe mày. Mai tao còn có cái mà bày ra quán. |
| bao_02 | D2 | calm | — | Giỏ tao vá lại rồi, không lọt cá nữa đâu. Lúc cập bến nhớ đếm đủ ba con. |
| bao_03 | D4 | calm | — | Mấy người mất tích hồi trước hay ngồi chung cái bàn sát mé đường. Bữa cuối họ còn hẹn ra cùng một bè. |
| bao_04 | D6 | calm | — | Anh Út trả tiền lúc nào cũng ướt, có mùi dầu máy. Tiền trong túi áo mà cứ như mới vớt dưới nước. |
| bao_05 | D2 | omen | omen_id = led_chao | Tao rút dây cái bảng rồi đó. Mày thấy nó còn sáng hông? |
| bao_06 | D2 | omen | omen_id = mam_cung | Nãy tao mới phụ cô bày mâm, chưa ai đụng vô hết. Để nguyên đó đi mày. |
| bao_07 | D2 | omen | omen_id = goi_ten | Tao đứng ngay đây, có kêu mày đâu. Cái giọng dưới bến nghe giống tao hả? |
| bao_08 | D1 | after_wrong | last_calm_miss | Giỏ trống hả mày? Tao nghe bên nhà mày gõ ba tiếng, tưởng mày gọi tao. |
| bao_09 | D1 | after_wrong | last_calm_miss | Mày về rồi mà tao vẫn nghe tiếng nước bên cửa. Tao chờ một hồi, không thấy ai đi ra. |
| bao_10 | D1 | after_wrong | Chết ngoài biển đêm có điềm | Tay mày lạnh ngắt vậy? Đứng gần bếp chút, tao dọn chỗ cho. |

### Chú Hai — 10 câu

| ID | Ngày sớm nhất | Trạng thái | Điều kiện phụ | Lời |
|---|---|---|---|---|
| hai_01 | D1 | calm | — | Đèn trên cọc còn sáng, con nhìn nó mà về. Dây neo chú đã coi giùm rồi. |
| hai_02 | D2 | calm | — | Hoa đăng trôi ra theo nước đó con. Để nó đi, đừng chèo cán ngang. |
| hai_03 | D3 | calm | — | Dây này có người đưa dao vô cắt. Sóng có mạnh cũng không để đầu ngọt như vầy. |
| hai_04 | D5 | calm | — | Đèn hải đăng vốn vàng, chú nhìn mấy chục năm rồi. Ánh xanh trong trang giấy đó nằm thấp hơn, sát mặt bè. |
| hai_05 | D2 | omen | omen_id = hai_dang | Đèn vàng đâu rồi con? Cái xanh đó sáng từ lúc tiếng máy ngoài kia tắt. |
| hai_06 | D2 | omen | omen_id = bong_cau_tau | Chú không thấy chân người đó chạm ván. Con thôi xuống thúng bữa nay nghe. |
| hai_07 | D2 | omen | omen_id = hoa_dang | Nước đang ròng mà đèn cứ vô chân cầu. Chú buộc thúng lại giùm con rồi. |
| hai_08 | D1 | after_wrong | last_calm_miss | Dấu nước vô tới giường thì người ta có tìm con đó. Chú thấy ngoài bến có ngọn đèn chờ suốt. |
| hai_09 | D1 | after_wrong | Chết ngoài biển đêm có điềm | Khuya chú thấy thúng con trôi sát cầu, không nghe tiếng chèo. Giờ con đứng đây thì chú mừng. |
| hai_10 | D1 | after_wrong | Chết ngoài biển đêm có điềm | Chú kéo dây thúng lên thì nghe ai dưới nước gọi tên con. Giọng già lắm, như ông con hồi trước. |

## 4. Câu bổ sung cho từng điềm — 9 ID × 2 câu

ID đối chiếu trực tiếp với `.tres`; `omen_catalog.tres` chỉ là catalog, không phải điềm thứ mười. Các dòng dưới đều có ngày sớm nhất D2, điều kiện `omen`, đúng `omen_id`; không phát ở D1 hoặc rằm. Đây là câu mới ngoài lời hiện có, không ghi đè `text`, `calm_text` hay `co_nam_line`.

| ID điềm | Biến thể | Người nói | Lời |
|---|---|---|---|
| mam_cung | a | Cô Năm | Ba cây nhang gãy cùng một chỗ. Ai đụng vô mà không làm rơi cái lư nào hết vậy con? |
| mam_cung | b | Bảo | Cái vệt ướt đó in đủ năm ngón tay. Tao lau cạnh khay hồi chiều còn khô rang. |
| led_chao | a | Bảo | Chữ mới chạy ngược một vòng rồi đứng lại đó. Tao đâu có cài món này. |
| led_chao | b | Cô Năm | Mấy bữa bảng sáng đỏ, nay chữ trắng bệch. Con nhìn lâu có nghe lạnh sau lưng hông? |
| xe_khong_nguoi | a | Bảo | Tao ra hỏi gửi xe mà cái yên ướt nhẹp. Dưới đất không có dấu giày nào. |
| xe_khong_nguoi | b | Cô Năm | Đèn rọi thẳng vô bàn trống hoài. Cô lấy ghế che thì nó lại chớp. |
| vang_ma | a | Chú Hai | Khói bay một đường, giấy bay một đường. Đường giấy đi là ra bến đó con. |
| vang_ma | b | Bảo | Tờ giấy vừa rớt vô thùng lại bay ngược ra. Lửa tắt rồi mà nó còn đỏ. |
| tien_le | a | Cô Năm | Tiền rớt thành hàng tới bảng ra bến kìa. Cô ngồi nãy giờ đâu thấy ai làm rơi. |
| tien_le | b | Chú Hai | Con để đồng đó nằm yên nghe. Chú vừa nhặt một đồng thì phía trước lại nghe tiếng rớt. |
| goi_ten | a | Chú Hai | Nó kêu một tiếng, nước dưới cầu đáp một tiếng. Con đừng bước theo, đứng đây với chú. |
| goi_ten | b | Cô Năm | Giọng kêu từ dưới thấp lắm con. Dưới cầu giờ nước đã ngập hết bậc rồi. |
| hoa_dang | a | Cô Năm | Cái đèn cứ chạm mũi thúng con rồi quay vô. Như có người kéo nó lại vậy. |
| hoa_dang | b | Chú Hai | Chú thả lại ba lần, nó về chân cầu cả ba. Bữa nay con cất mái chèo đi. |
| hai_dang | a | Chú Hai | Đèn quét qua mặt nước mà xanh như trong chai cũ. Chú nhìn cả đời chưa thấy màu đó. |
| hai_dang | b | Cô Năm | Cậu gác đèn mất rồi, ai vừa đổi ánh đèn vậy con? Cô thấy nó đứng một chỗ, không quét nữa. |
| bong_cau_tau | a | Chú Hai | Chú giơ đèn lên thì người đó lùi, hạ đèn xuống lại đứng chắn. Họ không cho mình xuống cầu đâu. |
| bong_cau_tau | b | Cô Năm | Áo người đó chảy nước mà trên ván không nghe một giọt. Con về nhà đi, để đèn cửa sáng nghe. |

## 5. Đêm rằm

### Người trong xóm thả hoa đăng — 6 câu

Ba câu trước kết không khẳng định đã tìm được xác; ba câu sau chỉ phát trong kết thật sau khi tìm thấy bảy nạn nhân dưới bè. Ông Tư bị hại hai năm trước, người gác đèn năm ngoái; cả hai đều là nạn nhân của anh Út, các hồn cảnh báo và đưa Rin trở lại.

| ID | Ngày / điều kiện | Người nói | Lời |
|---|---|---|---|
| ram_shore_01 | D7, trước khi ra khơi | Cô Năm | Con cầm sát cái đế nghe, giấy mỏng lắm. Để ngọn đèn còn cháy tới ngoài kia. |
| ram_shore_02 | D7, trước khi ra khơi | Chú Hai | Chú chừa bảy cái bên này. Nhà nào còn chờ người thì lại lấy một cái. |
| ram_shore_03 | D7, trước khi ra khơi | Bà Sáu | Có ai chưa về thì theo ánh này nghe. Bữa nay cả xóm đứng chờ đây. |
| ram_shore_04 | D7, chỉ kết thật | Cô Năm | Hai năm rồi ông Tư mới có chỗ nằm trên đất. Lần này cô thả đèn tiễn ổng. |
| ram_shore_05 | D7, chỉ kết thật | Chú Hai | Phần cậu gác đèn để chú thả. Năm ngoái cậu còn châm dầu giùm chú ở chỗ này. |
| ram_shore_06 | D7, chỉ kết thật | Bà Sáu | Đủ bảy ngọn rồi, đừng níu đèn lại con. Cho họ đi với nhau. |

### Anh Út tại quán — 4 câu

Đều D7, chỉ lúc gặp ở quán trước khi ra khơi; giữ giọng thân thiện và áp lực ngầm, không thú nhận sớm. Trà gừng thuộc nhánh buồn ngủ trong cốt truyện; lời không bổ sung cách pha hay loại thuốc.

| ID | Điều kiện phụ | Người nói | Lời |
|---|---|---|---|
| ram_ut_01 | Bắt đầu mời trà | Anh Út | Ông con hồi trước cũng hay ngồi chỗ này. Lại đây anh rót cho ly trà gừng. |
| ram_ut_02 | Khi đưa ly | Anh Út | Cầm hai tay cho ấm, em. Ngoài kia có nghe gõ mạn thì cứ chèo, đừng ngoái lại làm gì. |
| ram_ut_03 | Sau khi uống | Anh Út | Em xuống thúng trước đi, anh theo liền. Mệt thì cứ tựa đầu, tới bè anh gọi. |
| ram_ut_04 | Khi từ chối | Anh Út | Ừ, không uống thì thôi, anh có ép đâu. Tối em đi lối nào, nói anh biết còn chờ. |

## Ghi chú bàn giao

Tổng: 21 trang báo (42 câu), 12 manh mối, 40 lời đồn (20 Cô Năm / 10 Bảo / 10 Chú Hai), 18 câu cho 9 điềm, 6 câu hoa đăng và 4 câu anh Út. Mỗi ô lời giữ một hoặc hai câu ngắn. Tất cả địa danh và nhân vật thuộc thế giới hư cấu của game. Không thêm điện thoại, NEO, nhiệm vụ UI hay lời tự giải thích của Rin. Cờ điều kiện phụ là hướng dẫn lựa chọn cho người tích hợp, không phải trường dữ liệu đã được thêm vào game.
