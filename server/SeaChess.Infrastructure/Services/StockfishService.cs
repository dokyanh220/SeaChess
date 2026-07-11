using System.Diagnostics;
using Microsoft.Extensions.Configuration;
using SeaChess.Application.DTOs.AI;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Enums;

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
                var (skillLevel, depth, thinkTime) = StockfishConfig.GetConfig(difficulty);
                SendCommand("ucinewgame");
                // Set độ khó
                SendCommand($"setoption name Skill Level value {skillLevel}");
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