# Kế hoạch phát triển ứng dụng SeaChess

## 1. Phân tích yêu cầu (Requirement Analysis)

### Tổng quan

* **Mục tiêu:** Xây dựng ứng dụng chơi cờ vua trực tuyến đa nền tảng (Cross-platform), cho phép người chơi thi đấu với nhau theo thời gian thực.
* **Đối tượng:** Người yêu thích cờ vua từ nghiệp dư đến chuyên nghiệp.

### Tính năng chính (MVP)

* Quản lý tài khoản

  * Đăng ký
  * Đăng nhập
  * Hồ sơ cá nhân

* Matchmaking

  * Tự động ghép cặp người chơi đang tìm trận.

* Gameplay (Real-time)

  * Chơi cờ thời gian thực.
  * Đồng hồ đếm ngược.

* Game Engine

  * Checkmate
  * Stalemate
  * Castling
  * En Passant
  * Promotion
  * 50-move Rule
  * Threefold Repetition

* Lịch sử trận đấu

  * Lưu toàn bộ nước đi.
  * Xem lại trận đấu (Replay).

### Chức năng mở rộng

* Hệ thống xếp hạng (ELO)
* Leaderboard
* Chơi với AI (Stockfish)
* Tạo phòng riêng
* Chế độ khán giả (Observer)

### Yêu cầu phi chức năng (Non-functional)

| Yêu cầu          | Mục tiêu                           |
| ---------------- | ---------------------------------- |
| Latency          | < 100ms                            |
| Concurrent Users | ≥ 1.000 CCU                        |
| Scalability      | Hỗ trợ Scale-out                   |
| Security         | Server xác thực toàn bộ logic game |

### Edge Cases

* Người chơi mất kết nối giữa trận.
* Hai người chơi thực hiện nước đi gần như cùng lúc.
* Spam request nhằm gây quá tải server.

---

# 2. Thiết kế kiến trúc hệ thống (System Architecture)

## Kiến trúc tổng thể

```text
                 Flutter Client
                       │
        ┌──────────────┴──────────────┐
        │                             │
 REST API (HTTP)              SignalR (WebSocket)
        │                             │
        └──────────────┬──────────────┘
                       │
            ASP.NET Core Backend
                       │
        ┌──────────────┴──────────────┐
        │                             │
    PostgreSQL / SQL Server        Redis
```

### Client

* Flutter
* Hỗ trợ Android và iOS.
* UI thống nhất.
* Hiệu năng animation tốt cho game bàn cờ.

### Backend

#### REST API

Sử dụng ASP.NET Core Web API.

Chịu trách nhiệm:

* Authentication
* User Profile
* Match History
* Các tác vụ Stateless

#### Real-time

Sử dụng SignalR.

Chịu trách nhiệm:

* Matchmaking
* Đồng bộ nước đi
* Đồng hồ
* Sự kiện trong trận đấu

### Database

#### PostgreSQL / SQL Server

Lưu trữ dữ liệu:

* User
* Match
* History

#### Redis

Lưu dữ liệu tạm thời:

* Matchmaking Queue
* Trạng thái trận đấu
* Session người chơi

### Trade-off

Server phải xác thực toàn bộ nước đi.

Ưu điểm:

* Chống gian lận.
* Client không thể sửa luật.

Nhược điểm:

* Tăng tải CPU.

Đây là sự đánh đổi cần thiết trong game online.

---

# 3. Cấu trúc dự án (Project Structure)

## Flutter

```text
client/
│
├── core/
│
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   │
│   ├── matchmaking/
│   │
│   └── gameplay/
│
└── main.dart
```

### Presentation

* UI
* Widgets
* Riverpod / Bloc

### Domain

* Entities
* Use Cases

### Data

* Repository
* API
* SignalR

---

## ASP.NET Core

```text
server/
│
├── SeaChess.API
│
├── SeaChess.Application
│
├── SeaChess.Domain
│
├── SeaChess.Infrastructure
│
└── SeaChess.Tests
```

### Domain

* Entities
* Value Objects
* Enums
* Game Engine

### Application

* DTO
* Interfaces
* CQRS
* Use Cases

### Infrastructure

* Entity Framework Core
* Redis
* Third-party Services

### API

* Controllers
* SignalR Hub
* Middleware
* Dependency Injection

---

# 4. Thiết kế cơ sở dữ liệu

## Users

| Cột          | Kiểu dữ liệu |
| ------------ | ------------ |
| Id           | Guid         |
| Username     | string       |
| PasswordHash | string       |
| Email        | string       |
| Elo          | int          |
| CreatedAt    | DateTime     |

---

## Matches

| Cột           | Kiểu dữ liệu |
| ------------- | ------------ |
| Id            | Guid         |
| WhitePlayerId | Guid         |
| BlackPlayerId | Guid         |
| StartTime     | DateTime     |
| EndTime       | DateTime     |
| Result        | Enum         |
| PGN           | text         |

---

## Moves (Tùy chọn)

| Cột          | Kiểu dữ liệu |
| ------------ | ------------ |
| MatchId      | Guid         |
| MoveNumber   | int          |
| MoveNotation | string       |
| TimeTaken    | int          |

---

# 5. Thiết kế Game Engine & Realtime

## FEN

Trạng thái bàn cờ được lưu bằng FEN.

Ví dụ:

```text
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

FEN giúp:

* Lưu trạng thái bàn cờ.
* Khôi phục trận đấu.
* Đồng bộ Client ↔ Server.

---

## Flow Realtime

```text
Player A
    │
    │ JoinMatchmaking()
    ▼
Server
    │
Redis Queue
    │
    ├─────────────► Ghép thành công
    │
    ▼
Tạo Match
    │
    ▼
Gửi MatchStarted(FEN)
    │
┌───────────────┐
│               │
▼               ▼
Player A     Player B
```

---

### Khi người chơi đi quân

```text
Player A
    │
    │ MakeMove(e2,e4)
    ▼
SignalR Hub
    │
Game Engine
    │
    ├── Kiểm tra hợp lệ
    │
    ├── Cập nhật FEN
    │
    └── Lưu PGN
    │
    ▼
MoveMade(e2,e4)
    │
┌───────────────┐
│               │
▼               ▼
Player A     Player B
```

Nếu nước đi không hợp lệ:

```text
Player
   │
   ▼
Server
   │
   ▼
MoveRejected
```

---

# 6. Roadmap

## Sprint 1 — Core Game Engine

* Thiết kế Board
* Move Generator
* Game State
* Unit Test

---

## Sprint 2 — Database & REST API

* Entity Framework Core
* Authentication
* User Management
* Match History

---

## Sprint 3 — Realtime & Matchmaking

* SignalR
* Redis Queue
* Đồng bộ trạng thái trận đấu

---

## Sprint 4 — Flutter Client

* Giao diện bàn cờ
* Kết nối API
* Kết nối SignalR
* Đồng bộ UI

---

## Sprint 5 — Polish

* Reconnect
* Đồng hồ
* Replay
* Stress Test
* Tối ưu hiệu năng
* Hoàn thiện sản phẩm
