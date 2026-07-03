using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
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

        public void MakeMove(Position from, Position to, PieceType? promotion = null)
        {
            // 1. Lấy quân cờ ở vị trí xuất phát
            if (Squares.TryGetValue(from, out var piece))
            {
                // 2. Xóa ô cũ
                Squares.Remove(from);
                
                // 3. Nếu có phong cấp (Promotion), đổi loại quân
                if (promotion.HasValue) 
                {
                    piece = new Piece(piece.Color, promotion.Value);
                }

                // 4. Đặt vào ô mới (sẽ đè lên quân bị ăn nếu có)
                Squares[to] = piece;

                // TODO: Cập nhật thêm quyền Nhập thành (CastlingRights) 
                // và mục tiêu Bắt qua đường (EnPassantTarget) tại đây
            }
        }

        public string ToFenString()
        {
            // Thuật toán quét 8 hàng, đếm ô trống và nối các ký hiệu quân cờ (K, q, p, P...)
            // Kết hợp với CastlingRights, EnPassantTarget, Halfmove, Fullmove.
            return "chuỗi_fen_đã_được_tính_toán_hoàn_chỉnh"; 
        }

        private PieceType GetPieceTypeFromChar(char c) => c switch
        {
            'p' => PieceType.Pawn,
            'n' => PieceType.Knight,
            'b' => PieceType.Bishop,
            'r' => PieceType.Rook,
            'q' => PieceType.Queen,
            'k' => PieceType.King,
            _ => throw new ArgumentException($"Ký tự quân cờ không hợp lệ: {c}")
        };

        private Position? ParseFenPosition(string fenPos)
        {
            if (fenPos == "-") return null;
            int file = fenPos[0] - 'a';
            int rank = fenPos[1] - '1';
            return new Position(file, rank);
        }
    }
}