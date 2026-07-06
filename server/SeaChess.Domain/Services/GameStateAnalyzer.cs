using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Domain.ValueObjects;

namespace SeaChess.Domain.Services
{
    public class GameStateAnalyzer
    {
        // Check chiếu và trả về thông tin chi tiết
        public static (bool IsCheck, Position? KingPosition, List<Position> AttackerPositions) GetCheckInfo(Board board, PieceColor color)
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

            if (kingPosition == null) return (false, null, new List<Position>());

            PieceColor opponetColor = color == PieceColor.White ? PieceColor.Black : PieceColor.White;
            var attackers = new List<Position>();

            foreach (var square in board.Squares)
            {
                if (square.Value.Color == opponetColor)
                {
                    var opponetMoves = MoveGenerator.GetPseudoLegalMoves(board, square.Key);
                    if (opponetMoves.Any(m => m.To == kingPosition))
                    {
                        attackers.Add(square.Key);
                    }
                }
            }

            return (attackers.Count > 0, kingPosition, attackers);
        }

        public static bool IsInCheck(Board board, PieceColor color)
        {
            return GetCheckInfo(board, color).IsCheck;
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
                    // Đi thử
                    var cloneBoard = new Board(board.ToFenString());
                    cloneBoard.MakeMove(move.From, move.To, null);

                    if (!IsInCheck(cloneBoard, color))
                    {
                        legalMoves.Add(move);
                    }
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
    }
}