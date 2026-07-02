using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SeaChess.API.Hubs
{
    [Authorize]
    public class ChessHub : Hub
    {
        public override async Task OnConnectedAsync()
        {
            // Tự động lấy userId từ Jwt Token
            Console.WriteLine($"[ChessHub] Client kết nối: {Context.ConnectionId}, UserId: {Context.UserIdentifier}");
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            Console.WriteLine($"[ChessHub] Client ngắn kết nối: {Context.ConnectionId}");
            // TODO:  Xử lý xóa user khỏi hàng đợi Redis nếu đang tìm trận
            await base.OnDisconnectedAsync(exception);
        }

        public async Task FindMatch()
        {
            Console.WriteLine($"[ChessHub] UserId: {Context.UserIdentifier} đang tìm trận...");
            // TODO: Logic 
        }

        public async Task CancelMatch() 
        {
            Console.WriteLine($"[ChessHub] UserId: {Context.UserIdentifier} Hủy tìm trận");
            // TODO: Logic 
        }

        public async Task MakeMove(string matchId, string fromPosition, string toPosition, string? promotionPiece)
         {
            Console.WriteLine($"[ChessHub] UserId {Context.UserIdentifier} đánh nước cờ tại trận {matchId}: {fromPosition} -> {toPosition}");
            // TODO: Logic
        }
    }
}