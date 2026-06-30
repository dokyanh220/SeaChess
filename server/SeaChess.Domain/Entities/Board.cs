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