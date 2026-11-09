# ARCHITECTURE.md - Thiết Kế Kiến Trúc Hệ Thống

Tài liệu này mô tả kiến trúc hệ thống phục vụ cho việc xây dựng đồ án một cách thực tế, mạch lạc và dễ báo cáo.

---

## 1. Lựa chọn kiến trúc: Monolith Repo

Dự án chọn mô hình **Monolith** (tất cả các phần Web, Mobile, Backend và AI đặt chung trong một kho mã nguồn duy nhất). 

### Lý do lựa chọn:
- **Thực tế với sinh viên:** Dễ theo dõi toàn bộ dự án trên một màn hình, không phải quản lý nhiều repository riêng lẻ.
- **Dễ chạy thử:** Khi chuẩn bị máy để demo với thầy cô hoặc hội đồng bảo vệ, chỉ cần kéo 1 repo về máy là có đủ cả bộ.
- **Tiện chia sẻ dữ liệu:** Dễ dàng đối chiếu kiểu dữ liệu (DTO) giữa Backend, Web và Android.

---

## 2. Mô hình luồng dữ liệu (Data Flow)

```
[ Web (React) ]         [ Mobile (Android Java) ]
       \                       /
        \                     / (Gửi HTTP REST / JWT)
         ▼                   ▼
    +-----------------------------+
    |    Spring Boot (Backend)    |
    |  - Quản lý logic nghiệp vụ   |
    |  - Xác thực người dùng (JWT)|
    +-----------------------------+
         /                     \
 (Truy vấn SQL)           (Gọi REST nội bộ)
       /                         \
      ▼                           ▼
[ PostgreSQL Database ]     [ AI Service (Python) ]
- Lưu trữ người dùng        - Tính thuật toán FSRS (ngày ôn)
- Bộ thẻ, câu hỏi, điểm số  - Chạy mô hình DKT (độ hiểu bài)
                            - Nhận diện chữ từ ảnh (OCR)
                            - Trả lời câu hỏi (AI Chatbot)
```

---

## 3. Trách nhiệm của từng thành phần

### 3.1. Backend (`backend/`)
- Sử dụng **Spring Boot** (Java 17/21).
- Chịu trách nhiệm chính:
  - Cung cấp API đăng ký, đăng nhập, bảo vệ tài nguyên qua JWT Token.
  - Quản lý CRUD cho: Bộ thẻ (Decks), Thẻ (Cards), Lớp học (Classes), Bài tập (Assignments).
  - Khi người dùng đánh giá thẻ $\rightarrow$ Spring Boot gọi sang AI Service để lấy ngày ôn tập kế tiếp rồi lưu vào PostgreSQL.
  - Khi học sinh làm xong bài kiểm tra $\rightarrow$ Spring Boot gửi kết quả đúng/sai sang AI Service để chạy mô hình DKT và nhận lại đánh giá năng lực.

### 3.2. Cơ sở dữ liệu (PostgreSQL)
- Lưu trữ toàn bộ dữ liệu có cấu trúc của hệ thống.
- Các bảng chính:
  - `users`: Tài khoản, mật khẩu băm, vai trò (học sinh, giáo viên), chuỗi ngày học (streak).
  - `decks`: Thông tin bộ thẻ học phần.
  - `cards`: Nội dung mặt trước, mặt sau của thẻ học.
  - `fsrs_states`: Lưu trữ độ khó, độ bền trí nhớ và ngày cần ôn tập lại của từng thẻ.
  - `classes` & `class_members`: Quản lý lớp học và danh sách học sinh tham gia.
  - `quiz_logs`: Lịch sử câu hỏi trắc nghiệm đã làm để nạp vào mô hình DKT.

### 3.3. Web Frontend (`web/`)
- Viết bằng **React** (Vite + TailwindCSS hoặc Ant Design).
- Tập trung vào màn hình làm việc rộng của máy tính:
  - Màn hình soạn thảo thẻ học nhanh bằng bàn phím.
  - Dashboard dành cho giáo viên: Xem danh sách học sinh, giao bài tập và xem biểu đồ tiến độ.
  - Màn hình học thẻ lật và làm bài trắc nghiệm kiểm tra.

### 3.4. Mobile App (`android/`)
- Viết bằng **Android Native (Java - Empty Views Activity)**.
- Giao diện thiết kế bằng tệp XML Layout truyền thống, thân thiện với sinh viên học môn Lập trình di động:
  - Sử dụng `RecyclerView` cho danh sách thẻ, danh sách lớp học.
  - Dùng Animation lật thẻ 3D khi học Spaced Repetition.
  - Tích hợp Camera để chụp trang sách phục vụ tính năng tạo thẻ bằng OCR.
  - Dùng **Retrofit2** để gọi API từ Spring Boot.

### 3.5. AI Service (`ai-service/`)
- Viết bằng **Python (FastAPI)** để tận dụng hệ sinh thái thư viện AI có sẵn:
  - **FSRS Scheduler:** Sử dụng thư viện `py-fsrs` tính toán các chỉ số trí nhớ: Stability, Difficulty, Retrievability và ngày ôn kế tiếp.
  - **DKT (Deep Knowledge Tracing):** Mô hình mạng nơ-ron (LSTM hoặc Transformer nhỏ) dự đoán xác suất trả lời đúng các câu hỏi tiếp theo và chỉ ra kiến thức còn hổng.
  - **OCR:** Nhận ảnh, dùng thư viện OCR (như Tesseract hoặc EasyOCR) tách chữ ra thành từng dòng.
  - **Chatbot:** Gọi API của mô hình ngôn ngữ lớn (Gemini hoặc OpenAI) để giải thích từ vựng hoặc tạo câu hỏi mẫu.
