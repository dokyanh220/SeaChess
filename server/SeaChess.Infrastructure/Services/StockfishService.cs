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

        // SemaphoreSlim(1,1) = chỉ cho 1 request chạy tại 1 thời điểm
        // Vì Stockfish process là single-threaded, gửi 2 lệnh cùng lúc sẽ lỗi
        private readonly SemaphoreSlim _semaphore = new(1, 1);

        public StockfishService(IConfiguration config)
        {
            _enginePath = config["Stockfish:Path"] ?? "stockfish";
            InitializeEngine();
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
                if (difficulty == AiDifficulty.Beginner)
                {
                    // Chế độ Beginner: 50% tỉ lệ đi một nước hợp lệ ngẫu nhiên (chấp nhận mắc sai lầm ngớ ngẩn)
                    if (Random.Shared.Next(100) < 50)
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
                            string rmStr = $"{rm.From}{rm.To}{promo}";
                            Console.WriteLine($"[Stockfish] (Beginner Random) FEN: {fen} | BestMove: {rmStr}");
                            return rmStr;
                        }
                    }
                }

                var (skillLevel, depth, thinkTime) = StockfishConfig.GetConfig(difficulty);
                SendCommand("ucinewgame");
                
                if (difficulty == AiDifficulty.Beginner || difficulty == AiDifficulty.Easy)
                {
                    // Stockfish hỗ trợ giới hạn sức mạnh bằng Elo
                    SendCommand("setoption name UCI_LimitStrength value true");
                    SendCommand($"setoption name UCI_Elo value {(difficulty == AiDifficulty.Beginner ? 1320 : 1500)}");
                    SendCommand("setoption name Skill Level value 0");
                }
                else
                {
                    SendCommand("setoption name UCI_LimitStrength value false");
                    SendCommand($"setoption name Skill Level value {skillLevel}");
                }
                // Đợi engine sẵn sàng
                SendCommand("isready");
                WaitForResponse("readyok");
                // Đặt vị trí bàn cờ bằng FEN
                SendCommand($"position fen {fen}");
                // Yêu cầu tìm nước đi tốt nhất
                // depth = số nước nhìn trước, movetime = thời gian tối đa (ms)
                SendCommand($"go depth {depth} movetime {thinkTime}");
                // Đọc output cho đến khi gặp "bestmove ..."
                var bestMove = await ReadBestMoveAsync();
                Console.WriteLine($"[Stockfish] FEN: {fen} | Difficulty: {difficulty} | BestMove: {bestMove}");
                return bestMove;
            }
            finally
            {
                _semaphore.Release();
            }
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