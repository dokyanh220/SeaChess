# (DATABASE DESIGN)

## Thông tin dự án

- **Dự án:** SeaChess
- **Hệ quản trị CSDL:** PostgreSQL (Host trên nền tảng Supabase)
- **ORM:** Entity Framework Core (EF Core)
- **Cơ chế xác thực:** Custom Authentication + JWT

---

# 1. Bảng `Users` (Người Chơi)

Quản lý thông tin tài khoản và trạng thái xác thực của người chơi.

| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
|----------|-------------|-----------|----------|
| Id | UUID | Primary Key | Định danh hệ thống. Sử dụng UUID để tăng tính bảo mật. |
| Username | VARCHAR(50) | UNIQUE, NOT NULL | Tên đăng nhập, không được trùng lặp. |
| DisplayName | VARCHAR(100) | NOT NULL | Tên hiển thị trong game. |
| Email | VARCHAR(100) | UNIQUE, NOT NULL | Email tài khoản. |
| PasswordHash | VARCHAR(255) | NOT NULL | Mật khẩu đã được băm. |
| Elo | INT | NOT NULL, DEFAULT 1200 | Điểm xếp hạng ban đầu. |
| EmailVerified | BOOLEAN | DEFAULT FALSE | Trạng thái xác thực email. |
| IsActive | BOOLEAN | DEFAULT TRUE | Trạng thái hoạt động của tài khoản. |
| CreatedAt | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Thời điểm tạo tài khoản. |
| UpdatedAt | TIMESTAMPTZ | NULL | Thời điểm cập nhật gần nhất. |

---

# 2. Bảng `Matches` (Lịch Sử Trận Đấu)

Lưu thông tin các trận đấu và kết quả.

| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
|----------|-------------|-----------|----------|
| Id | UUID | Primary Key | Định danh trận đấu. |
| WhitePlayerId | UUID | Foreign Key, NOT NULL | FK tới bảng `Users`. |
| BlackPlayerId | UUID | Foreign Key, NOT NULL | FK tới bảng `Users`. |
| Result | SMALLINT | NOT NULL, DEFAULT 0 | Kết quả trận đấu (`MatchResult`). |
| InitialTimeSeconds | INT | NOT NULL | Thời gian ban đầu (VD: `600` = 10 phút). |
| IsRated | BOOLEAN | DEFAULT TRUE | Có tính điểm ELO hay không. |
| PGN | TEXT | NULL | Lịch sử nước đi theo chuẩn Portable Game Notation (PGN). |
| StartTime | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Thời điểm bắt đầu trận đấu. |
| EndTime | TIMESTAMPTZ | NULL | Thời điểm kết thúc trận đấu. |
| CreatedAt | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Thời điểm tạo bản ghi. |

---

# 3. Bảng `Friendships` (Quan Hệ Bạn Bè)

Quản lý lời mời kết bạn và trạng thái kết bạn.

| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
|----------|-------------|-----------|----------|
| Id | UUID | Primary Key | Định danh quan hệ. |
| RequesterId | UUID | Foreign Key, NOT NULL | Người gửi lời mời kết bạn. |
| ReceiverId | UUID | Foreign Key, NOT NULL | Người nhận lời mời kết bạn. |
| Status | SMALLINT | NOT NULL | Trạng thái (`FriendshipStatus`). |
| CreatedAt | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Thời điểm gửi lời mời. |
| UpdatedAt | TIMESTAMPTZ | NULL | Thời điểm thay đổi trạng thái. |

---

# 4. Bảng `Notifications` (Thông Báo)

Lưu trữ các thông báo hệ thống và tương tác giữa người chơi.

| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
|----------|-------------|-----------|----------|
| Id | UUID | Primary Key | Định danh thông báo. |
| UserId | UUID | Foreign Key, NOT NULL | Người nhận thông báo. |
| SenderId | UUID | Foreign Key, NULL | Người gửi (NULL nếu là hệ thống). |
| Type | SMALLINT | NOT NULL | Loại thông báo (`NotificationType`). |
| Title | VARCHAR(100) | NOT NULL | Tiêu đề thông báo. |
| Content | TEXT | NOT NULL | Nội dung thông báo. |
| ReferenceId | UUID | NULL | Liên kết tới Match hoặc Friendship. |
| IsRead | BOOLEAN | DEFAULT FALSE | Đã đọc hay chưa. |
| CreatedAt | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Thời điểm tạo thông báo. |
| ReadAt | TIMESTAMPTZ | NULL | Thời điểm người dùng đọc thông báo. |

---

# 5. Enum (Từ Điển Dữ Liệu)

Các cột có kiểu `SMALLINT` sẽ được ánh xạ trực tiếp với các **C# Enum** trong tầng Domain.

## MatchResult

| Giá trị | Enum | Ý nghĩa |
|---------|------|----------|
| 0 | Pending | Đang chờ / Đang diễn ra |
| 1 | WhiteWin | Quân Trắng thắng |
| 2 | BlackWin | Quân Đen thắng |
| 3 | Draw | Hòa |
| 4 | Aborted | Trận đấu bị hủy |

---

## FriendshipStatus

| Giá trị | Enum | Ý nghĩa |
|---------|------|----------|
| 0 | Pending | Đang chờ xử lý |
| 1 | Accepted | Đã chấp nhận |
| 2 | Rejected | Đã từ chối |
| 3 | Blocked | Đã chặn |

---

## NotificationType

| Giá trị | Enum | Ý nghĩa |
|---------|------|----------|
| 0 | FriendRequest | Lời mời kết bạn |
| 1 | MatchInvite | Lời mời thi đấu |
| 2 | System | Thông báo từ hệ thống |