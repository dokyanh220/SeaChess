using SeaChess.Domain.Enums;

namespace SeaChess.Application.DTOs.Match
{
    public class MatchState
    {
        public string MatchID { get; set; } = string.Empty;
        public string WhitePlayerId { get; set; } = string.Empty;
        public string BlackPlayerId { get; set; } = string.Empty;
        public string CurrentFen { get; set; } = string.Empty;
        public string Status { get; set; } = "Playing";

        // Quản lý thời gian
        public double WhiteTimeLeftMs { get; set; } 
        public double BlackTimeLeftMs { get; set; }

        // Mốc thời gian đối chiếu
        public DateTimeOffset LastMoveTime { get; set; }
        public bool IsAiGame { get; set; } = false;
        public AiDifficulty? AiDifficulty { get; set; }
        public PieceColor? AiColor { get; set; }
    }
}