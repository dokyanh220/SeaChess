# Tài Liệu Kỹ Thuật: Chế Độ Đấu Với Máy (AI Mode)

Tài liệu này mô tả chi tiết về cách hoạt động, kiến trúc, và các thông số cấu hình của chế độ "Đấu với máy" trong dự án SeaChess, sử dụng engine Stockfish để tính toán nước đi.

## 1. Kiến trúc tổng quan

Chế độ đấu với máy hoạt động dựa trên mô hình Client - Server thông qua WebSockets (SignalR):
1. **Client (Flutter):** Thu thập các tuỳ chọn từ người chơi (Độ khó, Màu quân, Thời gian) tại màn hình `AiSetupScreen`.
2. **SignalR Connection:** Client giao tiếp với Server qua kết nối SignalR (tại endpoint `/hubs/chess`). Hàm `ensureConnected()` sẽ đảm bảo Client luôn kết nối trước khi gửi dữ liệu.
3. **Server (.NET API):** Nhận lệnh tạo phòng đấu AI. `ChessHub` sẽ chuyển trạng thái của người chơi sang `IsAiGame = true`.
4. **Engine (Stockfish):** Server sử dụng `StockfishService` để giao tiếp với file thực thi Stockfish (chạy dưới dạng Process độc lập) thông qua giao thức **UCI** (Universal Chess Interface).

## 2. Quản lý Độ Khó (Difficulty Settings)

Mọi thông số về độ khó được tách biệt thành một Class `AiSettings` và được quản lý tập trung tại hàm `StockfishConfig.GetSettings(AiDifficulty difficulty)`. 

### Các thông số cấu hình:
- **UseElo (bool):** Có sử dụng tính năng giới hạn sức mạnh theo Elo (`UCI_LimitStrength`) của Stockfish hay không.
- **Elo (int):** Chỉ số Elo giới hạn cho máy.
- **SkillLevel (int):** Cấp độ kỹ năng của Stockfish (từ 0 đến 20).
- **Depth (int):** Độ sâu tìm kiếm (số nước tính trước). Depth càng cao AI càng mạnh.
- **ThinkTimeMs (int):** Thời gian suy nghĩ tối đa cho một nước đi (tính bằng mili giây).
- **RandomMoveChance (int):** Tỷ lệ phần trăm (0-100) máy sẽ đi một nước hoàn toàn ngẫu nhiên.

### Các cấp độ hiện tại:

| Cấp độ | Random (%) | Giới hạn Elo | Elo | Skill Level | Độ Sâu (Depth) | Thời gian nghĩ (ms) | Mô tả |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Beginner** | 50% | Có | 1320 | 0 | 1 | 100 | Rất yếu. Thường xuyên mắc lỗi ngớ ngẩn do 50% tỉ lệ đi nước ngẫu nhiên hoàn toàn. |
| **Easy** | 0% | Có | 1350 | 0 | 2 | 200 | Dễ. Máy không đi bậy, nhưng bị giới hạn độ sâu tính toán ở 2 nước nên dễ dính bẫy chiến thuật. |
| **Medium** | 0% | Có | 1500 | 3 | 4 | 400 | Vừa phải. Mô phỏng lối chơi của một kỳ thủ phong trào bình thường. |
| **Hard** | 0% | Không | N/A | 14 | 10 | 800 | Rất khó. Tắt giới hạn Elo, sử dụng Skill Level cao để phân tích thế trận phức tạp. |

## 3. Quy trình tính toán nước đi (GetBestMoveAsync)

Khi đến lượt AI đi, hàm `GetBestMoveAsync` trong `StockfishService` sẽ thực thi các bước sau:

1. **Khởi tạo trễ (Lazy Initialization):**
   Stockfish không được bật ngay khi Server khởi động để tránh crash hệ thống nếu lỗi. Hàm `EnsureInitialized()` chỉ khởi động Stockfish khi có người chơi chọn chế độ AI.
2. **Kiểm tra Random Move (Dành cho Beginner):**
   Đổ xí ngầu theo tỷ lệ `RandomMoveChance`. Nếu trúng, tự động sinh ra một nước đi hợp lệ hoàn toàn ngẫu nhiên bằng `GameStateAnalyzer.GetLegalMoves`, bỏ qua việc hỏi Stockfish để tiết kiệm tài nguyên.
3. **Reset Game (ucinewgame):**
   Gửi lệnh `ucinewgame` để xóa bộ nhớ đệm của trận đấu cũ.
4. **Cấu hình độ khó:**
   Gửi các lệnh UCI để set `UCI_LimitStrength`, `UCI_Elo` và `Skill Level` dựa vào `AiSettings`.
5. **Gán bàn cờ hiện tại:**
   Truyền thế cờ hiện tại vào Stockfish bằng lệnh: `position fen <Chuỗi FEN>`.
6. **Yêu cầu phân tích:**
   Ra lệnh tính toán: `go depth <Depth> movetime <ThinkTimeMs>`.
7. **Đọc kết quả:**
   Chờ Stockfish trả về chuỗi `bestmove <nước_đi>` và trả kết quả về cho SignalR Hub.

## 4. Xử lý hạ tầng (Deployment & Docker)

Stockfish được cài đặt thẳng vào trong Docker container bằng lệnh:
```dockerfile
RUN apt-get update && apt-get install -y stockfish && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/games/stockfish /usr/local/bin/stockfish
```
Việc tạo Symbol Link (`ln -sf`) giúp hệ thống .NET có thể gọi trực tiếp lệnh `stockfish` mà không cần cung cấp đường dẫn tuyệt đối, giải quyết được bài toán tương thích khi chạy trên các môi trường Linux/Debian khác nhau.
