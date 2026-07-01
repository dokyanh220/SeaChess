| Task                             | Mô tả chi tiết                                                                                                                           |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Cài đặt SignalR               | Tích hợp SignalR vào `SeaChess.API`, cấu hình xác thực WebSocket bằng JWT để đảm bảo chỉ user hợp lệ mới kết nối được realtime.          |
| 2. Tạo ChessHub                  | Xây dựng `ChessHub` làm trung tâm xử lý realtime events từ client như `FindMatch`, `MakeMove`, `CancelMatch`.                            |
| 3. Logic Matchmaking (Ghép trận) | Sử dụng Redis để lưu danh sách người chơi đang chờ. Thuật toán sẽ ghép 2 người có Elo gần nhau để tạo trận đấu tối ưu.                   |
| 4. Đồng bộ State Trận Đấu        | Khi match thành công, khởi tạo bàn cờ từ Core Engine (Sprint 1), lưu state ván đấu vào Redis và broadcast dữ liệu realtime cho 2 client. |
| 5. Xử lý nước đi Realtime        | Nhận move từ client, validate qua Core Engine (luật cờ), nếu hợp lệ thì cập nhật state và gửi move cho đối thủ theo thời gian thực.      |
