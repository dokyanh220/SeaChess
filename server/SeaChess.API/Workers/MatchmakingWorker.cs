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
        private readonly IServiceProvider _serviceProvider;

        public MatchmakingWorker(
            IConnectionMultiplexer redis,
            IHubContext<ChessHub> hubContext,
            ILogger<MatchmakingWorker> logger,
            IServiceProvider serviceProvider)
        {
            _redis = redis;
            _hubContext = hubContext;
            _logger = logger;
            _serviceProvider = serviceProvider;
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

                            await db.StringSetAsync($"match_state:{matchId}", stateJson, TimeSpan.FromHours(3));

                            // Lưu mapping userId → matchId để hỗ trợ reconnect
                            var matchTtl = TimeSpan.FromHours(3);
                            await db.StringSetAsync($"user_active_match:{p1}", matchId, matchTtl);
                            await db.StringSetAsync($"user_active_match:{p2}", matchId, matchTtl);


                            // Fetch user profiles to send opponent info
                            using var scope = _serviceProvider.CreateScope();
                            var userService = scope.ServiceProvider.GetRequiredService<SeaChess.Application.Interfaces.IUserService>();
                            
                            var p1Profile = await userService.GetUserProfileAsync(Guid.Parse(p1.ToString()!));
                            var p2Profile = await userService.GetUserProfileAsync(Guid.Parse(p2.ToString()!));

                            // Send MatchStarted to White (p1) with Black's (p2) profile
                            await _hubContext.Clients.User(p1.ToString()!)
                                .SendAsync("MatchStarted", matchId, initialFen, "white", new {
                                    opponentName = p2Profile?.DisplayName ?? "Đối thủ",
                                    opponentLevel = p2Profile?.Level ?? 1,
                                    opponentElo = p2Profile?.Elo ?? 799,
                                    opponentRank = p2Profile?.Rank ?? "Unranked"
                                }, cancellationToken: stoppingToken);

                            // Send MatchStarted to Black (p2) with White's (p1) profile
                            await _hubContext.Clients.User(p2.ToString()!)
                                .SendAsync("MatchStarted", matchId, initialFen, "black", new {
                                    opponentName = p1Profile?.DisplayName ?? "Đối thủ",
                                    opponentLevel = p1Profile?.Level ?? 1,
                                    opponentElo = p1Profile?.Elo ?? 799,
                                    opponentRank = p1Profile?.Rank ?? "Unranked"
                                }, cancellationToken: stoppingToken);
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