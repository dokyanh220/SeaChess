using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;

namespace SeaChess.Test
{
    public class BoardTests
    {
        [Fact]
        public void LoadFromFen_ShouldParseDefaultStartingPositionCorrectly()
        {
            // Arrange
            // Khởi tạo bàn cờ với FEN mặc định ban đầu:
            // "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
            var board = new Board();

            // Act & Assert
            // 1. Kiểm tra lượt đi
            Assert.Equal(PieceColor.White, board.ActiveColor);
            
            // 2. Kiểm tra quyền nhập thành và các thông số khác
            Assert.Equal("KQkq", board.CastlingRights);
            Assert.Null(board.EnPassantTarget);
            Assert.Equal(0, board.HalfmoveClock);
            Assert.Equal(1, board.FullmoveNumber);
            
            // 3. Kiểm tra số lượng quân cờ (Phải đủ 32 quân ở trạng thái đầu game)
            Assert.Equal(32, board.Squares.Count);
        }
    }
}