# Thiết kế cơ sở dữ liệu

## Thông tin chung

- **Dự án:** SeaChess
- **Hệ quản trị CSDL:** PostgreSQL
- **ORM:** Entity Framework Core
- **DbContext:** `ApplicationDbContext`
- **Cơ chế xác thực:** Custom Authentication + JWT
- **Kiểu định danh chính:** `Guid` ánh xạ sang `uuid`

Tài liệu này mô tả các bảng đang được khai báo trong tầng Domain và cấu hình bằng EF Core ở tầng Infrastructure.

---

## 1. Bảng `Users`

Lưu thông tin tài khoản, hồ sơ người chơi, điểm xếp hạng và thống kê thi đấu.

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| --- | --- | --- | --- |
| `Id` | `uuid` | Primary key | Định danh duy nhất của người dùng. |
| `Username` | `varchar(50)` | Required, unique index | Tên đăng nhập. |
| `DisplayName` | `text` | Required theo entity | Tên hiển thị trong game. |
| `Email` | `varchar(100)` | Required, unique index | Email đăng ký tài khoản. |
| `PasswordHash` | `text` | Required theo entity | Mật khẩu đã được hash. |
| `AvatarUrl` | `text` | Nullable | Đường dẫn ảnh đại diện. |
| `TotalMatches` | `integer` | Default `0` | Tổng số trận đã chơi. |
| `Experience` | `integer` | Default `0` | Điểm kinh nghiệm của người chơi. |
| `Wins` | `integer` | Default `0` | Số trận thắng. |
| `Loses` | `integer` | Default `0` | Số trận thua. |
| `Draw` | `integer` | Default `0` | Số trận hòa. |
| `Elo` | `integer` | Default `799`, indexed | Điểm xếp hạng hiện tại. |
| `EmailVerified` | `boolean` | Default `false` | Trạng thái xác thực email. |
| `IsActive` | `boolean` | Default `true` | Trạng thái hoạt động của tài khoản. |
| `CreatedAt` | `timestamp with time zone` | Default `DateTime.UtcNow` | Thời điểm tạo tài khoản. |
| `UpdatedAt` | `timestamp with time zone` | Nullable | Thời điểm cập nhật gần nhất. |

### Index

| Index | Loại | Mục đích |
| --- | --- | --- |
| `Username` | Unique | Không cho phép trùng tên đăng nhập. |
| `Email` | Unique | Không cho phép trùng email. |
| `Elo` | Non-unique | Hỗ trợ truy vấn/xếp hạng theo Elo. |

---

## 2. Bảng `Matches`

Lưu lịch sử trận đấu, người chơi hai bên, kết quả và dữ liệu ván cờ.

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| --- | --- | --- | --- |
| `Id` | `uuid` | Primary key | Định danh duy nhất của trận đấu. |
| `WhitePlayerId` | `uuid` | Foreign key đến `Users.Id`, required | Người chơi quân trắng. |
| `BlackPlayerId` | `uuid` | Foreign key đến `Users.Id`, required | Người chơi quân đen. |
| `Result` | `smallint` | Default `0` | Kết quả trận đấu, ánh xạ từ `MatchResult`. |
| `InitialTimeSeconds` | `integer` | Required | Thời gian ban đầu của ván, tính bằng giây. |
| `IsRated` | `boolean` | Default `true` | Trận có tính điểm Elo hay không. |
| `PGN` | `text` | Nullable | Chuỗi lưu lịch sử nước đi theo định dạng PGN hoặc tương đương. |
| `StartTime` | `timestamp with time zone` | Default `DateTime.UtcNow` | Thời điểm bắt đầu trận. |
| `EndTime` | `timestamp with time zone` | Nullable | Thời điểm kết thúc trận. |
| `CreatedAt` | `timestamp with time zone` | Default `DateTime.UtcNow` | Thời điểm tạo bản ghi. |

### Quan hệ và index

| Thành phần | Cấu hình |
| --- | --- |
| `WhitePlayerId -> Users.Id` | `OnDelete(DeleteBehavior.Restrict)` |
| `BlackPlayerId -> Users.Id` | `OnDelete(DeleteBehavior.Restrict)` |
| Index | `WhitePlayerId`, `BlackPlayerId` |

`Restrict` được dùng để tránh xóa người dùng khi vẫn còn lịch sử trận đấu liên quan.

---

## 3. Bảng `Friendships`

Quản lý lời mời kết bạn và trạng thái quan hệ giữa hai người dùng.

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| --- | --- | --- | --- |
| `Id` | `uuid` | Primary key | Định danh duy nhất của quan hệ. |
| `RequesterId` | `uuid` | Foreign key đến `Users.Id`, required | Người gửi lời mời kết bạn. |
| `ReceiverId` | `uuid` | Foreign key đến `Users.Id`, required | Người nhận lời mời kết bạn. |
| `Status` | `smallint` | Default `0` | Trạng thái quan hệ, ánh xạ từ `FriendshipStatus`. |
| `CreatedAt` | `timestamp with time zone` | Default `DateTime.UtcNow` | Thời điểm tạo lời mời. |
| `UpdatedAt` | `timestamp with time zone` | Nullable | Thời điểm cập nhật trạng thái gần nhất. |

