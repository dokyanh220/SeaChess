using SeaChess.Domain.Enums;

namespace SeaChess.Application.Interfaces
{
    public interface IStockfishService : IDisposable
    {
        Task<string> GetBestMoveAsync(string fen, AiDifficulty difficulty);
    }
}