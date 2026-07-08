# Chức năng: Đấu với Máy (AI)

Cho phép người chơi thử thách bản thân với máy (AI) thông qua các tùy chọn về **độ khó**, **màu quân** và **thời gian trận đấu**.

---

# Tóm tắt yêu cầu

## Cấp độ khó (Difficulty Levels)

- Mới bắt đầu (Beginner)
- Dễ (Easy)
- Bình thường (Normal)
- Khó (Hard)
- Rất khó (Very Hard)

## Chọn màu quân (Side Selection)

- Trắng (White)
- Đen (Black)
- Ngẫu nhiên (Random)

## Chọn thời gian (Time Controls)

- 5 phút
- 10 phút
- 20 phút
- 30 phút

---

# Giải pháp kiến trúc đề xuất

Có hai hướng triển khai AI.

## 1. Server-Side AI (Khuyến nghị)

Chạy Stockfish trên ASP.NET Core Server.

Luồng hoạt động:

```text
Flutter
    │
SignalR / REST
    │
ASP.NET Core
    │
Stockfish Engine
    │
Best Move
    │
Flutter
```

### Ưu điểm

- Toàn bộ logic game nằm trên Server.
- Chống hack tốt.
- Client nhẹ, không tăng dung lượng APK/IPA.
- Hoạt động ổn định trên các thiết bị cấu hình thấp.
- Không làm nóng máy hoặc tiêu tốn pin.

---

## 2. Client-Side AI

Tích hợp Stockfish trực tiếp vào Flutter thông qua:

- Flutter FFI
- WebAssembly

### Ưu điểm

- Chơi offline.
- Phản hồi gần như tức thì.

### Nhược điểm

- Build native phức tạp cho Android/iOS/Desktop/Web.
- Tăng kích thước ứng dụng.
- Tiêu hao CPU và pin ở độ khó cao.

---

> **Quan trọng**
>
> SeaChess sử dụng kiến trúc **Server-authoritative**, vì vậy lựa chọn **Server-Side AI** là phù hợp nhất nhằm đảm bảo đồng bộ trạng thái trận đấu và chống gian lận.

---

# Thiết lập AI

## 1. Cấp độ khó

Stockfish hỗ trợ cấu hình thông qua:

- Skill Level
- Search Depth
- Thời gian suy nghĩ

| Cấp độ | Skill Level | Depth | Thời gian suy nghĩ | Mô tả |
|---------|------------:|------:|-------------------:|------|
| Mới bắt đầu | 0 | 1 | 100ms | AI thường xuyên đi sai, phù hợp người mới. |
| Dễ | 3 | 3 | 200ms | AI yếu, mắc nhiều lỗi cơ bản. |
| Bình thường | 8 | 6 | 400ms | Mức độ trung bình. |
| Khó | 14 | 10 | 800ms | Chơi chắc chắn, ít sai lầm. |
| Rất khó | 20 | 15 | 1500ms | Sức mạnh tối đa theo giới hạn depth. |

---

## 2. Chọn màu quân

### Trắng

- Người chơi đi trước.
- Bàn cờ hiển thị theo góc nhìn quân Trắng.

### Đen

- AI đi trước.
- Server gọi Stockfish thực hiện nước đầu tiên.
- Gửi trạng thái FEN mới về Client.
- Bàn cờ hiển thị theo góc nhìn quân Đen.

### Ngẫu nhiên

Server chọn ngẫu nhiên Trắng hoặc Đen.

---

## 3. Đồng hồ thi đấu

Các lựa chọn:

- 5 phút
- 10 phút
- 20 phút
- 30 phút

### Người chơi

- Đồng hồ chỉ chạy khi đến lượt người chơi.
- Hết giờ ⇒ Thua do Timeout.

### AI

- Thời gian suy nghĩ được trừ vào đồng hồ AI.
- AI phản hồi sau khoảng:

```
500ms ~ 2s
```

để tạo cảm giác tự nhiên.

AI sẽ không bị xử thua vì hết giờ.

---

# Thay đổi mã nguồn

## Flutter Client

### [NEW] ai_setup_dialog.dart

Dialog cấu hình trận đấu AI.

Bao gồm:

- Dropdown chọn độ khó
- Radio chọn màu quân
- Grid chọn thời gian

Sau khi xác nhận:

- Gửi request tạo trận đấu AI lên Server.

---

### [MODIFY] lobby_screen.dart

Thêm nút:

```
Đấu với Máy
```

Khi nhấn:

```
Hiển thị AiSetupDialog
```

---

### [MODIFY] game_screen.dart

Cập nhật:

- Hiển thị tên đối thủ

```
Máy (AI) - Khó
```

- Xoay bàn cờ theo màu quân.
- Khóa thao tác kéo quân khi AI đang suy nghĩ.

---

# Backend ASP.NET Core

## [NEW] IStockfishService.cs

```csharp
Task<string> GetBestMoveAsync(
    string fen,
    int skillLevel,
    int depth
);
```

---

## [NEW] StockfishService.cs

Khởi chạy tiến trình Stockfish bằng:

```csharp
System.Diagnostics.Process
```

Giao tiếp theo chuẩn UCI.

Ví dụ:

```text
position fen [FEN]
setoption name Skill Level value [LEVEL]
go depth [DEPTH]
```

Đọc kết quả:

```text
bestmove e2e4
```

---

## [MODIFY] GameHub.cs

Thêm SignalR Event:

```csharp
StartAiGame(
    int difficulty,
    string colorPreference,
    int timeMinutes
)
```

Quy trình:

1. Tạo phòng AI.
2. Chọn màu quân.
3. Khởi tạo FEN.
4. Nếu AI đi trước:
   - Gọi Stockfish.
   - Cập nhật bàn cờ.
5. Gửi MatchStarted về Client.

---

### MakeMove()

Sau khi người chơi đi:

1. Kiểm tra hợp lệ.
2. Cập nhật FEN.
3. Cập nhật đồng hồ.
4. Gửi MoveMade cho Client.
5. Kiểm tra kết thúc trận.

Nếu chưa kết thúc:

- Gọi Stockfish.
- Lấy nước đi tốt nhất.
- Áp dụng vào Game Engine.
- Cập nhật FEN.
- Gửi MoveMade của AI.
- Kiểm tra trạng thái kết thúc.

---

# Verification Plan

## Unit Test

### StockfishService

- Khởi động Stockfish.
- Kiểm tra gửi FEN.
- Kiểm tra trả về bestmove.
- Kiểm tra Skill Level.
- Kiểm tra định dạng UCI.

---

### Game AI

- Giả lập trận đấu.
- Kiểm tra AI đi trước khi người chơi chọn quân Đen.
- Kiểm tra tạo phòng AI.

---

# Manual Test

## UI

Kiểm tra các tổ hợp:

- Khó + Đen + 10 phút
- Dễ + Trắng + 5 phút
- Rất khó + Ngẫu nhiên + 30 phút

Xác nhận:

- Bàn cờ xoay đúng.
- Đồng hồ chạy đúng.
- Không thể kéo quân khi AI đang suy nghĩ.

---

## Gameplay

### Mới bắt đầu

- AI đi nhiều nước yếu.
- Dễ bắt quân.

### Rất khó

- AI phản hồi nhanh.
- Chất lượng nước đi cao.

### Timeout

Để hết giờ và xác nhận hệ thống xử thua chính xác.