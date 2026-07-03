using System.Text.Json;
using SeaChess.Application.DTOs.Match;
using SeaChess.Application.Interfaces;
using StackExchange.Redis;

namespace SeaChess.Infrastructure.Services
{
    public class GameStateService : IGameStateService
    {
        private readonly IDatabase _redisDb;

        public GameStateService(IConnectionMultiplexer redis)
        {
            _redisDb = redis.GetDatabase();
        }

        public async Task SaveStateAsync(MatchState state)
        {
            var key = $"match_state:{state.MatchID}";
            var json = JsonSerializer.Serialize(state);
            // Trạng thái ván cờ(set 3h dọn rác)
            await _redisDb.StringSetAsync(key, json, TimeSpan.FromHours(3));
        }

        public async Task<MatchState?> GetStateAsync(string matchId)
        {
            var key = $"match_state:{matchId}";
            var json = await _redisDb.StringGetAsync(key);

            if (json.IsNullOrEmpty) return null;
            return JsonSerializer.Deserialize<MatchState>(json.ToString());
        }
    }
}