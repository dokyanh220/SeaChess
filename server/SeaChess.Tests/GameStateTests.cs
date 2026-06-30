using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Domain.Services;

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
    }
}