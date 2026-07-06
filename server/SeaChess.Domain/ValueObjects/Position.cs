namespace SeaChess.Domain.ValueObjects
{
    // File đại diện cột a-h, Rank hàng 1-8
    public record Position(int File, int Rank){
        public static Position Parse(string square)
        {
            if (string.IsNullOrWhiteSpace(square) || square.Length != 2)
                throw new ArgumentException("Invalid square.", nameof(square));

            int file = char.ToLowerInvariant(square[0]) - 'a';
            int rank = square[1] - '1';

            if (file < 0 || file > 7 || rank < 0 || rank > 7)
                throw new ArgumentOutOfRangeException(nameof(square));

            return new Position(file, rank);
        }
        public override string ToString() => $"{(char)('a' + File)}{Rank + 1}";
    }
}