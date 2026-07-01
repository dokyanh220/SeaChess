using SeaChess.Domain.Enums;

namespace SeaChess.Domain.Entities
{
    public class Match
    {
        public Guid Id { get; set; }
        public Guid WhitePlayerId { get; set; }
        public Guid BlackPlayerId { get; set; }
        public MatchResult Result { get; set; } = MatchResult.Pending;
        public int InitialTimeSeconds { get; set; }
        public bool IsRated { get; set; } = true;
        public string? PGN { get; set; }
        public DateTime StartTime { get; set; } = DateTime.UtcNow;
        public DateTime? EndTime { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}