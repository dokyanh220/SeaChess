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

        // Kiểm tra nước đi
        public static bool ValidateMove(Board board, Position from, Position to, PieceColor playerColor)
        {
            // 1. Kiểm tra xem ô xuất phát có quân cờ của người chơi không
            if (!board.Squares.TryGetValue(from, out var piece) || piece.Color != playerColor)
                return false;

            // 2. Lấy tất cả các nước đi hợp lệ tuyệt đối (Legal Moves) của quân cờ này
            var legalMoves = GetLegalMoves(board, playerColor);

            // 3. Kiểm tra xem nước đi Client gửi lên có nằm trong danh sách Legal Moves không
            return legalMoves.Any(m => m.From == from && m.To == to);
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
        
        // Todo: Đi thử
    }
}