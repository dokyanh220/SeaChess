# SeaChess 🌊♟️

SeaChess là một ứng dụng cờ vua trực tuyến thời gian thực hiện đại, được xây dựng với Backend mạnh mẽ bằng .NET và Frontend đa nền tảng bằng Flutter. Dự án mang đến cho người chơi trải nghiệm cờ vua online mượt mà, tích hợp hệ thống tìm trận cạnh tranh, hệ thống xếp hạng Elo, và khả năng thi đấu với engine AI thông minh.

## 🌟 Tính năng nổi bật

- **Chơi mạng thời gian thực (Real-Time Multiplayer):** Thi đấu với người chơi khác trên toàn thế giới, đồng bộ nước đi gần như tức thời nhờ công nghệ SignalR.
- **Hệ thống tìm trận & Xếp hạng Elo:** Tự động ghép cặp (Matchmaking) dựa trên điểm Elo của người chơi, đảm bảo các trận đấu diễn ra công bằng và kịch tính.
- **Thi đấu với AI:** Thử thách bản thân với AI được tích hợp sẵn (sử dụng engine Stockfish) qua nhiều cấp độ khó khác nhau (Người mới, Dễ, Trung bình, Khó) để rèn luyện kỹ năng.
- **Lịch sử & Xem lại trận đấu:** Xem lại các trận đấu cũ hỗ trợ đầy đủ định dạng PGN (Portable Game Notation). Điều hướng qua lịch sử trận đấu với giao diện trực quan, theo dõi số quân cờ đã bị ăn và phát lại bàn cờ tương tác.
- **Thông báo thời gian thực & Hệ thống bạn bè:** Thêm bạn bè, xem trạng thái trực tuyến của họ, và nhận thông báo ngay lập tức về lời mời thách đấu hoặc sự kiện hệ thống.
- **Client đa nền tảng:** Ứng dụng di động thiết kế đẹp mắt, đáp ứng tốt, viết bằng Flutter, tối ưu hóa cho Android và iOS.

## 🛠️ Công nghệ sử dụng

### Backend (`server/`)
- **Framework:** .NET 10.0 (C#) / ASP.NET Core Web API
- **Giao tiếp thời gian thực:** SignalR
- **Cơ sở dữ liệu:** PostgreSQL với Entity Framework Core
- **Bộ đệm & Hàng đợi tìm trận:** Redis
- **AI Engine:** Stockfish
- **Xác thực:** JWT (JSON Web Tokens)

### Frontend (`client/`)
- **Framework:** Flutter (Dart)
- **Quản lý trạng thái:** Riverpod
- **Giao tiếp mạng:** Dio (HTTP client) & SignalR Core cho Dart
- **Đồ họa & Âm thanh:** Các quân cờ thiết kế tùy chỉnh, giao diện động mang hơi hướng Glassmorphism, kết hợp hiệu ứng âm thanh sống động bằng gói `audioplayers`.

## 🚀 Hướng dẫn cài đặt

### Yêu cầu hệ thống
- Docker & Docker Compose (dành cho Postgres và Redis)
- .NET 10.0 SDK
- Flutter SDK (phiên bản ổn định mới nhất)
- (Tùy chọn) Android Studio / Xcode để chạy ứng dụng di động

### Chạy Backend
1. Clone mã nguồn và mở thư mục gốc của dự án.
2. Khởi động cơ sở dữ liệu và Redis:
   ```bash
   docker-compose up -d
   ```
3. Di chuyển vào thư mục server:
   ```bash
   cd server/SeaChess.API
   ```
4. Chạy Entity Framework migrations để khởi tạo cấu trúc cơ sở dữ liệu:
   ```bash
   dotnet ef database update
   ```
5. Chạy API:
   ```bash
   dotnet run
   ```

### Chạy Frontend
1. Di chuyển vào thư mục client:
   ```bash
   cd client
   ```
2. Tải các gói phụ thuộc:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng trên thiết bị đã kết nối hoặc máy ảo:
   ```bash
   flutter run
   ```

## 📸 Hình ảnh thực tế
*(Sắp ra mắt)*

## 📄 Giấy phép
Dự án này được cấp phép theo Giấy phép MIT.
