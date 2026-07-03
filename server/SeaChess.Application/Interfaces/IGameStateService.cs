using SeaChess.Application.DTOs.Match;

namespace SeaChess.Application.Interfaces
{
    public interface IGameStateService
    {
        Task SaveStateAsync(MatchState state);
        Task<MatchState?> GetStateAsync(string matchID);
    }
}