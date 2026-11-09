# Flashcard Learning System (Đồ Án Tốt Nghiệp)

> **Hệ thống học tập cá nhân hóa đa nền tảng sử dụng Spaced Repetition (FSRS) và Machine Learning (DKT) trên nền tảng Spring Boot, React và Android (Java).**

Dự án này là sản phẩm đồ án sinh viên, lấy cảm hứng từ Quizlet nhưng tập trung vào việc cá nhân hóa lộ trình ghi nhớ của người học bằng thuật toán khoa học não bộ và máy học.

---

## 1. Tính năng chính

- **Học qua thẻ ghi nhớ (Spaced Repetition):** Ứng dụng thuật toán **FSRS** để tính toán chính xác ngày cần ôn tập lại từng thẻ (Again, Hard, Good, Easy), giúp học lâu quên.
- **Tạo thẻ nhanh bằng OCR:** Chụp ảnh sách vở, bảng viết hoặc tài liệu để hệ thống tự nhận diện chữ và tách thành các thẻ từ vựng/khái niệm.
- **Kiểm tra trắc nghiệm 1 trong 4 kết hợp DKT:** Bài kiểm tra tự động sinh từ bộ thẻ. Thuật toán **Deep Knowledge Tracing (DKT)** theo dõi tiến trình làm bài để phát hiện khái niệm nào bạn còn yếu và cần ôn lại.
- **Mini-game ôn tập:** Trò chơi ghép thẻ (Match game) giúp việc học bớt nhàm chán và tạo hứng thú.
- **Lớp học & Nhóm học tập:** Giáo viên tạo lớp, chia sẻ bộ thẻ, giao bài tập và theo dõi bảng xếp hạng học sinh.
- **Trợ lý AI Chatbot:** Hỏi đáp, giải thích khái niệm khó hiểu hoặc tạo ví dụ minh họa bằng ngôn ngữ tự nhiên.

---

## 2. Công nghệ sử dụng

| Thành phần | Công nghệ | Ghi chú |
| :--- | :--- | :--- |
| **Backend** | Spring Boot (Java 17/21) | RESTful API, Spring Security, JWT, Spring Data JPA |
| **Cơ sở dữ liệu** | PostgreSQL | Lưu trữ người dùng, thẻ học, lớp học và lịch sử làm bài |
| **Web Frontend** | React (Vite, TypeScript/JavaScript) | Giao diện quản lý bộ thẻ, học bài và dashboard giáo viên |
| **Mobile App** | Android Native (Java - Empty Views Activity) | Ứng dụng di động học thẻ mọi lúc mọi nơi, có camera chụp OCR |
| **AI / Machine Learning** | Python (FastAPI / PyTorch) | Chạy FSRS (lên lịch thẻ), DKT (theo dõi kiến thức), OCR và kết nối LLM |

---

## 3. Cấu trúc thư mục Monolith

```
android-flashcard/
├── backend/          # Mã nguồn Spring Boot Server & cấu hình kết nối PostgreSQL
├── web/              # Mã nguồn Web Client (React)
├── android/          # Mã nguồn ứng dụng Android (Java, XML View)
├── ai-service/       # Dịch vụ Python cho mô hình DKT, FSRS, OCR & Chatbot
├── docs/             # Tài liệu đặc tả, sơ đồ cơ sở dữ liệu và báo cáo
├── README.md         # Giới thiệu tổng quan dự án
├── ARCHITECTURE.md   # Thiết kế kiến trúc hệ thống và cơ sở dữ liệu
├── CLAUDE.md         # Hướng dẫn quy chuẩn code và lệnh thực thi cho AI Assistant
├── CHANGELOG.md      # Nhật ký tiến độ thực hiện đồ án
└── CONTRIBUTING.md   # Quy tắc commit và quy trình phát triển
```

---

## 4. Hướng dẫn chạy nhanh (Quick Start)

### Yêu cầu môi trường
- Java JDK 17+
- Node.js 18+
- Android Studio (hỗ trợ Java & SDK tối thiểu 26)
- Python 3.10+
- PostgreSQL 14+

### Các bước khởi động cơ bản
1. **Khởi chạy Cơ sở dữ liệu PostgreSQL:**
   - Tạo database tên `flashcard_db` trên PostgreSQL local hoặc Docker.
2. **Khởi chạy Backend (Spring Boot):**
   ```bash
   cd backend
   ./mvnw spring-boot:run
   ```
3. **Khởi chạy AI Service (Python):**
   ```bash
   cd ai-service
   pip install -r requirements.txt
   uvicorn main:app --reload --port 8000
   ```
4. **Khởi chạy Web (React):**
   ```bash
   cd web
   npm install
   npm run dev
   ```
5. **Chạy ứng dụng Android:**
   - Mở thư mục `android/` bằng Android Studio và chạy trên máy ảo hoặc thiết bị thật.
