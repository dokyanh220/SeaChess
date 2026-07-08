Cấu hình & Hiện thực Dịch vụ Stockfish trên Backend: Tải Engine, cấu hình đường dẫn và viết dịch vụ giao tiếp UCI qua Process.
Cập nhật SignalR Hub (C# Backend): Bổ sung API tạo trận đấu AI, xử lý nước đi của AI trong MakeMove và tránh crash Elo khi đối thủ là AI trong EndGame.
Cập nhật Flutter Client (Dart Frontend): Tích hợp phương thức gọi SignalR, thiết kế giao diện tùy chọn AI (AiSetupDialog) và điều chỉnh màn hình chơi game (GameScreen).
Kiểm thử & Đánh giá: Viết unit test cho StockfishService và thử nghiệm các kịch bản thực tế (chọn Đen, hết giờ, độ khó khác nhau).