Chào bạn, để xây dựng một package validation chuẩn chỉnh và bao phủ tốt cho các ứng dụng Flutter (đặc biệt khi bạn đang làm việc với các hệ thống phức tạp như dự án mạng xã hội, thương mại điện tử, tài chính/fintech, đặt vé,...), việc liệt kê và phân loại các use case là bước cực kỳ quan trọng.

Dưới đây là danh sách phân loại chi tiết và toàn diện các use case validation từ cơ bản đến nâng cao để bạn làm example và viết Unit Test cho package của mình.

---

### 1. Dữ liệu chuỗi cơ bản (String Validation)

Đây là những validation nền tảng nhất cho mọi TextField.

* **Required (Bắt buộc):** Trường không được null và không được rỗng.
* **Not Blank:** Chuỗi không được chỉ chứa toàn khoảng trắng (space, tab, newline).
* **Min Length:** Độ dài chuỗi tối thiểu (VD: Tên phải có ít nhất 2 ký tự).
* **Max Length:** Độ dài chuỗi tối đa (VD: Tiểu sử tối đa 500 ký tự).
* **Exact Length:** Độ dài chuỗi chính xác tuyệt đối (VD: Mã OTP phải đúng 6 ký tự).
* **Length Range:** Độ dài nằm trong khoảng `min` và `max` (VD: Tên đăng nhập từ 6 đến 30 ký tự).
* **Starts With / Ends With:** Bắt đầu hoặc kết thúc bằng một cụm từ cụ thể (VD: Mã sinh viên phải bắt đầu bằng "SV").
* **Contains / Not Contains:** Chứa hoặc không được chứa từ khóa (VD: Tên không được chứa từ ngữ phản cảm).
* **Blacklist / Whitelist Words:** Kiểm tra danh sách từ bị cấm hoặc chỉ cho phép các từ trong danh mục hợp lệ.
* **Latin / No Accent Only:** Chỉ cho phép ký tự không dấu (VD: Họ tên in trên thẻ ngân hàng, vé máy bay: "NGUYEN VAN A").
* **No Emoji:** Không cho phép chứa icon/emoji (thường dùng cho form hành chính, căn cước, hộ chiếu).

---

### 2. Định dạng & Biểu thức chính quy (Format & Regular Expressions)

Sử dụng Regex để kiểm tra tính hợp lệ của format dữ liệu.

* **Email:** Đúng chuẩn định dạng email quốc tế (hỗ trợ alias `+tag`, subdomains).
* **Phone Number:** Định dạng số điện thoại (hỗ trợ quốc tế có mã vùng `+84` hoặc nội địa 10 số `09xxxxxxxx`).
* **Password Strength:**
  * Ít nhất 1 chữ hoa, 1 chữ thường.
  * Ít nhất 1 chữ số.
  * Ít nhất 1 ký tự đặc biệt (`!@#$%^&*(),.?":{}|<>`).
* **URL / Website:** Định dạng link hợp lệ (`http`, `https`, domain/host hợp lệ).
* **Alphanumeric:** Chỉ chứa chữ cái và số, không chứa ký tự đặc biệt hay khoảng trắng.
* **Numeric String:** Chuỗi chỉ chứa các con số (VD: Mã số thuế, mã bưu chính).
* **Hex Color:** Mã màu hợp lệ (VD: `#FFFFFF`, `#123456`, `#FFF`).
* **UUID / GUID:** Định dạng chuỗi UUID chuẩn v4.
* **Slug Format:** Định dạng đường dẫn URL thân thiện (VD: `bai-viet-so-1`).
* **JSON Format:** Chuỗi nhập vào phải parse được thành JSON hợp lệ.

---

### 3. Dữ liệu số (Numeric Validation)

Dành cho các trường nhập liệu yêu cầu giá trị toán học (Tuổi, Số lượng, Giá tiền, Điểm số).

* **Type Casting:** Phải là một số hợp lệ (parse được sang `int` hoặc `double`).
* **Min / Max Value:** Giá trị tối thiểu và tối đa (VD: Tuổi từ 18 đến 100).
* **Value Range:** Nằm trong đoạn `[min, max]` (VD: Điểm đánh giá từ 1.0 đến 5.0).
* **Positive / Negative:** Phải là số dương (Số lượng mua hàng > 0) hoặc số âm.
* **Multiple Of (Bội số):** Phải chia hết cho một số (VD: Bước nhảy giá đấu thầu phải là bội số của 10.000đ, hoặc số lượng mua theo lốc 6 lon).
* **Decimal Precision (Độ chính xác số thập phân):** Giới hạn số chữ số sau dấu phẩy (VD: Tiền tệ VND không có số thập phân, USD tối đa 2 số thập phân, Tọa độ GPS tối đa 6 số thập phân).
* **Integer Only / Float Allowed:** Quy định chặt chẽ chỉ chấp nhận số nguyên hay cho phép số thực.

---

