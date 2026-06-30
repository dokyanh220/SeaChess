using SeaChess.Domain.Enums;

namespace SeaChess.Domain.ValueObjects
{
    public record Piece(PieceColor Color, PieceType Type);
}