namespace SeaChess.Application.DTOs.Match
{
    public class MatchState
    {
        public string MatchID { get; set; } = string.Empty;
        public string WhitePlayerId { get; set; } = string.Empty;
        public string BlackPlayerId { get; set; } = string.Empty;
        public string CurrentFen { get; set; } = string.Empty;
        public long StartTimeUnix { get; set; }
    }
}