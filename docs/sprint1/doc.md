# Tổng quan Game Engine SeaChess

## 1. Luồng hoạt động tổng thể (Overall Workflow)

Hệ thống được xây dựng theo mô hình **Clean Architecture**. Toàn bộ thuật toán quản lý bàn cờ, kiểm tra nước đi và xử lý luật chơi được triển khai trong project **`SeaChess.Domain`** bằng C# thuần túy.

Thiết kế này giúp tầng **Domain**:

* Không phụ thuộc vào ASP.NET Core, Entity Framework hay bất kỳ framework nào.
* Dễ kiểm thử (Unit Test).
* Dễ bảo trì.
* Có thể tái sử dụng trên nhiều nền tảng.

---

## Luồng xử lý Game Engine

```text
Khởi tạo bàn cờ
        │
        ▼
   Đọc chuỗi FEN
        │
        ▼
 Sinh nước đi cơ bản
(Pseudo-Legal Moves)
        │
        ▼
 Đi thử trên bàn cờ ảo
 (Virtual Move)
        │
        ▼
 Vua có bị chiếu?
    │         │
    │ Có      │ Không
    ▼         ▼
Loại bỏ   Nước đi hợp lệ
        │
        ▼
Kiểm tra trạng thái trận đấu
(Checkmate, Stalemate...)
```

### Bước 1. Khởi tạo trạng thái

Bàn cờ được khởi tạo từ chuỗi **FEN (Forsyth–Edwards Notation)**.

Ví dụ:

