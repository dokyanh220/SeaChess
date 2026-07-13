using System.Diagnostics;
using Microsoft.Extensions.Configuration;
using SeaChess.Application.DTOs.AI;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Domain.Services;

namespace SeaChess.Infrastructure.Services
{
    public class StockfishService : IStockfishService
    {
        private Process? _process;
        private StreamWriter? _writer;
        private StreamReader? _reader;
        private readonly string _enginePath;
        private bool _initialized = false;

        // SemaphoreSlim(1,1) = chỉ cho 1 request chạy tại 1 thời điểm
        // Vì Stockfish process là single-threaded, gửi 2 lệnh cùng lúc sẽ lỗi
        private readonly SemaphoreSlim _semaphore = new(1, 1);

        public StockfishService(IConfiguration config)
        {
            _enginePath = config["Stockfish:Path"] ?? "stockfish";
            // Không khởi tạo engine ngay ở constructor nữa
            // Sẽ khởi tạo lần đầu khi cần (lazy init)
        }

        /// <summary>
        /// Đảm bảo engine đã được khởi tạo trước khi sử dụng
        /// </summary>
        private void EnsureInitialized()
        {
            if (!_initialized)
            {
                InitializeEngine();
                _initialized = true;
            }
        }

        private void InitializeEngine()
        {
            _process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = _enginePath,
                    UseShellExecute = false,
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                }
            };

            _process.Start();
            _writer = _process.StandardInput;
            _reader = _process.StandardOutput;

            
            // Handshake theo chuẩn UCI:
            // 1. Gửi "uci" → đợi "uciok"
            // 2. Gửi "isready" → đợi "readyok"
            SendCommand("uci");
            WaitForResponse("uciok");

            SendCommand("isready");
            WaitForResponse("readyok");

            Console.WriteLine("[Stockfish] Engine initialized successfully");
        }

        public async Task<string> GetBestMoveAsync(string fen, AiDifficulty difficulty)
        {
            await _semaphore.WaitAsync();
            try
            {
                EnsureInitialized();

                var settings = StockfishConfig.GetSettings(difficulty);

                // 1. Kiểm tra Random Move (cho Beginner)
                if (settings.RandomMoveChance > 0 && Random.Shared.Next(100) < settings.RandomMoveChance)
                {
                    string? randomMove = GetRandomLegalMove(fen);
                    if (randomMove != null)
                    {
                        Console.WriteLine($"[Stockfish] (Random) FEN: {fen} | BestMove: {randomMove}");
                        return randomMove;
                    }
                }

                // 2. Cấu hình Stockfish theo AiSettings
                SendCommand("ucinewgame");
                
                if (settings.UseElo)
                {
                    SendCommand("setoption name UCI_LimitStrength value true");
                    SendCommand($"setoption name UCI_Elo value {settings.Elo}");
                    SendCommand($"setoption name Skill Level value {settings.SkillLevel}");
                }
                else
                {
                    SendCommand("setoption name UCI_LimitStrength value false");
                    SendCommand($"setoption name Skill Level value {settings.SkillLevel}");
                }
                
                SendCommand("isready");
                WaitForResponse("readyok");
                
                SendCommand($"position fen {fen}");
                SendCommand($"go depth {settings.Depth} movetime {settings.ThinkTimeMs}");
                
                var bestMove = await ReadBestMoveAsync();
                Console.WriteLine($"[Stockfish] FEN: {fen} | Difficulty: {difficulty} | BestMove: {bestMove}");
                return bestMove;
            }
            finally
            {
                _semaphore.Release();
            }
        }

        private string? GetRandomLegalMove(string fen)
        {
            var board = new Board(fen);
            string[] parts = fen.Split(' ');
            PieceColor color = parts.Length > 1 && parts[1] == "b" ? PieceColor.Black : PieceColor.White;
            var legalMoves = GameStateAnalyzer.GetLegalMoves(board, color);
            
            if (legalMoves.Count > 0)
            {
                var rm = legalMoves[Random.Shared.Next(legalMoves.Count)];
                string promo = "";
                if (board.Squares.TryGetValue(rm.From, out var p) && p.Type == PieceType.Pawn)
                {
                    if ((color == PieceColor.White && rm.To.Rank == 7) || (color == PieceColor.Black && rm.To.Rank == 0))
                        promo = "q";
                }
                return $"{rm.From}{rm.To}{promo}";
            }
            return null;
        }

        private async Task<string> ReadBestMoveAsync()
        {
            string? line;
            while((line = await _reader!.ReadLineAsync()) != null)
            {
                if (line.StartsWith("bestmove"))
                {
                    var parts = line.Split(' ');
                    return parts[1];
                }
            }

            throw new InvalidOperationException("Stockfish kết thúc: không trả về 'bestmove'");
        }

        private void SendCommand(string command)
        {
            _writer!.WriteLine(command);
            _writer.Flush();
        }

        private void WaitForResponse(string expected)
        {
            string? line;
            while ((line = _reader!.ReadLine()) != null)
            {
                if (line.Trim() == expected) return;
            }
        }

        public void Dispose()
        {
            try
            {
                SendCommand("quit");
                _process?.WaitForExit(3000);
            }
            catch { }
            finally
            {
                _process?.Kill();
                _process?.Dispose();
            }
        }
    }
}