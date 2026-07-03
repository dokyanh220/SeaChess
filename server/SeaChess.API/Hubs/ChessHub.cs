using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using SeaChess.Application.DTOs.Match;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Entities;
using SeaChess.Domain.Services;

namespace SeaChess.API.Hubs
{
    [Authorize]
    public class ChessHub : Hub
    {
        private readonly IMatchMakingService _matchmaking;
        private readonly IGameStateService _gameState;
        private const string INITIAL_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

        public ChessHub(IMatchMakingService matchmaking, IGameStateService gameState)
        {
            _matchmaking = matchmaking;
            _gameState = gameState;
        }

        public override async Task OnConnectedAsync()
        {
            // Tự động lấy userId từ Jwt Token
            Console.WriteLine($"[ChessHub] Client kết nối: {Context.ConnectionId}, UserId: {Context.UserIdentifier}");
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            if (Context.UserIdentifier != null)
            {
                await _matchmaking.LeaveQueueAsync(Context.UserIdentifier);
            }
            await base.OnDisconnectedAsync(exception);
        }

        public async Task FindMatch()
        {
            var userId = Context.UserIdentifier;
            if (userId == null) return;

            // TODO: Ở phiên bản hoàn chỉnh, Elo sẽ được lấy từ Database qua IUserRepository
            int playerElo = 1200;

            await _matchmaking.JoinQueueAsync(userId, playerElo);
            var opponentId = await _matchmaking.FindMatchAsync(userId, playerElo);

            if (opponentId != null)
            {
                var matchId = Guid.NewGuid().ToString();

                var isUserWhite = new Random().Next(2) == 0;

                var matchState = new MatchState
                {
                    MatchID = matchId,
                    WhitePlayerId = isUserWhite ? userId : opponentId,
                    BlackPlayerId = isUserWhite ? opponentId : userId,  
                    CurrentFen = INITIAL_FEN,
                    StartTimeUnix = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
                };

                await _gameState.SaveStateAsync(matchState);

                var matchedPlayers = new List<string> { userId, opponentId };

                await Clients.Users(matchedPlayers).SendAsync("MatchStarted", matchState);

                await Groups.AddToGroupAsync(Context.ConnectionId, matchId);
                // (Và phải gửi lệnh yêu cầu Client B cũng tự join vào Group này, hoặc Server tự dùng ID để gửi như code mẫu trên).
            }
            else
            {
                Console.WriteLine($"[Matchmaking] {userId} đang đợi đối thủ...");
            }
        }

        public async Task CancelMatch() 
        {
            var userId = Context.UserIdentifier;
            if (userId != null)
            {
                await _matchmaking.LeaveQueueAsync(userId);
                Console.WriteLine($"[Matchmaking] {userId} đã hủy tìm trận.");
            }
        }

        public async Task MakeMove(string matchId, string fromPosition, string toPosition, string? promotionPiece)
         {
            var userId = Context.UserIdentifier;
            if (userId == null) return;

            // Lấy state từ redis
            var matchState = await _gameState.GetStateAsync(matchId);
            if (matchState == null)
            {
                await Clients.Caller.SendAsync("Error", "Không tìm thấy trận đấu");
                return;
            }

            // Load Core
            Board board = new Board();
            board.LoadFromFen(matchState.CurrentFen);

            // Validate bước đi
            // var isLegalMove = GameStateAnalyzer.ValidateMove(board, userId, fromPosition, toPosition);
            // if (!isLegalMove)
            // {
            //     await Clients.Caller.SendAsync("Error", "Nước đi không hợp lệ");
            //     return;
            // }

            // Thực thi nước đi & Lấy FEN mới
            // board.MakeMove(fromPosition, toPosition, promotionPiece);
            // string newFen = board.ToFenString(); 
            string newFen = "Demo"; // TODO: Thay bằng FEN thật từ Engine

            // Cập nhật redis
            matchState.CurrentFen = newFen;
            await _gameState.SaveStateAsync(matchState);

            // Người chơi còn lại thấy nước đi
            var opponentId = matchState.WhitePlayerId == userId ? matchState.BlackPlayerId : matchState.WhitePlayerId;

            await Clients.User(opponentId).SendAsync("ReceiveMove", new 
            {
                From = fromPosition,
                To = toPosition,
                Promotion = promotionPiece,
                NewFen = newFen
            });

            // Kiểm tra kết thúc trận
            // if (GameStateAnalyzer.IsCheckmate(board)) { ... }
        }
    }
}