### 4. Ngày tháng & Thời gian (DateTime & Duration Validation)

Xử lý các picker hoặc text input liên quan đến ngày, giờ và khoảng thời gian.

* **Valid Date / Format:** Chuỗi nhập vào có thể parse thành DateTime theo định dạng mong muốn (`dd/MM/yyyy`, `yyyy-MM-dd`).
* **Past Date:** Ngày phải ở trong quá khứ (VD: Ngày sinh, ngày cấp CMND/CCCD).
* **Future Date:** Ngày phải ở trong tương lai (VD: Ngày hết hạn thẻ tín dụng, ngày hẹn khám).
* **Date Range (Min / Max Date):** Ngày nằm trong một khoảng nhất định (VD: Lịch đặt phòng chỉ trong vòng 3 tháng tới).
* **Age Verification:** Kiểm tra độ tuổi tính từ ngày sinh đến hiện tại (VD: Đủ 18 tuổi, không quá 65 tuổi).
* **Working Hours / Time Range:** Khung giờ hợp lệ trong ngày (VD: Giờ giao hàng từ 08:00 đến 20:00).
* **Exclude Weekends / Holidays:** Không được chọn ngày rơi vào Thứ 7, Chủ Nhật hoặc ngày lễ.
* **Minimum Advance Time:** Phải đặt trước một khoảng thời gian tối thiểu (VD: Đặt vé máy bay trước giờ bay ít nhất 24 tiếng).
* **Duration Range:** Khoảng cách giữa 2 mốc thời gian tối thiểu/tối đa (VD: Đặt phòng khách sạn tối thiểu 1 đêm, tối đa 30 đêm).

---

### 5. Dữ liệu Tài chính, Thanh toán & Định danh (Fintech & Identity)

* **Credit Card Number (Luhn Algorithm):** Kiểm tra tính hợp lệ của số thẻ thanh toán quốc tế và nhận diện loại thẻ (Visa, Mastercard, JCB, Amex).
* **Credit Card Expiry Date:** Định dạng `MM/YY` hoặc `MM/YYYY`, tháng từ 01-12 và chưa hết hạn so với tháng hiện tại.
* **CVV / CVC:** Đúng 3 chữ số (Visa/Mastercard) hoặc 4 chữ số (Amex).
* **Số CCCD / CMND Việt Nam:** 12 chữ số chuẩn (kiểm tra mã tỉnh, mã thế kỷ/giới tính, năm sinh) hoặc CMND cũ 9 chữ số.
* **Mã số thuế (Tax ID):** 10 chữ số (cho doanh nghiệp/cá nhân) hoặc 13 chữ số (cho chi nhánh).
* **Số tài khoản ngân hàng / IBAN:** Kiểm tra độ dài và định dạng số tài khoản hoặc mã IBAN chuẩn quốc tế.
* **Số dư khả dụng (Balance Limit):** Số tiền giao dịch/rút tiền không vượt quá số dư tài khoản hiện tại (`amount <= currentBalance`).

---

### 6. Logic Boolean, Điều khoản & Quyền riêng tư (Consent & Booleans)

* **Must be True (Accepted):** Bắt buộc phải được đánh dấu `true` (VD: Checkbox "Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật").
* **Must be False (Opt-out):** Bắt buộc phải là `false` trong một số kịch bản xác nhận từ chối.

---

### 7. Validation chéo / Phụ thuộc lẫn nhau (Cross-field / Dependent)

*Đây là nhóm quan trọng nhất để chứng minh package của bạn linh hoạt và mạnh mẽ.*

* **Match (Khớp giá trị):** Trường B phải giống hệt trường A (VD: Mật khẩu và Xác nhận mật khẩu).
* **Not Match (Không trùng lặp):** Trường B phải khác trường A (VD: Mật khẩu mới không được trùng với Mật khẩu cũ).
* **Greater Than / Less Than:**
  * Ngày kết thúc (`endDate`) phải lớn hơn hoặc bằng Ngày bắt đầu (`startDate`).
  * Giá tối đa (`maxPrice`) phải lớn hơn Giá tối thiểu (`minPrice`).
* **Required If (Bắt buộc có điều kiện):** Trường B bắt buộc nhập nếu Trường A mang một giá trị cụ thể.
  * *VD:* Nếu chọn hình thức xuất hóa đơn là "Công ty", bắt buộc phải điền trường "Mã số thuế" và "Tên công ty".
  * *VD:* Nếu checkbox "Giao hàng đến địa chỉ khác" được tick, toàn bộ form địa chỉ giao hàng trở thành bắt buộc.
* **Required Unless:** Bắt buộc nhập trừ khi một điều kiện khác đã được thỏa mãn.
* **At Least One Of (Ít nhất một trường):** Trong nhóm các trường, bắt buộc phải điền ít nhất 1 trường (VD: Để tìm kiếm tài khoản, người dùng có thể nhập Email HOẶC Số điện thoại HOẶC Tên đăng nhập).
* **Mutually Exclusive (Loại trừ lẫn nhau):** Chỉ được chọn 1 trong 2 hoặc nhiều phương thức (VD: Đã chọn phương thức giảm giá theo % thì không được nhập số tiền giảm cố định).