```text
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

---

### Bước 2. Sinh nước đi

Khi người chơi chọn một quân cờ:

* Hệ thống xác định loại quân.
* Gọi `MoveGenerator`.
* Sinh toàn bộ **Pseudo-Legal Moves** theo quy tắc di chuyển.

---

### Bước 3. Kiểm tra hợp lệ

Mỗi nước đi sẽ được thực hiện trên một **bản sao của bàn cờ** (Virtual Move).

Sau đó kiểm tra:

* Vua của người chơi có bị chiếu không?
* Nếu có → loại bỏ nước đi.
* Nếu không → nước đi hợp lệ.

---

### Bước 4. Phân tích trạng thái

Sau khi nước đi được xác nhận:

* Kiểm tra Check.
* Kiểm tra Checkmate.
* Kiểm tra Stalemate.
* Kiểm tra các điều kiện hòa.

---

# 2. Ý nghĩa các thành phần cốt lõi

## Entities & FEN Parser

### Board

Đại diện toàn bộ bàn cờ.

Quản lý:

* Danh sách quân cờ.
* Lượt đi.
* Quyền nhập thành.
* En Passant.
* Trạng thái FEN.

---

### Piece

Đại diện một quân cờ.

Thông tin gồm:

* Màu quân.
* Loại quân.

---

### Move

Đại diện một nước đi.

Bao gồm:

* Ô bắt đầu.
* Ô kết thúc.
* Loại nước đi.
* Quân được phong cấp (nếu có).

---

### Position

Đại diện một ô trên bàn cờ.

Ví dụ:

```text
e4
```

được lưu thành:

```text
File = 4
Rank = 3
```

---

## FEN Parser

### `LoadFromFen(string fen)`

Có nhiệm vụ:

* Đọc chuỗi FEN.
* Khởi tạo bàn cờ.
* Xác định lượt đi.
* Khôi phục đầy đủ trạng thái game.

Việc sử dụng FEN giúp:

* Tiết kiệm bộ nhớ.
* Đồng bộ trạng thái nhanh.
* Phục hồi trận đấu dễ dàng.

---

# MoveGenerator

Đây là **Domain Service** chịu trách nhiệm sinh nước đi.

---

## `GenerateSlidingMoves()`

Áp dụng cho:

* Xe
* Tượng
* Hậu

Thuật toán quét theo từng hướng:

```text
← ↑ → ↓
↖ ↗ ↘ ↙
```

Quân tiếp tục di chuyển cho đến khi:

* Ra khỏi bàn cờ.
* Gặp quân cản.

---

## `GenerateJumpMoves()`

Áp dụng cho:

* Mã
* Vua

Các quân này chỉ kiểm tra các vị trí cố định và **không cần quét liên tục**.

---

## `GeneratePawnMoves()`

Xử lý toàn bộ luật của quân Tốt:

* Đi 1 ô.
* Đi 2 ô lần đầu.
* Ăn chéo.
* En Passant.
* Promotion.

---

## `AddPawnMove()`

Thêm nước đi hợp lệ của quân Tốt vào danh sách.

Nếu đến hàng cuối:

* Tự động sinh các nước phong cấp.

---

## `GenerateCastlingMoves()`

Xử lý luật **Castling (Nhập thành)**.

Điều kiện:

* Vua chưa di chuyển.
* Xe chưa di chuyển.
* Không có quân cản.
* Không đi qua ô bị khống chế.
* Vua không đang bị chiếu.

---

## `IsOnBoard()`

Phương thức hỗ trợ.

Kiểm tra tọa độ có còn nằm trong bàn cờ hay không.

```csharp
0 <= file < 8
0 <= rank < 8
```

Giúp tránh truy cập ngoài mảng.

---

# GameStateAnalyzer

Đây là thành phần xác định trạng thái hiện tại của ván cờ.

Chịu trách nhiệm:

* Kiểm tra vua có bị chiếu.
* Kiểm tra chiếu hết.
* Kiểm tra hòa.
* Xác định kết quả trận đấu.

---

## Check

Kiểm tra xem quân vua hiện tại có đang bị đối phương tấn công hay không.

---

## Checkmate

Điều kiện:

* Đang bị chiếu.
* Không còn bất kỳ nước đi hợp lệ nào.

---

## Stalemate

Điều kiện:

* Không bị chiếu.
* Không còn nước đi hợp lệ.

---

## 50-Move Rule

Nếu trong **50 nước liên tiếp**:

* Không ăn quân.
* Không di chuyển quân Tốt.

=> Hòa.

---

## Threefold Repetition

Nếu cùng một trạng thái bàn cờ xuất hiện **3 lần**.

=> Hòa.

---

# 3. Vai trò của Unit Test

Trong Game Engine, viết được thuật toán mới chỉ là bước đầu.

Quan trọng hơn là **đảm bảo mọi luật chơi luôn chính xác** sau mỗi lần thay đổi mã nguồn.

SeaChess sử dụng **xUnit** để kiểm thử tự động.

---

## Các kịch bản kiểm thử

### BoardTests

Kiểm tra:

* Đọc FEN.
* Khởi tạo bàn cờ.
* Khởi tạo lượt đi.
* Khởi tạo vị trí quân.

---

### GameStateTests

Kiểm tra:

* Check.
* Checkmate.
* Stalemate.
* Các trường hợp đặc biệt.

---

## Quá trình khắc phục lỗi

Trong quá trình phát triển, Unit Test đã giúp phát hiện lỗi **Infinite Loop**.

Nguyên nhân:

* Sai hướng di chuyển `(0, 0)` trong thuật toán quét.
* Vị trí `break` không hợp lý.

Hệ quả:

* Tia quét không bao giờ kết thúc.
* `dotnet test` bị treo.

Sau khi sửa:

* Thuật toán hoạt động đúng.
* Tất cả bài kiểm thử đều hoàn thành.

---

# Kết quả hiện tại

* Hoàn thành Game Engine cơ bản.
* Hỗ trợ đầy đủ sinh nước đi cho các quân cờ.
* Hỗ trợ FEN Parser.
* Hỗ trợ các luật đặc biệt.
* Có hệ thống Unit Test tự động.
* Tất cả Test Case hiện tại đều **PASS** với thời gian thực thi khoảng **1 giây**.
