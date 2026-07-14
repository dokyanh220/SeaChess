using SeaChess.Application.DTOs.Match;

namespace SeaChess.Application.Interfaces
{
    public interface IGameStateService
    {
        Task SaveStateAsync(MatchState state);
        Task<MatchState?> GetStateAsync(string matchID);
        Task DeleteStateAsync(string matchID);

        /// <summary>Lưu matchId đang active của user (dùng khi bắt đầu trận)</summary>
        Task SetActiveMatchForUserAsync(string userId, string matchId);

        /// <summary>Lấy matchId đang active của user (dùng khi reconnect)</summary>
        Task<string?> GetActiveMatchForUserAsync(string userId);

        /// <summary>Xóa matchId active của user (dùng khi trận kết thúc)</summary>
        Task ClearActiveMatchForUserAsync(string userId);
    }
}