namespace SeaChess.Domain.Enums
{
    public enum MatchResult : short
    {
        Pending = 0,
        WhiteWin = 1,
        BlackWin = 2,
        Draw = 3,
        Aborted = 4,
    }
}