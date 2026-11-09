# TÀI LIỆU THIẾT KẾ CƠ SỞ DỮ LIỆU (POSTGRESQL)

Tài liệu này giải thích chi tiết cấu trúc CSDL tham khảo từ **Quizlet**, các kỹ năng thiết kế CSDL thực chiến (Database Design Best Practices) và giải đáp thắc mắc về cơ chế đăng nhập Google.

---

## 1. Đăng nhập / Đăng ký qua Google: Có bắt buộc dùng Firebase không?

> **TRẢ LỜI: HOÀN TOÀN KHÔNG BẮT BUỘC DÙNG FIREBASE.**

Thực tế có 2 giải pháp kỹ thuật:

| Tiêu chí | Cách 1: Google OAuth2 / OpenID Connect chuẩn (KHUYÊN DÙNG) | Cách 2: Qua Firebase Authentication |
| :--- | :--- | :--- |
| **Bản chất** | Dùng Google Identity SDK lấy `id_token` $\rightarrow$ Gửi về Spring Boot verify bằng thư viện `google-api-client`. | Dùng Firebase Auth SDK trên App/Web $\rightarrow$ Lấy Firebase Token $\rightarrow$ Gửi về Spring Boot verify Firebase Admin SDK. |
| **Độ phụ thuộc** | Trực tiếp với Google, không phụ thuộc bên thứ 3 nào khác. | Phụ thuộc thêm dịch vụ Firebase của Google Cloud. |
| **Chi phí & Giới hạn**| Hoàn toàn miễn phí, không giới hạn request xác thực. | Miễn phí trong hạn mức, nếu vượt mức có thể phát sinh cấu hình phức tạp. |
| **Cơ sở dữ liệu** | Toàn bộ dữ liệu user lưu tập trung tại **PostgreSQL** của bạn. | Dễ bị phân mảnh tài khoản giữa Firebase và PostgreSQL. |
| **Độ khó đồ án** | Code rõ ràng, thể hiện sinh viên hiểu cơ chế Token-based Authentication chuẩn RESTful. | Thêm thư viện trung gian cồng kềnh cho backend. |

**Quy trình chuẩn không cần Firebase:**
1. **Frontend (React hoặc Android):** Dùng Google Sign-In SDK có sẵn của Google để hiển thị nút *"Đăng nhập với Google"*. Khi người dùng chọn tài khoản, Google trả về một chuỗi `id_token`.
2. **Gửi về Spring Boot:** Client gọi API `POST /api/auth/google` kèm `id_token`.
3. **Spring Boot:** Sử dụng thư viện `google-api-client-java` xác thực token với Google Server. Nếu hợp lệ, lấy email, tên, avatar $\rightarrow$ Tìm trong bảng `users` ở PostgreSQL:
   - Nếu chưa có: Tạo mới user (`auth_provider = 'GOOGLE'`).
   - Nếu đã có: Cập nhật thông tin.
4. **Trả về JWT nội bộ:** Spring Boot tạo JWT Token của riêng hệ thống và trả về cho Web/Android sử dụng cho các API sau.

---

## 2. Các Actor (Tác nhân) chính trong hệ thống

Tham khảo từ mô hình của Quizlet:

1. **Học sinh (STUDENT):**
   - Tạo và chỉnh sửa bộ thẻ (Flashcard Sets/Decks) của riêng mình.
   - Học thẻ theo thuật toán lặp lại ngắt quãng (FSRS).
   - Đánh dấu sao (`starred`) các thẻ khó nhớ để ôn riêng.
   - Làm bài kiểm tra trắc nghiệm 1 in 4 (được DKT theo dõi và dự báo năng lực).
   - Chơi mini-game ghép thẻ (Match Game) để đua bảng xếp hạng tốc độ.
   - Nhập mã PIN tham gia lớp học của thầy cô, nộp bài tập được giao.
   - Hỏi đáp với trợ lý AI Chatbot.

2. **Giáo viên (TEACHER):**
   - Có toàn bộ quyền của Học sinh.
   - Tạo lớp học, cấp mã tham gia (`class_code`).
   - Thêm các bộ thẻ bài giảng vào thư viện của lớp.
   - Giao bài tập (yêu cầu học sinh làm bài test hoặc đạt số điểm tối thiểu trước hạn chót).
   - Xem bảng thống kê: Theo dõi mức độ am hiểu kiến thức của từng học sinh thông qua báo cáo từ mô hình DKT.

