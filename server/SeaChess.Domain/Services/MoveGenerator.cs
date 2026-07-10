using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Domain.ValueObjects;

namespace SeaChess.Domain.Services
{
    public class MoveGenerator
    {
        // Khai báo hướng đi
        // Hướng thẳng
        private static readonly (int, int)[] StrainghtDirections = { (0, 1), (0, -1), (-1, 0), (1, 0) };
        // Hướng chéo
        private static readonly (int, int)[] DiagonalDirections = { (1, 1), (1, -1), (-1, 1), (-1, -1) };

        // Hướng chữ L của mã
        private static readonly (int, int)[] KnightMoves = { (1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2) };

        // Hướng của vua 1 ô mọi hướng
        private static readonly (int, int)[] KingMoves = { (0, 1), (0, -1), (-1, 0), (1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1) };

        public static List<Move> GetPseudoLegalMoves(Board board, Position startPos)
        {
            var moves = new List<Move>();
            if (!board.Squares.TryGetValue(startPos, out Piece? piece))
                return moves;

            switch (piece.Type)
            {
                
                case PieceType.Knight:
                    GenerateJumpMoves(board, startPos, piece.Color, KnightMoves, moves);
                    break;
                case PieceType.King:
                    GenerateJumpMoves(board, startPos, piece.Color, KingMoves, moves);
                    GenerateCastlingMoves(board, startPos, piece.Color, moves);
                    break;
                case PieceType.Rook:
                    GenerateSlidingMoves(board, startPos, piece.Color, StrainghtDirections, moves);
                    break;
                case PieceType.Bishop:
                    GenerateSlidingMoves(board, startPos, piece.Color, DiagonalDirections, moves);
                    break;
                case PieceType.Queen:
                    GenerateSlidingMoves(board, startPos, piece.Color, StrainghtDirections, moves);
                    GenerateSlidingMoves(board, startPos, piece.Color, DiagonalDirections, moves);
                    break;
                case PieceType.Pawn:
                    GeneratePawnMoves(board, startPos, piece.Color, moves);
                    break;
            }

            return moves;
        }

        // Mã và Vua
        private static void GenerateJumpMoves(Board board, Position startPos, PieceColor color, (int, int)[] partterns, List<Move> moves)
        {
            foreach (var (f, r) in partterns)
            {
                int targetFile = startPos.File + f;
                int targetRank = startPos.Rank + r;

                if (IsOnBoard(targetFile, targetRank))
                {
                    var targetPos = new Position(targetFile, targetRank);
                    if (!board.Squares.ContainsKey(targetPos) || board.Squares[targetPos].Color != color)
                    {
                        moves.Add(new Move(startPos, targetPos));
                    }
                }
            }
        }

        // Nhập thành
        private static void GenerateCastlingMoves(Board board, Position startPos, PieceColor color, List<Move> moves)
        {
            if (board.CastlingRights == "-") return;

            int rank = color == PieceColor.White ? 0 : 7;
            char kingSideChar = color == PieceColor.White ? 'K' : 'k';
            char queenSideChar = color == PieceColor.White ? 'Q' : 'q';

            if (board.CastlingRights.Contains(kingSideChar))
            {
                if (!board.Squares.ContainsKey(new Position(5, rank)) &&
                    !board.Squares.ContainsKey(new Position(6, rank)))
                {
                    moves.Add(new Move(startPos, new Position(6, rank)));
                }
            }

            if (board.CastlingRights.Contains(queenSideChar))
            {
                if (!board.Squares.ContainsKey(new Position(1, rank)) &&
                    !board.Squares.ContainsKey(new Position(2, rank)) &&
                    !board.Squares.ContainsKey(new Position(3, rank)))
                {
                    moves.Add(new Move(startPos, new Position(2, rank)));
                }
            }
        }

        // Xe, Tượng, Hậu
        private static void GenerateSlidingMoves(Board board, Position startPos, PieceColor color, (int, int)[] directions, List<Move> moves)
        {
            foreach (var (df, dr) in directions)
            {
                int currentFile = startPos.File + df;
                int currentRank = startPos.Rank + dr;

                while (IsOnBoard(currentFile, currentRank))
                {
                    var targetPos = new Position(currentFile, currentRank);
                    if (!board.Squares.ContainsKey(targetPos))
                    {
                        moves.Add(new Move(startPos, targetPos));
                    }
                    else
                    {
                        if (board.Squares[targetPos].Color != color)
                        {
                            if (board.Squares[targetPos].Color != color)
                            {
                                moves.Add(new Move(startPos, targetPos));
                            }
                        }
                        break;
                    }

                    currentFile += df;
                    currentRank += dr;
                }
            }
        }

        // Tốt
        private static void GeneratePawnMoves(Board board, Position startPos, PieceColor color, List<Move> moves)
        {
            int direction = color == PieceColor.White ? 1 : -1;
            int startRank = color == PieceColor.White ? 1 : 6;

            int promotionRank = color == PieceColor.White ? 7 : 0;

            int forward1Rank = startPos.Rank + direction;
            if (IsOnBoard(startPos.File, forward1Rank))
            {
                var forward1Pos = new Position(startPos.File, forward1Rank);

                if (!board.Squares.ContainsKey(forward1Pos))
                {
                    moves.Add(new Move(startPos, forward1Pos));

                    // Bắt đầu 2 bước
                    if (startPos.Rank == startRank)
                    {
                        int forward2Rank = startPos.Rank + 2 * direction;
                        var forward2Pos = new Position(startPos.File, forward2Rank);

                        if (!board.Squares.ContainsKey(forward2Pos))
                        {
                            moves.Add(new Move(startPos, forward2Pos));
                        }
                    }
                }
            }

            int[] captureFiles = { startPos.File - 1, startPos.File + 1 };
            foreach (var file in captureFiles)
            {
                if (IsOnBoard(file, forward1Rank))
                {
                    var capturePos = new Position(file, forward1Rank);

                    bool isNormalCapture = board.Squares.TryGetValue(capturePos, out Piece? targetPiece) && targetPiece.Color != color;
                    bool isEnPassant = board.EnPassantTarget != null && capturePos == board.EnPassantTarget;

                    if (isNormalCapture || isEnPassant)
                    {
                        AddPawnMove(startPos, capturePos, forward1Rank == promotionRank, moves);
                    }
                }
            }
        }

        // Check quân trên bàn
        private static bool IsOnBoard(int file, int rank)
        {
            return file >= 0 && file < 8 && rank >= 0 && rank < 8;
        }

        // Phong Tốt
        private static void AddPawnMove(Position start, Position target, bool isPromotion, List<Move> moves)
        {
            if (isPromotion)
            {
                moves.Add(new Move(start, target, PieceType.Queen));
                moves.Add(new Move(start, target, PieceType.Knight));
                moves.Add(new Move(start, target, PieceType.Rook));
                moves.Add(new Move(start, target, PieceType.Bishop));
            }
            else
            {
                moves.Add(new Move(start, target));
            }
        }
    }
}