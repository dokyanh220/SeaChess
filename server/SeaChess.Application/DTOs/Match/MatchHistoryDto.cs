using System;
using SeaChess.Domain.Enums;

namespace SeaChess.Application.DTOs.Match
{
    public class MatchHistoryDto
    {
        public Guid Id { get; set; }
        public string OpponentName { get; set; } = string.Empty;
        public int OpponentElo { get; set; }
        public MatchResult Result { get; set; }
        public bool IsWhite { get; set; }
        public bool IsAiGame { get; set; }
        public AiDifficulty? AiDifficulty { get; set; }
        public string? PGN { get; set; }
        public DateTime CreatedAt { get; set; }
        public int InitialTimeSeconds { get; set; }
    }
}
