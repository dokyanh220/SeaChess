using System.Text.Json;
using SeaChess.Application.DTOs.Match;
using SeaChess.Application.Interfaces;
using StackExchange.Redis;

namespace SeaChess.Infrastructure.Services
{
    public class GameStateService : IGameStateService
    {
        private readonly IDatabase _redisDb;
        private static readonly TimeSpan _ttl = TimeSpan.FromHours(3);

        public GameStateService(IConnectionMultiplexer redis)
        {
            _redisDb = redis.GetDatabase();
        }

        // ── Trạng thái ván cờ ────────────────────────────────────────

        public async Task SaveStateAsync(MatchState state)
        {
            var key  = $"match_state:{state.MatchID}";
            var json = JsonSerializer.Serialize(state);
            await _redisDb.StringSetAsync(key, json, _ttl);
        }

        public async Task<MatchState?> GetStateAsync(string matchId)
        {
            var key  = $"match_state:{matchId}";
            var json = await _redisDb.StringGetAsync(key);
            if (json.IsNullOrEmpty) return null;
            return JsonSerializer.Deserialize<MatchState>(json.ToString());
        }

        // ── Mapping userId → matchId (để reconnect) ──────────────────

        public async Task SetActiveMatchForUserAsync(string userId, string matchId)
        {
            var key = $"user_active_match:{userId}";
            await _redisDb.StringSetAsync(key, matchId, _ttl);
        }

        public async Task<string?> GetActiveMatchForUserAsync(string userId)
        {
            var key   = $"user_active_match:{userId}";
            var value = await _redisDb.StringGetAsync(key);
            return value.IsNullOrEmpty ? null : value.ToString();
        }

        public async Task ClearActiveMatchForUserAsync(string userId)
        {
            var key = $"user_active_match:{userId}";
            await _redisDb.KeyDeleteAsync(key);
        }
    }
}