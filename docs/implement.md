thử thách bản thân với máy (AI) thông qua các tùy chọn về độ khó, màu quân và thời gian trận đấu.

Tóm tắt yêu cầu
Cấp độ khó (Difficulty Levels):
Mới bắt đầu (Beginner)
Dễ (Easy)
Bình thường (Normal)
Khó (Hard)
Rất khó (Very hard)
Chọn màu quân (Side Selection):
Trắng (White)
Đen (Black)
Ngẫu nhiên (Random)
Chọn thời gian (Time Controls):
5 phút, 10 phút, 20 phút, 30 phút.
Giải pháp Kiến trúc đề xuất
Chúng ta có hai hướng đi chính cho Game Engine AI:

Server-Side AI (Khuyến nghị):
Chạy Engine Stockfish trên Server ASP.NET Core.
Client gửi nước đi lên thông qua SignalR/REST, Server chuyển nước đi vào Engine, lấy nước đi phản hồi tốt nhất của AI và gửi lại cho Client.
Ưu điểm: Đồng bộ logic game hoàn toàn trên Server, không tăng kích thước file cài đặt app client (.apk/.ipa), hoạt động ổn định trên mọi thiết bị di động cũ mà không gây nóng máy/tốn pin.
Client-Side AI (Local Engine):
Tích hợp một package engine cờ vua (như Stockfish chạy qua Flutter FFI hoặc WebAssembly) trực tiếp trên Flutter.
Ưu điểm: Hoạt động offline, phản hồi tức thì không phụ thuộc mạng.
Nhược điểm: Phức tạp trong việc build thư viện native cho đa nền tảng (Android, iOS, Windows, macOS, Web), tăng dung lượng ứng dụng và tốn pin thiết bị khi chạy ở độ khó cao.
IMPORTANT

Bản kế hoạch này được thiết kế theo hướng Server-Side AI do SeaChess hiện tại đang đi theo mô hình Server-authoritative (Server kiểm soát toàn bộ logic game để chống hack và đồng bộ qua SignalR).

Chi tiết các thiết lập & Phân tích Kỹ thuật
1. Cấu hình Cấp độ khó (Stockfish UCI Parameters)
Stockfish hỗ trợ điều chỉnh sức mạnh thông qua thông số Skill Level (từ 0 đến 20) và giới hạn độ sâu tìm kiếm depth hoặc thời gian tính toán movetime. Cấu hình đề xuất cho các cấp độ khó:

Cấp độ	Cấp độ Stockfish (Skill Level)	Độ sâu tối đa (depth)	Thời gian tối đa của AI	Mô tả
Mới bắt đầu	0	1	100ms	AI thường xuyên đi lỗi, thích hợp cho người mới học đi quân.
Dễ	3	3	200ms	AI chơi yếu, dễ mắc sai lầm cơ bản.
Bình thường	8	6	400ms	AI chơi ở mức độ phong trào trung bình.
Khó	14	10	800ms	AI chơi chắc chắn, ít lỗi sơ đẳng. Thử thách tốt.
Rất khó	20	15	1500ms	AI đạt sức mạnh tối đa ở độ sâu quy định, rất khó để thắng.
2. Thiết lập Màu quân (Side Selection)
Quân Trắng: Người chơi đi trước. Màn hình bàn cờ hiển thị góc nhìn từ phía quân Trắng (Bottom).
Quân Đen: AI đi trước. Server tự động gọi Stockfish thực hiện nước đi đầu tiên ngay khi trận đấu bắt đầu và gửi FEN về cho Client. Màn hình bàn cờ hiển thị góc nhìn từ phía quân Đen (Bottom).
Ngẫu nhiên: Server tung đồng xu ngẫu nhiên chọn Trắng hoặc Đen cho người chơi và tiến hành khởi tạo trận đấu tương ứng.
3. Đồng hồ và Thời gian (Time Controls)
Trận đấu có áp dụng đồng hồ đếm ngược (5, 10, 20, 30 phút) cho người chơi.
Khi đến lượt người chơi, đồng hồ đếm ngược của người chơi chạy. Nếu hết giờ, người chơi bị xử Thua do hết giờ (Timeout).
Đối với AI, thời gian đi quân của AI sẽ được trừ trực tiếp vào đồng hồ ảo của AI. Để trận đấu tự nhiên hơn, AI sẽ phản hồi sau một khoảng trễ nhỏ (ví dụ từ 500ms đến 2s tùy độ khó) thay vì đi quân ngay lập tức trong 1ms. AI không bao giờ bị xử thua vì hết giờ (do thời gian tính toán luôn bị giới hạn rất nhỏ).
Thay đổi đề xuất trong Mã nguồn
1. Giao diện Flutter (Client)
[NEW] 
ai_setup_dialog.dart
Widget Dialog/Bottom Sheet cho phép chọn cấu hình trận đấu:
Dropdown/Segmented Control chọn độ khó (5 cấp độ).
Radio/Icon Button chọn màu quân (Trắng, Đen, Ngẫu nhiên).
Grid/Segmented Control chọn thời gian (5, 10, 20, 30 phút).
Khi xác nhận, gửi Request tạo trận đấu với AI lên Server.
[MODIFY] 
lobby_screen.dart
Thêm nút "Đấu với Máy" bên cạnh nút "Tìm trận". Khi nhấn nút này sẽ hiển thị AiSetupDialog.
[MODIFY] 
game_screen.dart
Cập nhật hiển thị tên đối thủ là "Máy (AI) - Cấp độ: [Tên cấp độ]".
Đảm bảo góc quay của bàn cờ tương thích với màu quân được chọn (White ở dưới, Black ở trên hoặc ngược lại).
Chặn kéo thả quân cờ khi đang là lượt của AI (máy đang suy nghĩ).
2. Logic Backend (Server - ASP.NET Core)
[NEW] 
IStockfishService.cs
Interface định nghĩa dịch vụ tương tác với Stockfish.
Phương thức chính: Task<string> GetBestMoveAsync(string fen, int skillLevel, int depthMs);
[NEW] 
StockfishService.cs
Hiện thực hóa IStockfishService bằng cách giao tiếp với tiến trình stockfish (executable) qua giao thức UCI thông qua System.Diagnostics.Process.
Gửi lệnh:
text

