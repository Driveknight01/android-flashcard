# CONTRIBUTING.md - Hướng Dẫn Đóng Góp & Quy Chuẩn Code

Tài liệu này ghi lại các quy định làm việc nhóm hoặc cá nhân để đảm bảo mã nguồn đồ án luôn sạch sẽ, dễ bảo trì và không bị mất code.

---

## 1. Quy tắc Commit bắt buộc

Để tránh tình trạng "viết một lèo cả tuần mới commit một lần" dẫn đến xung đột code hoặc không biết lỗi phát sinh từ đâu, dự án tuân thủ nghiêm ngặt **4 thời điểm commit**:

### 1. Khi hoàn thành một logic nhỏ / chức năng nguyên tử (Atomic Commit)
- **Định nghĩa:** Một chức năng nhỏ vừa viết xong và kiểm thử hoạt động được độc lập.
- **Ví dụ thực tế:**
  - Thiết kế xong giao diện màn hình đăng nhập (chưa cần nối API).
  - Viết xong hàm mã hóa mật khẩu bằng BCrypt.
  - Tạo xong 1 API `GET /api/decks` lấy danh sách bộ thẻ.
  - Ghép xong logic bấm nút lật mặt sau của thẻ trên Android.

### 2. Khi sửa xong 1 lỗi cụ thể (Bug Fix)
- Vừa debug xong một lỗi và kiểm tra code đã chạy ổn định trở lại.
- **Ví dụ thực tế:**
  - Sửa lỗi không hiển thị tiếng Việt có dấu khi nhận diện chữ bằng OCR.
  - Sửa lỗi crash app trên Android khi danh sách thẻ bị rỗng.

### 3. Trước khi thử nghiệm một hướng viết code mới
- **Mục đích:** Tạo một "điểm lưu an toàn" (checkpoint) cho trạng thái code đang chạy ngon lành.
- Nếu thử nghiệm hướng mới thất bại, bị lỗi dây chuyền hoặc không kịp giờ báo cáo, bạn chỉ cần dùng lệnh Git để quay về mốc này một cách dễ dàng mà không làm hỏng dự án.

### 4. Cuối buổi làm việc hàng ngày
- Gom toàn bộ các phần việc đang làm dở lại.
- Có thể ghi rõ trong thông điệp commit là đang làm dở (ví dụ: `wip: dang lam do man hinh ket qua thi dkt`).
- Đẩy (push) lên Git để sao lưu trạng thái làm việc trong ngày, tránh sự cố hỏng máy tính hoặc mất file.

---

## 2. Quy ước đặt tên nhánh (Branch)

Giữ quy trình phân nhánh đơn giản, phù hợp với đồ án sinh viên:

- `main`: Nhánh code ổn định nhất, dùng để đem đi nộp báo cáo hoặc demo cho giáo viên hướng dẫn và hội đồng.
- `dev`: Nhánh phát triển chính hàng ngày.
- `feature/[tên-chức-năng]`: Nhánh làm tính năng riêng biệt trước khi gộp vào `dev`.
  - *Ví dụ:* `feature/fsrs-engine`, `feature/android-ocr`, `feature/web-class-dashboard`.
- `fix/[tên-lỗi]`: Nhánh dùng để sửa các lỗi cụ thể.

---

## 3. Quy chuẩn viết mã nguồn (Code Style)

1. **Đặt tên biến và hàm:**
   - Đặt tên có nghĩa bằng tiếng Anh (hoặc tiếng Việt không dấu rõ nghĩa nếu thuật ngữ chuyên ngành khó dịch).
   - Java / React: Sử dụng kiểu lạc đà (`camelCase`) cho tên biến/hàm (ví dụ: `getDueCards()`, `calculateInterval()`).
   - Tên Class / Component: Sử dụng `PascalCase` (ví dụ: `FlashcardActivity`, `DeckController`, `StudyCard`).
2. **Cơ sở dữ liệu PostgreSQL:**
   - Tên bảng và tên cột trong PostgreSQL viết chữ thường nối bằng dấu gạch dưới (`snake_case`): ví dụ `created_at`, `deck_id`, `is_public`.
3. **Giữ code đơn giản:**
   - Không copy-paste các đoạn mã quá dài mà không hiểu rõ nó hoạt động như thế nào.
   - Thêm chú thích (comment) ngắn gọn tại các đoạn tính toán thuật toán phức tạp như FSRS hoặc ma trận DKT để thuận tiện khi trả lời vấn đáp.
