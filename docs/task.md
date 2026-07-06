## 1. Kiểm soát Lượt đi (Turn Order & Move Lock)
Quân trắng luôn đi trước, và tuyệt đối không thể can thiệp khi chưa tới lượt.

Tại Server (C# SignalR): Mỗi khi nhận một nước đi (ví dụ method MakeMove), Server lấy UserId của người gửi và đối chiếu với trường turn trong Redis (hoặc kiểm tra ký tự lượt đi w hoặc b trong chuỗi FEN). Nếu không khớp, Server lập tức từ chối và gửi trả lại FEN hiện tại để Client rẽ nhánh lại bàn cờ.

Tại Client (Flutter): Để trải nghiệm mượt mà, khi không phải lượt của mình, biến isMyTurn sẽ bằng false. Gói thư viện bàn cờ trên Flutter sẽ vô hiệu hóa hoàn toàn khả năng kéo-thả (drag & drop) các quân cờ của phe mình.

## 2. Quản lý Đồng hồ và Thời gian (Time Controls)
Việc đếm ngược (10, 15, 20 phút) cần được xử lý thông minh để tránh giật lag mạng. Không nên dùng Server đếm ngược từng giây rồi gửi về Client (sẽ gây quá tải).

Logic chuẩn:

Khi trận đấu bắt đầu, Server lưu tổng thời gian của 2 người (VD: 600.000ms cho 10 phút) và thời điểm lastMoveTime.

Khi Player A đánh xong, Server lấy thời gian hiện tại trừ đi lastMoveTime ra khoảng thời gian A đã dùng. Trừ số này vào tổng thời gian của A.

Cập nhật lastMoveTime mới và chuyển lượt cho B.

Hiển thị ở Client: Flutter tự chạy một Timer đếm ngược từng giây trên màn hình. Mỗi khi có một nước đi mới được thực hiện, Client sẽ nhận lại số thời gian chuẩn xác từ Server để đồng bộ lại, giúp loại bỏ sai số do ping mạng.

Bắt lỗi Hết giờ (Timeout): Có một Background Service (hoặc dùng tính năng Expire của Redis) liên tục kiểm tra, nếu thời gian của một bên về 0, Server tự động phát sự kiện kết thúc ván.

## 3. Điều kiện Kết thúc trận (Win, Lose, Draw)
Sau mỗi nước đi hợp lệ, Core Engine C# của bạn phải làm nhiệm vụ đánh giá trạng thái bàn cờ để quyết định game tiếp tục hay dừng.

Thắng/Thua (Win/Lose):

Chiếu bí (Checkmate): Engine báo cờ bí, người vừa đi thắng.

Hết giờ (Timeout): Người hết giờ trước bị xử thua.

Đầu hàng (Resign): Một bên chủ động gửi sự kiện đầu hàng qua SignalR.

Hòa (Draw):

Hết nước đi (Stalemate): Tới lượt nhưng không bị chiếu và không còn nước đi hợp lệ.

Luật 50 nước (50-move rule): 50 nước liên tiếp không có quân nào bị bắt và không có Tốt nào di chuyển.

Hòa thuận tình (Draw offer): Một bên gửi yêu cầu hòa và bên kia đồng ý.