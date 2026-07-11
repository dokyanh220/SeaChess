using SeaChess.Domain.Enums;

namespace SeaChess.Application.DTOs.AI
{
    public static class StockfishConfig
    {
        public static (int SkillLevel, int Depth, int ThinkTimeMs) GetConfig(AiDifficulty difficulty)
        {
            return difficulty switch
            {
                AiDifficulty.Beginner => (0, 1, 100),     // Đi bậy, rất yếu
                AiDifficulty.Easy    => (3, 3, 200),      // Yếu, mắc lỗi cơ bản
                AiDifficulty.Medium  => (8, 6, 400),      // Trung bình
                AiDifficulty.Hard    => (14, 10, 800),    // Mạnh, ít sai lầm
                _ => (8, 6, 400)
            };
        }
    }
}