# Sprint 2: Database & REST API

> **Mục tiêu:** Thiết lập cơ sở dữ liệu, tích hợp Entity Framework Core, xây dựng hệ thống xác thực (Authentication), REST API và khởi tạo Redis làm nền tảng cho các Sprint tiếp theo.

| Task | Tên công việc | Mô tả |
|------|---------------|--------|
| 2.1 | **Thiết kế Database Schema** | Phân tích yêu cầu và thiết kế schema cho các bảng **Users** và **Matches**, bao gồm khóa chính, khóa ngoại, chỉ mục (Indexes) và các ràng buộc dữ liệu (Constraints). |
| 2.2 | **Tích hợp Entity Framework Core** | Cài đặt Entity Framework Core trong project **Infrastructure**, cấu hình `DbContext`, Mapping, Migration và kết nối đến SQL Server. |
| 2.3 | **Xây dựng Authentication** | Phát triển hệ thống xác thực gồm **Đăng ký** và **Đăng nhập**, mã hóa mật khẩu bằng BCrypt, xác thực bằng JWT và phân quyền cơ bản. |
| 2.4 | **Xây dựng REST API** | Tạo các Controller và Service để cung cấp API quản lý thông tin người chơi như xem hồ sơ, cập nhật hồ sơ và lấy dữ liệu người dùng. |
| 2.5 | **Khởi tạo Redis** | Cấu hình kết nối Redis, xây dựng lớp Redis Service và kiểm tra khả năng đọc/ghi dữ liệu để chuẩn bị cho hệ thống Matchmaking và Cache ở các Sprint sau. |

---

## Deliverables

- Thiết kế Database hoàn chỉnh.
- Entity Framework Core hoạt động với Migration.
- Hệ thống Authentication bằng JWT.
- REST API cho User Info.
- Redis được tích hợp và kết nối thành công.

---

## Công nghệ sử dụng

- ASP.NET Core Web API
- Entity Framework Core
- SQL Server
- Redis
- JWT Authentication
- BCrypt Password Hashing
- Clean Architecture