using System.Text.Json;
using Microsoft.AspNetCore.SignalR;
using SeaChess.API.Hubs;
using SeaChess.Application.DTOs.Match;
using StackExchange.Redis;

namespace SeaChess.API.Workers
{
    public class MatchmakingWorker : BackgroundService
    {
        private readonly IConnectionMultiplexer _redis;
        private readonly IHubContext<ChessHub> _hubContext;
        private readonly ILogger<MatchmakingWorker> _logger;

        public MatchmakingWorker(
            IConnectionMultiplexer redis,
            IHubContext<ChessHub> hubContext,
            ILogger<MatchmakingWorker> logger)
        {
            _redis = redis;
            _hubContext = hubContext;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("[Matchmaking] Worker đang chạy ngầm...");
            var db = _redis.GetDatabase();

            string queueKey = "matchmaking_queue";

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    long queueLength = await db.SortedSetLengthAsync(queueKey);

                    if (queueLength >= 2)
                    {
                        var matchedPlayers = await db.SortedSetPopAsync(queueKey, 2);

                        if (matchedPlayers != null && matchedPlayers.Length == 2)
                        {
                            var p1 = matchedPlayers[0].Element;
                            var p2 = matchedPlayers[1].Element;

                            string matchId = Guid.NewGuid().ToString();
                            string initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

                            _logger.LogInformation($"Ghép trận thành công: {p1} (Trắng) vs {p2} (Đen). MatchId: {matchId}");

                            const double initialTimeMs = 20 * 60 * 1000; // 120000s | 20 phút
                            var matchState = new MatchState
                            {
                                MatchID = matchId,
                                WhitePlayerId = p1.ToString()!,
                                BlackPlayerId = p2.ToString()!,
                                CurrentFen = initialFen,
                                Status = "Playing",
                                WhiteTimeLeftMs = initialTimeMs,
                                BlackTimeLeftMs = initialTimeMs,
                                LastMoveTime = DateTimeOffset.UtcNow,
                            };

                            string stateJson = JsonSerializer.Serialize(matchState);

                            await db.StringSetAsync($"match_state:{matchId}", stateJson);

                            await _hubContext.Clients.User(p1.ToString()!)
                                .SendAsync("MatchStarted", matchId, initialFen, "white", cancellationToken: stoppingToken);

                            await _hubContext.Clients.User(p2.ToString()!)
                                .SendAsync("MatchStarted", matchId, initialFen, "black", cancellationToken: stoppingToken);
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError($"[Matchmaking Error] {ex.Message}");
                }

                await Task.Delay(1000, stoppingToken);
            }
        }
    }
}