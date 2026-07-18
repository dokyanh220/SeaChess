using System;
using SeaChess.Domain.Enums;

namespace SeaChess.Application.DTOs.Match
{
    public class AiMatchResultDto
    {
        public AiDifficulty Difficulty { get; set; }
        public PieceColor PlayerColor { get; set; }
        public MatchResult Result { get; set; }
        public int InitialTimeSeconds { get; set; }
        public string? Pgn { get; set; }
    }

    public class AiMatchResultResponse
    {
        public int EloChange { get; set; }
        public int XpChange { get; set; }
        public int NewElo { get; set; }
        public int NewLevel { get; set; }
        public int NewExperience { get; set; }
    }
}
