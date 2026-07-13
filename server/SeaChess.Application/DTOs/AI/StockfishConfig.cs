using SeaChess.Domain.Enums;

namespace SeaChess.Application.DTOs.AI
{
    public class AiSettings
    {
        public bool UseElo { get; set; }
        public int Elo { get; set; }
        public int SkillLevel { get; set; }
        public int Depth { get; set; }
        public int ThinkTimeMs { get; set; }
        public int RandomMoveChance { get; set; }
    }

    public static class StockfishConfig
    {
        public static AiSettings GetSettings(AiDifficulty difficulty)
        {
            return difficulty switch
            {
                // Rất ngáo, 50% đi bậy
                AiDifficulty.Beginner => new AiSettings { UseElo = true, Elo = 1320, SkillLevel = 0, Depth = 1, ThinkTimeMs = 100, RandomMoveChance = 50 },
                
                // Dễ, chỉ khó hơn beginner 1 chút (1350 Elo, sâu 2, không đi bậy)
                AiDifficulty.Easy => new AiSettings { UseElo = true, Elo = 1350, SkillLevel = 0, Depth = 2, ThinkTimeMs = 200, RandomMoveChance = 0 },
                
                // Medium: Vừa phải như một người chơi đồng cấp (~1500 Elo)
                AiDifficulty.Medium => new AiSettings { UseElo = true, Elo = 1500, SkillLevel = 3, Depth = 4, ThinkTimeMs = 400, RandomMoveChance = 0 },
                
                // Hard: Khó, giới hạn bằng Skill Level cao
                AiDifficulty.Hard => new AiSettings { UseElo = false, Elo = 0, SkillLevel = 14, Depth = 10, ThinkTimeMs = 800, RandomMoveChance = 0 },
                
                _ => new AiSettings { UseElo = true, Elo = 1500, SkillLevel = 3, Depth = 4, ThinkTimeMs = 400, RandomMoveChance = 0 }
            };
        }
    }
}