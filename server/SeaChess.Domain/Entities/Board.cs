using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SeaChess.Domain.Enums;
using SeaChess.Domain.ValueObjects;

namespace SeaChess.Domain.Entities
{
    public class Board
    {
        public Dictionary<Position, Piece> Squares { get; private set; }  = new();

        public PieceColor ActiveColor { get; private set; }

        public const string StartingFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

        public Board(string fen = StartingFen)
        {
            LoadFromFen(fen);
        }

        public string CastlingRights { get; private set; } = "-";
        public Position? EnPassantTarget { get; private set; }
        public int HalfmoveClock { get; private set; }
        public int FullmoveNumber { get; private set; }

        public void LoadFromFen(string fen)
        {
            Squares.Clear();
            var fenParts = fen.Split(' ');

            var boardLayout = fenParts[0];

            ActiveColor = fenParts[1] == "w" ? PieceColor.White : PieceColor.Black;

            int rank = 7;
            int file = 0;

            foreach (char c in boardLayout)
            {
                if (c == '/')
                {
                    rank--;
                    file = 0;
                }
                else if (char.IsDigit(c))
                {
                    file += (int)char.GetNumericValue(c);
                }
                else
                {
                    var pieceColor = char.IsUpper(c) ? PieceColor.White : PieceColor.Black;
                    var pieceType = GetPieceTypeFromChar(char.ToLower(c));

                    Squares[new Position(file, rank)] = new Piece(pieceColor, pieceType);
                    file++;
                }
            }

            if (fenParts.Length > 2)
            {
                CastlingRights = fenParts[2];
                EnPassantTarget = ParseFenPosition(fenParts[3]);
                HalfmoveClock = int.Parse(fenParts[4]);
                FullmoveNumber = int.Parse(fenParts[5]);
            }
        }

        public void MakeMove(Position from, Position to, string? promotion)
        {
            if (Squares.TryGetValue(from, out var piece))
            {
                Squares.Remove(from);
                // Kiểm tra xem đây có thực sự là nước đi phong cấp hợp lệ không
                bool isPawnPromotion = piece.Type == PieceType.Pawn && (to.Rank == 7 || to.Rank == 0);
                if (isPawnPromotion && !string.IsNullOrWhiteSpace(promotion))
                {
                    try
                    {
                        var newType = GetPieceTypeFromString(promotion);
                        piece = new Piece(piece.Color, newType);
                    }
                    catch (ArgumentException)
                    {
                        Console.WriteLine($"[Board] Phong cấp không hợp lệ: {promotion}");
                    }
                }
                Squares[to] = piece;
                
                // TODO: Cập nhật CastlingRights và EnPassantTarget tại đây
            }
        }

        public string ToFenString()
        {
            var sb = new StringBuilder();
            // 1. Quét 8 hàng từ 7 xuống 0 (từ hàng 8 xuống hàng 1 của bàn cờ)
            for (int rank = 7; rank >= 0; rank--)
            {
                int emptyCount = 0;
                for (int file = 0; file < 8; file++)
                {
                    var pos = new Position(file, rank);
                    if (Squares.TryGetValue(pos, out var piece))
                    {
                        if (emptyCount > 0)
                        {
                            sb.Append(emptyCount);
                            emptyCount = 0;
                        }
                        
                        // Lấy ký hiệu quân cờ
                        char pieceChar = piece.Type switch
                        {
                            PieceType.Pawn => 'p',
                            PieceType.Knight => 'n',
                            PieceType.Bishop => 'b',
                            PieceType.Rook => 'r',
                            PieceType.Queen => 'q',
                            PieceType.King => 'k',
                            _ => throw new ArgumentException("Loại quân cờ không hợp lệ")
                        };
                        // Viết hoa nếu là quân Trắng, viết thường nếu là Đen
                        sb.Append(piece.Color == PieceColor.White ? char.ToUpper(pieceChar) : pieceChar);
                    }
                    else
                    {
                        emptyCount++;
                    }
                }
                if (emptyCount > 0)
                {
                    sb.Append(emptyCount);
                }
                if (rank > 0)
                {
                    sb.Append('/');
                }
            }
            // 2. Lượt đi tiếp theo (Đảo ngược ActiveColor vì nước đi hiện tại vừa được thực hiện)
            string activeColorStr = ActiveColor == PieceColor.White ? "b" : "w";
            // 3. Các thông số phụ (Castling, En Passant, Clocks)
            string castling = CastlingRights;
            string enPassant = EnPassantTarget != null 
                ? $"{(char)('a' + EnPassantTarget.File)}{EnPassantTarget.Rank + 1}" 
                : "-";
                
            // Ghép các thành phần lại với nhau bằng khoảng trắng
            return $"{sb} {activeColorStr} {castling} {enPassant} {HalfmoveClock} {FullmoveNumber}";
        }

        private PieceType GetPieceTypeFromChar(char c) => char.ToLowerInvariant(c) switch
        {
            'p' => PieceType.Pawn,
            'n' => PieceType.Knight,
            'b' => PieceType.Bishop,
            'r' => PieceType.Rook,
            'q' => PieceType.Queen,
            'k' => PieceType.King,
            _ => throw new ArgumentException($"Ký tự quân cờ không hợp lệ: {c}")
        };

        private PieceType GetPieceTypeFromString(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length != 1)
                throw new ArgumentException($"Ký tự quân cờ không hợp lệ: {value}");

            return GetPieceTypeFromChar(value[0]);
        }

        private Position? ParseFenPosition(string fenPos)
        {
            if (fenPos == "-") return null;
            int file = fenPos[0] - 'a';
            int rank = fenPos[1] - '1';
            return new Position(file, rank);
        }
    }
}