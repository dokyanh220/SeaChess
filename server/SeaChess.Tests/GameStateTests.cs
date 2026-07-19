using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Domain.Services;
using SeaChess.Domain.ValueObjects;

namespace SeaChess.Tests
{
    public class GameStateTests
    {
        [Fact]
        public void IsInCheck_ShouldReturnTrue_WhenKingIsAttacked()
        {
            // Arrange
            // Setup một FEN tùy chỉnh: Vua Trắng ở e1, Xe Đen ở e8 không có ai cản đường
            string fen = "4r3/8/8/8/8/8/8/4K3 w - - 0 1";
            var board = new Board(fen);

            // Act
            bool isInCheck = GameStateAnalyzer.IsInCheck(board, PieceColor.White);

            // Assert
            Assert.True(isInCheck, "Vua Trắng phải đang trong trạng thái bị chiếu bởi Xe Đen");
        }

        [Fact]
        public void IsInCheck_ShouldReturnFalse_WhenKingIsSafe()
        {
            // Arrange
            // Setup FEN: Vua Trắng ở e1, nhưng có Tốt Trắng ở e2 che chắn trước mặt Xe Đen
            string fen = "4r3/8/8/8/8/8/4P3/4K3 w - - 0 1";
            var board = new Board(fen);

            // Act
            bool isInCheck = GameStateAnalyzer.IsInCheck(board, PieceColor.White);

            // Assert
            Assert.False(isInCheck, "Vua Trắng an toàn vì đã có quân Tốt che chắn");
        }

        [Fact]
        public void KingsideCastling_ShouldBeLegal_WhenPathIsEmpty()
        {
            // Arrange
            // White back rank: R N B Q K 2 R (F1 and G1 are empty)
            string fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQK2R w KQkq - 0 1";
            var board = new Board(fen);

            // Act
            var legalMoves = GameStateAnalyzer.GetLegalMoves(board, PieceColor.White);

            // Assert
            // White King is at e1 (4, 0). Kingside castling move is e1 -> g1 (4, 0 -> 6, 0)
            var kingPos = new Position(4, 0);
            var targetPos = new Position(6, 0);
            var castlingMove = legalMoves.FirstOrDefault(m => m.From == kingPos && m.To == targetPos);

            Assert.NotNull(castlingMove);
        }

        [Fact]
        public void QueensideCastling_ShouldBeLegal_WhenPathIsEmpty()
        {
            // Arrange
            // White back rank: R 3 K B N R (B1, C1, D1 are empty)
            string fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/R3KBNR w KQkq - 0 1";
            var board = new Board(fen);

            // Act
            var legalMoves = GameStateAnalyzer.GetLegalMoves(board, PieceColor.White);

            // Assert
            // White King is at e1 (4, 0). Queenside castling move is e1 -> c1 (4, 0 -> 2, 0)
            var kingPos = new Position(4, 0);
            var targetPos = new Position(2, 0);
            var castlingMove = legalMoves.FirstOrDefault(m => m.From == kingPos && m.To == targetPos);

            Assert.NotNull(castlingMove);
        }
    }
}