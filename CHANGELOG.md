# CHANGELOG.md - Nhật Ký Phát Triển Đồ Án

Tất cả các mốc thay đổi và tiến độ thực hiện đồ án sẽ được ghi chép ngắn gọn tại đây theo ngày tháng và phiên bản.

---

## [Chưa phát hành - Kế hoạch sắp tới]

### Dự kiến v0.2.0 - Xây dựng Backend Core & Database
- [ ] Thiết kế file script SQL tạo các bảng trên PostgreSQL.
- [ ] Khởi tạo project Spring Boot với Spring Security và JWT.
- [ ] Viết API quản lý tài khoản, bộ thẻ (Decks) và thẻ (Cards).

### Dự kiến v0.3.0 - Tích hợp FSRS & DKT Service
- [ ] Dựng service Python FastAPI chạy thuật toán FSRS cho việc ôn thẻ.
- [ ] Xây dựng mô hình DKT cơ bản để đánh giá kỹ năng qua trắc nghiệm.
- [ ] Kết nối Spring Boot gọi sang AI Service qua REST API.

### Dự kiến v0.4.0 - Hoàn thiện Giao diện Web (React) & App (Android Java)
- [ ] Dựng các màn hình học thẻ, lật thẻ, mini-game nối từ trên React.
- [ ] Dựng các Activity trên Android Java (Đăng nhập, Danh sách thẻ, Học Spaced Repetition, Chụp ảnh OCR).

### Dự kiến v1.0.0 - Đóng gói nghiệm thu đồ án
- [ ] Kiểm thử toàn diện các luồng chức năng.
- [ ] Viết báo cáo tốt nghiệp, vẽ sơ đồ và chuẩn bị slide thuyết trình.

---

## [v0.1.0] - 2026-11-09

### Đã hoàn thành (Initial Setup)
- Khởi tạo cấu trúc thư mục Monolith cho dự án (`backend/`, `web/`, `android/`, `ai-service/`, `docs/`).
- Lựa chọn công nghệ chính: Spring Boot (Java), React (Web), Android Native (Java - Empty Views Activity), PostgreSQL (Database) và Python (AI/ML).
- Viết tài liệu khởi đầu: `README.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `CHANGELOG.md`, `CONTRIBUTING.md`.
- Chốt 6 module chức năng chính: Học thẻ Spaced Repetition (FSRS), Tạo thẻ với OCR, Mini-game nối thẻ, Lớp học & Nhóm, Kiểm tra trắc nghiệm 1 in 4 (DKT), AI Chatbot.