position fen [FEN_STRING]
setoption name Skill Level value [SKILL_LEVEL]
go depth [DEPTH]
Đọc đầu ra để lấy chuỗi bestmove [FROM][TO] (ví dụ: bestmove e2e4).
[MODIFY] 
GameHub.cs
Thêm Event SignalR: StartAiGame(int difficulty, string colorPref, int timeMinutes).
Khi nhận sự kiện:
Tạo một phòng game AI riêng (không đưa vào hàng chờ matchmaking).
Xác định màu quân của người chơi (nếu random thì chọn ngẫu nhiên).
Khởi tạo trạng thái bàn cờ (FEN bắt đầu).
Nếu người chơi chọn quân Đen (AI đi trước), Server gọi ngay StockfishService để lấy nước đi đầu tiên cho AI, cập nhật FEN và gửi về Client.
Gửi sự kiện MatchStarted tới Client kèm theo thông tin phòng đấu và cấu hình quân cờ.
Sửa đổi hàm MakeMove trong Hub:
Khi người chơi thực hiện nước đi hợp lệ:
Cập nhật FEN bàn cờ.
Cập nhật thời gian của người chơi.
Gửi nước đi vừa thực hiện về Client để cập nhật UI.
Kiểm tra xem game đã kết thúc chưa (Checkmate/Draw). Nếu chưa, tiếp tục chạy luồng AI:
Server gọi StockfishService.GetBestMoveAsync với cấu hình độ khó của trận đấu.
Áp dụng nước đi của AI vào Game Engine để kiểm tra tính hợp lệ và cập nhật FEN mới.
Gửi sự kiện cập nhật nước đi của AI (MoveMade) về cho Client.
Kiểm tra trạng thái kết thúc ván cờ sau nước đi của AI.
Kế hoạch kiểm thử & Xác minh (Verification Plan)
Kiểm thử Tự động
Unit Test cho StockfishService:
Đảm bảo tiến trình Stockfish khởi động thành công trên môi trường chạy server.
Gửi các chuỗi FEN cơ bản (ví dụ thế cờ chiếu bí 1 nước) và kiểm tra xem Stockfish có trả về nước đi đúng hay không.
Kiểm tra việc điều chỉnh Skill Level có hoạt động chính xác và phản hồi đúng định dạng UCI.
Unit Test cho Luồng Game AI trên Server:
Giả lập trận đấu đấu với AI.
Xác minh việc chọn quân Đen thì AI luôn thực hiện nước đi đầu tiên.
Kiểm thử Thủ công
Kiểm tra UI/UX trên Client:
Mở Dialog cấu hình AI, chọn các tổ hợp khác nhau (Ví dụ: Khó + Đen + 10 phút) và nhấn bắt đầu.
Kiểm tra xem bàn cờ có được lật đúng góc nhìn (nếu chọn quân Đen thì quân Đen nằm phía dưới).
Kiểm tra đồng hồ đếm ngược của người chơi hoạt động đúng và dừng lại khi đến lượt AI.
Kiểm tra trải nghiệm chơi:
Chơi thử một ván ở cấp độ Mới bắt đầu để xem AI có đi các nước đi ngớ ngẩn hoặc dễ bị bắt quân hay không.
Chơi thử ở cấp độ Rất khó để kiểm tra tốc độ phản hồi và độ thông minh của AI.
Thử để hết giờ xem hệ thống có xử thua chính xác không.