using SeaChess.Domain.Enums;
using SeaChess.Domain.ValueObjects;

namespace SeaChess.Domain.Entities
{
    public class Move
    {
        public Position From { get; }
        public Position To { get; }

        public PieceType? PromotionPice { get; }

        public Move(Position from, Position to, PieceType? promotionPiece = null)
        {
            From = from;
            To = to;
            PromotionPice = promotionPiece;
        }
    }
}