---

### 8. Bất đồng bộ (Asynchronous Validation)

Tương tác với Backend, Database hoặc 3rd-party API để validate.

* **Unique Check:** Kiểm tra Username, Email hoặc Số điện thoại đã tồn tại trong database hay chưa.
* **Promo Code / Coupon Check:** Kiểm tra mã giảm giá có hợp lệ, còn hạn và đủ điều kiện áp dụng cho đơn hàng không.
* **OTP Verification:** Kiểm tra mã OTP gửi về máy có đúng và còn hiệu lực không.
* **Referral Code Check:** Kiểm tra mã giới thiệu người dùng có tồn tại trong hệ thống.
* **Address / Postal Code Lookup:** Kiểm tra địa chỉ hoặc mã bưu điện có được hỗ trợ giao hàng hay không.
* *Yêu cầu kỹ thuật quan trọng:* Cần có cơ chế **Debounce** (ngừng gõ 300ms-500ms mới bắn request), quản lý cờ trạng thái `isValidating` (đang loading), và hủy bỏ kết quả cũ (Race Condition Token).

---

### 9. Mảng, Danh sách & Form Động (Collection & Dynamic Array Validation)

Dùng cho Multiple Select dropdown, Checkbox list, Tags input, hoặc dynamic list fields (thêm/bớt hàng).

* **Min / Max Items:** Số lượng phần tử tối thiểu/tối đa trong danh sách (VD: Chọn ít nhất 1 sở thích, tối đa 5 sở thích; Tải lên tối thiểu 3 ảnh sản phẩm).
* **Unique Items in List:** Không được có phần tử trùng lặp trong mảng (VD: Nhập danh sách email nhận thông báo, không được có 2 email trùng nhau).
* **List Element Validation (Mỗi phần tử phải hợp lệ):** Áp dụng luật kiểm tra cho từng item trong danh sách (VD: Mỗi tag nhập vào phải có độ dài từ 2 đến 20 ký tự; Mỗi hành khách trong danh sách vé máy bay phải có CCCD hợp lệ).
* **No Duplicate Keys in Dynamic Form:** Trong danh sách động các cặp Key-Value (như danh sách thông số kỹ thuật sản phẩm), các Key không được trùng nhau.

---

### 10. File / Hình ảnh / Đa phương tiện (File & Media Validation)

Dành cho các form upload tài liệu, avatar, file đính kèm.

* **Max File Size:** Kích thước file đơn lẻ không vượt quá giới hạn (VD: < 5MB).
* **Total Upload Size:** Tổng dung lượng của toàn bộ các file đính kèm không vượt quá giới hạn (VD: Tổng không quá 25MB).
* **Allowed Extensions:** Chỉ cho phép định dạng cụ thể (VD: `.jpg`, `.jpeg`, `.png`, `.pdf`, `.docx`).
* **Image Dimensions (Kích thước ảnh):** Chiều rộng (width), chiều cao (height) tối thiểu/tối đa (VD: Ảnh bìa phải có kích thước tối thiểu 1200x630px).
* **Aspect Ratio:** Tỷ lệ khung hình chuẩn (VD: Avatar bắt buộc tỉ lệ 1:1, ảnh banner tỉ lệ 16:9).
* **Min / Max File Count:** Số lượng file được đính kèm tối thiểu và tối đa.

---

### 11. Bảo mật & Làm sạch dữ liệu (Security & Sanitization Validation)

* **XSS / HTML Tag Injection:** Không cho phép chứa các thẻ HTML/Script nguy hiểm (`<script>`, `<iframe>`, `javascript:`).
* **SQL Injection Patterns:** Kiểm tra và chặn các từ khóa SQL injection trong các trường tìm kiếm thô.
* **Path Traversal Prevention:** Tên file tải lên không chứa ký tự nguy hiểm như `../` hoặc `..\`.

---

### Gợi ý cấu trúc cho bộ Test Cases chuẩn mực:

Để đảm bảo package của bạn đạt chất lượng sản phẩm (Production-ready) và không có bug, mỗi use case ở trên bạn nên thiết kế ít nhất **3 kịch bản kiểm thử**:

1. **Happy Path:** Nhập dữ liệu chuẩn, mong đợi trả về `true` / `null` (không có lỗi).
2. **Edge Cases:** Nhập `null`, chuỗi rỗng `""`, chuỗi chỉ có khoảng trắng `"   "`, giá trị mấp mé giới hạn (ví dụ rule min là 18 thì test đúng 3 mốc: 17, 18, 19).
3. **Error Path:** Nhập sai định dạng hoàn toàn, mong đợi trả về đúng `code` lỗi (hoặc message) đã cấu hình.