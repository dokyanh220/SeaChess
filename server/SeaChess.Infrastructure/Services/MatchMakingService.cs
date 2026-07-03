using SeaChess.Application.Interfaces;
using StackExchange.Redis;

namespace SeaChess.Infrastructure.Services
{
    public class MatchMakingService : IMatchMakingService
    {
        private readonly IDatabase _redisDb;
        private const string QUEUE_KEY = "matchmaking_queue";

        public MatchMakingService (IConnectionMultiplexer redis)
        {
            _redisDb = redis.GetDatabase();
        }

        public async Task JoinQueueAsync(string userId, int elo)
        {
            await _redisDb.SortedSetAddAsync(QUEUE_KEY, userId, elo);
        }

        public async Task LeaveQueueAsync(string userId)
        {
            await _redisDb.SortedSetRemoveAsync(QUEUE_KEY, userId);
        }

        public async Task<string?> FindMatchAsync(string userId, int elo, int tolerence = 100)
        {
            int minElo = elo - tolerence;
            int maxElo = elo + tolerence;

            var potentialMatches = await _redisDb.SortedSetRangeByScoreAsync(QUEUE_KEY, minElo, maxElo, take: 2);

            foreach (var match in potentialMatches)
            {
                var matchId = match.ToString();

                if (matchId != userId)
                {
                    var tran = _redisDb.CreateTransaction();
                    await tran.SortedSetRemoveAsync(QUEUE_KEY, userId);
                    await tran.SortedSetRemoveAsync(QUEUE_KEY, matchId);

                    bool commited = await tran.ExecuteAsync();
                    if (commited)
                    {
                        return matchId;
                    }
                }
            }

            return null;
        }
    }
}