### Quan hệ

| Thành phần | Cấu hình |
| --- | --- |
| `RequesterId -> Users.Id` | `OnDelete(DeleteBehavior.Restrict)` |
| `ReceiverId -> Users.Id` | `OnDelete(DeleteBehavior.Restrict)` |

---

## 4. Bảng `Notifications`

Lưu thông báo hệ thống và thông báo tương tác giữa người chơi.

| Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
| --- | --- | --- | --- |
| `Id` | `uuid` | Primary key | Định danh duy nhất của thông báo. |
| `UserId` | `uuid` | Foreign key đến `Users.Id`, required | Người nhận thông báo. |
| `SenderId` | `uuid` | Foreign key đến `Users.Id`, nullable | Người gửi thông báo; `null` nếu là thông báo hệ thống. |
| `Type` | `smallint` | Required | Loại thông báo, ánh xạ từ `NotificationType`. |
| `Title` | `varchar(100)` | Required | Tiêu đề thông báo. |
| `Content` | `text` | Required theo entity | Nội dung thông báo. |
| `ReferenceId` | `uuid` | Nullable | Id tham chiếu đến đối tượng liên quan, ví dụ trận đấu hoặc lời mời kết bạn. |
| `IsRead` | `boolean` | Default `false` | Người dùng đã đọc thông báo hay chưa. |
| `CreatedAt` | `timestamp with time zone` | Default `DateTime.UtcNow` | Thời điểm tạo thông báo. |
| `ReadAt` | `timestamp with time zone` | Nullable | Thời điểm thông báo được đọc. |

### Quan hệ và index

| Thành phần | Cấu hình |
| --- | --- |
| `UserId -> Users.Id` | `OnDelete(DeleteBehavior.Cascade)` |
| `SenderId -> Users.Id` | `OnDelete(DeleteBehavior.SetNull)` |
| Index | `UserId`, `SenderId` |

Khi người nhận bị xóa, thông báo của họ cũng bị xóa theo. Khi người gửi bị xóa, `SenderId` được đặt về `null` để vẫn giữ được thông báo.

---

## 5. Enum

Các enum được lưu bằng số nguyên nhỏ (`smallint`) trong database.

### `MatchResult`

| Giá trị | Tên | Ý nghĩa |
| --- | --- | --- |
| `0` | `Pending` | Trận đang chờ hoặc đang diễn ra. |
| `1` | `WhiteWin` | Quân trắng thắng. |
| `2` | `BlackWin` | Quân đen thắng. |
| `3` | `Draw` | Hòa. |
| `4` | `Aborted` | Trận bị hủy. |

### `FriendshipStatus`

| Giá trị | Tên | Ý nghĩa |
| --- | --- | --- |
| `0` | `Pending` | Đang chờ phản hồi. |
| `1` | `Accepted` | Đã chấp nhận. |
| `2` | `Rejected` | Đã từ chối. |
| `3` | `Blocked` | Đã chặn. |

### `NotificationType`

| Giá trị | Tên | Ý nghĩa |
| --- | --- | --- |
| `0` | `System` | Thông báo hệ thống. |
| `1` | `FriendRequest` | Lời mời kết bạn. |
| `2` | `MatchInvite` | Lời mời thi đấu. |

---

## 6. Migration hiện có

| Migration | Nội dung chính |
| --- | --- |
| `20260701121417_InitialCreate` | Tạo các bảng `Users`, `Matches`, `Friendships`, `Notifications`. |
| `20260701124410_UpdateUserEntity_StatsAndAvatar` | Thêm `AvatarUrl`, `TotalMatches`, `Wins`, `Loses`, `Draw` vào `Users`. |
| `20260701153535_Update_ExpLevelUser` | Thêm `Experience` vào `Users`. |

---

## 7. Ghi chú triển khai

- Cấu hình database nằm trong `SeaChess.Infrastructure/Data/ApplicationDbContext.cs`.
- Chuỗi kết nối được đọc từ `ConnectionStrings:DefaultConnection`.
- Các giá trị mặc định như `Elo`, `IsActive`, `CreatedAt` đang được đặt ở entity C#, không phải tất cả đều là default constraint ở database.
- Khi thêm hoặc sửa entity, cần tạo migration mới để đồng bộ schema:

```powershell
dotnet ef migrations add <MigrationName> --project server/SeaChess.Infrastructure --startup-project server/SeaChess.API
dotnet ef database update --project server/SeaChess.Infrastructure --startup-project server/SeaChess.API
```
