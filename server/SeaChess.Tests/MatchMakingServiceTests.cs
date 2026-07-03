using System.Threading.Tasks;
using Moq;
using StackExchange.Redis;
using SeaChess.Application.Interfaces;
using SeaChess.Infrastructure.Services;
using Xunit;

namespace SeaChess.Tests
{
    public class MatchMakingServiceTests
    {
        private const string QueueKey = "matchmaking_queue";
        private readonly Mock<IConnectionMultiplexer> _mockConnection;
        private readonly Mock<IDatabase> _mockDb;
        private readonly MatchMakingService _service;

        public MatchMakingServiceTests()
        {
            _mockConnection = new Mock<IConnectionMultiplexer>();
            _mockDb = new Mock<IDatabase>();
            _mockConnection.Setup(c => c.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
                .Returns(_mockDb.Object);
            _service = new MatchMakingService(_mockConnection.Object);
        }

        [Fact]
        public async Task JoinQueueAsync_CallsSortedSetAddAsync()
        {
            var userId = "user123";
            var elo = 1500;

            await _service.JoinQueueAsync(userId, elo);

            _mockDb.Verify(db => db.SortedSetAddAsync(
                QueueKey,
                userId,
                elo,
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()), Times.Once);
        }

        [Fact]
        public async Task LeaveQueueAsync_CallsSortedSetRemoveAsync()
        {
            var userId = "user123";

            await _service.LeaveQueueAsync(userId);

            _mockDb.Verify(db => db.SortedSetRemoveAsync(
                QueueKey,
                userId,
                It.IsAny<CommandFlags>()), Times.Once);
        }

        [Fact]
        public async Task FindMatchAsync_ReturnsMatchId_WhenOpponentFound()
        {
            var userId = "userA";
            var elo = 1500;
            var tolerance = 100;
            var opponentId = "userB";

            var rangeResult = new RedisValue[] { opponentId };
            _mockDb.Setup(db => db.SortedSetRangeByScoreAsync(
                QueueKey,
                elo - tolerance,
                elo + tolerance,
                Exclude.None,
                Order.Ascending,
                0,
                2,
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(rangeResult);

            var mockTran = new Mock<ITransaction>();
            mockTran.Setup(t => t.SortedSetRemoveAsync(QueueKey, userId, It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            mockTran.Setup(t => t.SortedSetRemoveAsync(QueueKey, opponentId, It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            mockTran.Setup(t => t.ExecuteAsync(It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            _mockDb.Setup(db => db.CreateTransaction()).Returns(mockTran.Object);

            var result = await _service.FindMatchAsync(userId, elo, tolerance);

            Assert.Equal(opponentId, result);
            mockTran.Verify(t => t.SortedSetRemoveAsync(QueueKey, userId, It.IsAny<CommandFlags>()), Times.Once);
            mockTran.Verify(t => t.SortedSetRemoveAsync(QueueKey, opponentId, It.IsAny<CommandFlags>()), Times.Once);
            mockTran.Verify(t => t.ExecuteAsync(It.IsAny<CommandFlags>()), Times.Once);
        }

        [Fact]
        public async Task FindMatchAsync_ReturnsNull_WhenNoOpponent()
        {
            var userId = "userA";
            var elo = 1500;
            var tolerance = 100;

            var emptyResult = new RedisValue[0];
            _mockDb.Setup(db => db.SortedSetRangeByScoreAsync(
                QueueKey,
                elo - tolerance,
                elo + tolerance,
                Exclude.None,
                Order.Ascending,
                0,
                2,
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(emptyResult);

            var result = await _service.FindMatchAsync(userId, elo, tolerance);

            Assert.Null(result);
        }
    }
}
