# CLAUDE.md - Hướng Dẫn & Quy Chuẩn Phát Triển

Tệp này cung cấp thông tin ngắn gọn giúp AI Assistant và các thành viên nắm rõ quy tắc làm việc trên dự án đồ án này.

---

## 1. Thông tin chung dự án

- **Bối cảnh:** Đồ án sinh viên xây dựng hệ thống học tập Flashcard cá nhân hóa (Web React + Mobile Android Java + Backend Spring Boot + AI Python + PostgreSQL).
- **Nguyên tắc code:** 
  - Viết code ngắn gọn, rõ ràng, dễ hiểu, ưu tiên code chạy đúng và ổn định trước khi tối ưu nâng cao.
  - Không lạm dụng các thư viện quá phức tạp khi chưa cần thiết.
  - Giữ tài liệu chân thực, không chém gió tính năng ngoài phạm vi đồ án.

---

## 2. Quy tắc tự tạo Commit (Bắt buộc tuân thủ)

Luôn commit thường xuyên theo 4 thời điểm sau:

1. **Đã hoàn thành một logic nhỏ / chức năng nguyên tử (Atomic Commit):**
   - Vừa làm xong một việc cụ thể, có thể kiểm thử được ngay.
   - *Ví dụ:* Thiết kế xong giao diện màn hình đăng nhập, viết xong hàm mã hóa mật khẩu, tạo xong 1 API GET danh sách thẻ, ghép nối xong component thẻ lật.
2. **Sửa xong 1 bug cụ thể:**
   - Khi vừa tìm và sửa triệt để một lỗi, code chạy ổn định trở lại.
   - *Ví dụ:* Sửa lỗi không load được ảnh OCR, sửa lỗi tính sai ngày ôn thẻ FSRS.
3. **Trước khi thử nghiệm một hướng viết code mới:**
   - Commit lại trạng thái code đang chạy ngon lành.
   - *Mục đích:* Nếu hướng thử nghiệm thất bại hoặc bị lỗi dây chuyền, có thể quay lại phiên bản này một cách nhanh chóng và an toàn.
4. **Cuối buổi làm việc:**
   - Gom các phần đang làm dở lại, ghi rõ là đang làm dở (`WIP: ...`) để sao lưu trạng thái làm việc trong ngày lên Git, tránh mất code.

### Cú pháp thông điệp commit (đơn giản, dễ đọc):
- `feat: [tên chức năng nhỏ vừa xong]` (Ví dụ: `feat: tạo api lay danh sach the can on`)
- `fix: [lỗi cụ thể vừa sửa]` (Ví dụ: `fix: sua loi khong nhan diện duoc chu tieng viet ocr`)
- `ui: [màn hình vừa vẽ xong]` (Ví dụ: `ui: hoan thien man hinh mini game match the tren android`)
- `checkpoint: [luu trang thai on dinh truoc khi thu nghiem]`
- `wip: [phan viec dang lam do cuoi ngay]`

---

## 3. Các lệnh thường dùng

### Backend (Spring Boot + PostgreSQL)
```bash
cd backend
./mvnw clean compile           # Biên dịch
./mvnw spring-boot:run         # Chạy backend (port 8080)
./mvnw test                    # Chạy unit test
```

### Web Client (React)
```bash
cd web
npm install                    # Cài đặt thư viện
npm run dev                    # Chạy môi trường dev (Vite)
npm run build                  # Đóng gói sản phẩm
```

### Android App (Java - Empty Views Activity)
```bash
cd android
./gradlew assembleDebug        # Build file APK debug
./gradlew installDebug         # Cài đặt APK vào máy ảo / điện thoại đang cắm cáp
```

### AI Service (Python FastAPI)
```bash
cd ai-service
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

---

## 4. Lưu ý về Cơ sở dữ liệu (PostgreSQL)

- Toàn bộ backend sử dụng PostgreSQL làm hệ quản trị cơ sở dữ liệu chính.
- Mọi script tạo bảng hoặc migration (Flyway / Liquibase / SQL file) đặt trong `backend/src/main/resources/db/` hoặc thư mục `docs/`.
- Không hardcode mật khẩu CSDL trong mã nguồn public, dùng file cấu hình `.env` hoặc `application-local.properties`.
