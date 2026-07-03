# 3. Cơ Chế Ghép Trận Qua Redis Sorted Set

Để giải quyết triệt để bài toán nghẽn cổ chai (**Bottleneck**) khi hàng vạn người chơi cùng bấm tìm trận, hệ thống không truy vấn trực tiếp cơ sở dữ liệu **PostgreSQL**. Thay vào đó, toàn bộ hàng đợi tìm trận được xử lý trên bộ nhớ RAM thông qua cấu trúc dữ liệu **Sorted Set (ZSET)** của Redis nhằm đảm bảo tốc độ truy xuất và khả năng mở rộng.

## 3.1. Cấu trúc dữ liệu hàng đợi (Queue)

- **Redis Key:** `matchmaking_queue`
- **Score:** Chỉ số **ELO** của người chơi, dùng để Redis tự động sắp xếp.
- **Member:** `UserId` của người chơi (lấy từ JWT Token).

## 3.2. Thuật toán tìm kiếm và ghép cặp

Khi người chơi yêu cầu tìm trận, hệ thống sẽ tìm các người chơi có mức ELO nằm trong khoảng dung sai (**Tolerance**) mặc định là **±100** điểm bằng phương thức `SortedSetRangeByScoreAsync()`.

## 3.3. Đảm bảo tính toàn vẹn (Chống Race Condition)

Trong môi trường có lượng truy cập lớn (**High Concurrency**), nhiều người chơi có thể đồng thời chọn cùng một đối thủ trong hàng chờ. Để ngăn hiện tượng này, hệ thống sử dụng **Redis Transaction (MULTI/EXEC)**.

Nếu cả hai người chơi được xóa khỏi hàng đợi thành công trong cùng một giao dịch nguyên tử (**Atomic Transaction**), trận đấu mới được xác nhận.

```csharp
public async Task<string?> FindMatchAsync(string userId, int elo, int tolerance = 100)
{
    var minElo = elo - tolerance;
    var maxElo = elo + tolerance;

    // Lấy tối đa 2 ứng viên phù hợp
    var potentialMatches = await _redisDb.SortedSetRangeByScoreAsync(
        "matchmaking_queue",
        minElo,
        maxElo,
        take: 2);

    foreach (var match in potentialMatches)
    {
        var matchId = match.ToString();

        if (matchId != userId)
        {
            // Transaction đảm bảo thao tác nguyên tử
            var tran = _redisDb.CreateTransaction();

            tran.SortedSetRemoveAsync("matchmaking_queue", userId);
            tran.SortedSetRemoveAsync("matchmaking_queue", matchId);

            if (await tran.ExecuteAsync())
            {
                return matchId;
            }
        }
    }

    return null;
}
```

---

# 4. Quản Lý Trạng Thái Trận Đấu (Match State)

## 4.1. Cấu trúc thực thể MatchState

Sau khi ghép trận thành công, trạng thái của ván cờ được đóng gói thành một đối tượng JSON và lưu trong Redis dưới dạng **String Key**.

- **Redis Key:** `match_state:{matchId}`
- **TTL:** 2 giờ (tự động dọn dẹp nếu trận đấu không được xóa đúng cách).

```csharp
public class MatchState
{
    public string MatchId { get; set; } = string.Empty;

    public string WhitePlayerId { get; set; } = string.Empty;

    public string BlackPlayerId { get; set; } = string.Empty;

    // Chuỗi FEN biểu diễn toàn bộ trạng thái bàn cờ
    public string CurrentFen { get; set; } = string.Empty;

    public long StartTimeUnix { get; set; }
}
```

## 4.2. Phân bổ màu quân cờ

Để đảm bảo tính công bằng, màu quân cờ được quyết định ngẫu nhiên ngay khi tạo trận.

```csharp
var isUserWhite = Random.Shared.Next(2) == 0;

matchState.WhitePlayerId = isUserWhite ? userId : opponentId;
matchState.BlackPlayerId = isUserWhite ? opponentId : userId;
```

---

# 5. Luồng Xử Lý Nước Đi Realtime (Authoritative Server)

SeaChess áp dụng mô hình **Authoritative Server**, trong đó Server chịu trách nhiệm xác thực toàn bộ nước đi nhằm chống gian lận.

Client chỉ gửi thông tin nước đi, mọi xử lý đều được thực hiện phía Server.

## 5.1. Quy trình xử lý

1. Client gửi yêu cầu:

   ```text
   MakeMove(matchId, "e2", "e4", promotionPiece)
   ```

2. `ChessHub` nhận request.

3. Đọc `MatchState` từ Redis.

4. Khởi tạo bàn cờ từ chuỗi FEN.

5. Chuyển đổi tọa độ `"e2"` và `"e4"` thành đối tượng `Position`.

6. `GameStateAnalyzer` kiểm tra:
   - Người chơi có đúng lượt đi không.
   - Nước đi có thuộc danh sách **Legal Moves** hay không.

7. Nếu hợp lệ:

   - Thực hiện:

     ```csharp
     board.MakeMove(from, to, promotion);
     ```

   - Sinh FEN mới:

     ```csharp
     board.ToFenString();
     ```

   - Ghi đè FEN mới vào Redis.

8. Gửi trạng thái mới cho đối thủ:

```csharp
await Clients.User(opponentId)
    .SendAsync("ReceiveMove", newFen);
```

---

## 5.2. Hàm ValidateMove

```csharp
public static bool ValidateMove(
    Board board,
    Position from,
    Position to,
    PieceColor playerColor)
{
    // Kiểm tra quân cờ tại ô xuất phát
    if (!board.Squares.TryGetValue(from, out var piece) ||
        piece.Color != playerColor)
    {
        return false;
    }

    // Lấy danh sách nước đi hợp lệ
    var legalMoves = GetLegalMoves(board, playerColor);

    // Đối chiếu nước đi
    return legalMoves.Any(m =>
        m.From == from &&
        m.To == to);
}
```

---

# 6. Tiêu Chí Hoàn Thành (Definition of Done)

- Toàn bộ kết nối WebSocket đều phải xác thực bằng JWT hợp lệ.
- Người dùng không có Token sẽ bị từ chối kết nối ngay tại Gateway.
- Thuật toán ghép trận hoạt động ổn định trong môi trường nhiều người dùng đồng thời.
- Không xảy ra hiện tượng một người chơi bị ghép vào nhiều trận nhờ Redis Transaction.
- Nước đi không hợp lệ hoặc bị chỉnh sửa từ Client sẽ bị Server từ chối.
- Trạng thái ván cờ được cập nhật chính xác trên Redis sau mỗi nước đi.
- Đối thủ nhận được trạng thái mới theo thời gian thực thông qua SignalR.
- Toàn bộ quy trình hoạt động xuyên suốt:

```text
Tìm trận
    ↓
Ghép cặp
    ↓
Khởi tạo MatchState
    ↓
Lưu Redis
    ↓
Đánh cờ
    ↓
Validate
    ↓
Cập nhật FEN
    ↓
Broadcast qua SignalR
```

- Các chức năng chính đạt tỷ lệ bao phủ kiểm thử (**Unit Test**) theo yêu cầu của hệ thống.