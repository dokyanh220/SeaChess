using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Domain.ValueObjects;

namespace SeaChess.Domain.Services
{
    public class GameStateAnalyzer
    {
        // Check chiếu
        public static bool IsInCheck(Board board, PieceColor color)
        {
            Position? kingPosition = null;

            foreach (var square in board.Squares)
            {
                if (square.Value.Color == color && square.Value.Type == PieceType.King)
                {
                    kingPosition = square.Key;
                    break;
                }
            }

            if (kingPosition == null) return false;

            PieceColor opponetColor = color == PieceColor.White ? PieceColor.Black : PieceColor.White;

            foreach (var square in board.Squares)
            {
                if (square.Value.Color == opponetColor)
                {
                    var opponetMoves = MoveGenerator.GetPseudoLegalMoves(board, square.Key);
                    if (opponetMoves.Any(m => m.To == kingPosition))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        // Check nước đi của đối thủ(vua không bị chiếu)
        public static List<Move> GetLegalMoves(Board board, PieceColor color)
        {
            var legalMoves = new List<Move>();

            foreach (var square in board.Squares.Where(s => s.Value.Color == color))
            {
                var pseudoMoves = MoveGenerator.GetPseudoLegalMoves(board, square.Key);
                
                foreach (var move in pseudoMoves)
                {
                    legalMoves.Add(move);
                }
            }

            return legalMoves;
        }

        // State chiếu hết
        public static bool IsCheckmate(Board board, PieceColor color)
        {
            return IsInCheck(board, color) && GetLegalMoves(board, color).Count == 0;
        }

        // State hòa
        public static bool IsStalemate(Board board, PieceColor color)
        {
            return !IsInCheck(board, color) && GetLegalMoves(board, color).Count == 0;
        }

        // State hòa cờ 50 nước
        public static bool IsFiftyMoveRule(Board board)
        {
            return board.HalfmoveClock >= 100;
        }

        // Todo: Luật hòa lặp lại 3 lần
        // Todo: Đi thử
    }
}