3. **Quản trị viên (ADMIN):**
   - Quản lý tài khoản người dùng: Khóa/mở khóa tài khoản có hành vi gian lận hoặc vi phạm tiêu chuẩn cộng đồng.
   - Kiểm duyệt nội dung (`content_reports`): Xử lý các báo cáo từ học sinh/giáo viên về các bộ thẻ sai kiến thức, phản cảm hoặc vi phạm bản quyền.
   - Quản trị cấu hình hệ thống (`system_settings`): Điều chỉnh tham số thuật toán FSRS (ví dụ: mục tiêu khả năng nhớ `retention rate`), thay đổi model AI, bật/tắt tính năng.
   - Theo dõi nhật ký kiểm toán (`admin_audit_logs`): Ghi lại minh bạch mọi thao tác quản trị trên hệ thống.
   - Quản lý danh mục khái niệm kiến thức chuẩn (`knowledge_components`) phục vụ mô hình DKT.

---

## 3. Các kỹ năng thiết kế CSDL (Database Design Skills) đã áp dụng

Trong tệp [schema.sql](file:///d:/android-flashcard/docs/schema.sql), các nguyên tắc sau đã được áp dụng để tránh việc thiếu sót trường dữ liệu sau này:

1. **Chuẩn hóa 3NF kết hợp Denormalization có kiểm soát:**
   - Dữ liệu được phân tách rõ ràng thành các bảng độc lập (Cards, Decks, Users).
   - Thêm các cột đệm như `card_count` (số thẻ trong bộ) và `streak_count` (số ngày học liên tục) để trang Home load ngay tức thì mà không cần chạy câu lệnh `COUNT(*)` nặng nề.
2. **Khóa ngoại và Ràng buộc toàn vẹn (Constraints & Foreign Keys):**
   - Sử dụng `ON DELETE CASCADE` hợp lý (ví dụ: Xóa Deck thì tự động xóa hết Cards liên quan).
   - Sử dụng `CHECK constraint` cho các tập giá trị cố định (`role`, `rating`, `auth_provider`, `correct_option`), tránh lỗi nhập sai chuỗi linh tinh.
3. **Đánh chỉ mục (Indexing Strategy):**
   - Đánh Index trên tất cả các cột khóa ngoại thường dùng để `JOIN`.
   - Đánh Composite Index cho các truy vấn lọc thường xuyên (ví dụ: `idx_fsrs_user_due` trên `(user_id, due_date)` để API lấy thẻ cần ôn tập hôm nay chạy với tốc độ miligiây).
4. **Soft Delete (Xóa mềm):**
   - Bảng `decks` và `cards` có trường `deleted_at`. Khi người dùng bấm xóa, dữ liệu chỉ ẩn đi chứ không mất hẳn, tránh làm hỏng lịch sử thống kê DKT hoặc FSRS của người dùng.
5. **Đón đầu dữ liệu cho Machine Learning:**
   - **Bảng `fsrs_card_states` & `fsrs_review_logs`:** Đủ 100% các biến của thuật toán FSRS v4/v5 (`stability`, `difficulty`, `elapsed_days`, `scheduled_days`, `reps`, `lapses`, `rating`, `duration_ms`).
   - **Bảng `dkt_question_logs`:** Ghi lại chuỗi thời gian `(user_id, kc_id, is_correct, timestamp)` - đây chính là định dạng đầu vào chuẩn tắc của các mô hình Deep Knowledge Tracing (DKT / SAKT / SAINT).
6. **Bảo mật và Nghiệp vụ Quản trị viên (ADMIN):**
   - **Bảng `content_reports`:** Tiếp nhận và xử lý các báo cáo vi phạm nội dung (Spam, sai kiến thức, bạo lực) từ người học/giáo viên.
   - **Bảng `system_settings`:** Cho phép Admin thay đổi cấu hình động hệ thống (tham số FSRS mặc định, model AI, thông báo bảo trì).
   - **Bảng `admin_audit_logs`:** Lưu vết lịch sử mọi hành vi can thiệp dữ liệu (khóa tài khoản, gỡ bộ thẻ) để phục vụ kiểm toán minh bạch.
