# Sprint 1 - Core Game Engine

## Task 1: Khởi tạo Solution

### Mục tiêu

Thiết lập cấu trúc **Clean Architecture** cho backend.

### Công việc

* Tạo Solution.
* Tạo các project:

  * `SeaChess.Domain`
  * `SeaChess.Application`
  * `SeaChess.Infrastructure`
  * `SeaChess.API`
  * `SeaChess.Tests`
* Thiết lập Project Reference.
* Cấu hình Dependency Injection cơ bản.

---

## Task 2: Phân tích & Thiết kế Domain Model

### Mục tiêu

Xây dựng các thực thể (Entities) thuần túy của Game Engine.

### Công việc

* Tạo `Board`.
* Tạo `Piece`.
* Tạo `Move`.
* Tạo `Position`.
* Tạo các `Enum`.
* Thiết kế quan hệ giữa các Entity.

---

## Task 3: Xây dựng FEN Parser

### Mục tiêu

Đọc và ghi trạng thái bàn cờ theo chuẩn **FEN (Forsyth–Edwards Notation)**.

### Công việc

* Parse chuỗi FEN thành bàn cờ.
* Khởi tạo trạng thái game từ FEN.
* Sinh lại chuỗi FEN sau mỗi nước đi.
* Xử lý:

  * Active Color
  * Castling Rights
  * En Passant Target
  * Halfmove Clock
  * Fullmove Number

---

## Task 4: Xử lý logic di chuyển cơ bản

### Mục tiêu

Xây dựng thuật toán sinh nước đi hợp lệ cho từng quân cờ.

### Công việc

* Tốt (Pawn)
* Xe (Rook)
* Mã (Knight)
* Tượng (Bishop)
* Hậu (Queen)
* Vua (King)

---

## Task 5: Xử lý luật đặc biệt

### Mục tiêu

Cài đặt đầy đủ các luật đặc biệt của cờ vua.

### Công việc

* Castling (Nhập thành)
* En Passant (Bắt tốt qua đường)
* Promotion (Phong cấp)

---

## Task 6: Xử lý trạng thái kết thúc trận đấu

### Mục tiêu

Xác định trạng thái của ván cờ.

### Công việc

* Check (Chiếu)
* Checkmate (Chiếu hết)
* Stalemate (Hòa cờ)
* 50-Move Rule
* Threefold Repetition

---

## Task 7: Viết Unit Test

### Mục tiêu

Đảm bảo tính chính xác của toàn bộ Game Engine.

### Công việc

* Viết Unit Test cho từng quân cờ.
* Kiểm thử FEN Parser.
* Kiểm thử các luật đặc biệt.
* Kiểm thử trạng thái kết thúc.
* Đạt độ bao phủ cao (ưu tiên gần **100%** đối với Game Engine).
