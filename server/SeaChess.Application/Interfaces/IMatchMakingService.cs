namespace SeaChess.Application.Interfaces
{
    public interface IMatchMakingService
    {
        Task JoinQueueAsync(string userId, int elo);

        Task LeaveQueueAsync(string userId);

        Task<string?> FindMatchAsync(string userId, int elo, int tolerence = 100);
    }
}