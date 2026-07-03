# Sprint 4 Backlog

| **Tên Task** | **Mô tả chi tiết** |
|--------------|--------------------|
| **1. Khởi tạo dự án Flutter** | Thiết lập cấu trúc thư mục theo **Clean Architecture** kết hợp mô hình **Feature-first**, bao gồm các tầng **Presentation**, **Domain**, **Data** và **Core**. Đồng thời tích hợp các thư viện nền tảng như **Riverpod**, **GoRouter**, **Dio** và **Flutter Secure Storage**. |
| **2. Kết nối REST API & Authentication** | Xây dựng giao diện **Đăng nhập** và **Đăng ký**, tích hợp REST API xác thực với Server, lưu trữ an toàn **JWT Token** bằng **Flutter Secure Storage**, đồng thời tự động đính kèm Token vào các request HTTP. |
| **3. Xây dựng giao diện bàn cờ (Chessboard)** | Phát triển giao diện bàn cờ 8×8 và hiển thị quân cờ dựa trên chuỗi **FEN** nhận từ Server. Chuyển đổi dữ liệu FEN thành 64 ô cờ cùng các quân cờ tương ứng trên giao diện Flutter. |
| **4. Tích hợp SignalR Client** | Thiết lập kết nối **WebSocket** tới `ChessHub`, gửi kèm **JWT Token** để xác thực. Lắng nghe các sự kiện thời gian thực như `MatchStarted`, `ReceiveMove` và các thông báo trạng thái trận đấu. |
| **5. Đồng bộ UI & Xử lý nước đi** | Xây dựng chức năng **Drag & Drop** quân cờ trên giao diện. Sau khi người chơi thực hiện nước đi, gửi sự kiện `MakeMove` lên Server thông qua SignalR, đồng thời cập nhật giao diện theo trạng thái mới mà Server trả về nhằm đảm bảo mô hình **Authoritative Server**. |