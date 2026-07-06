using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using SeaChess.Application.DTOs.Match;
using SeaChess.Application.Interfaces;
using SeaChess.Application.Services;
using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Domain.Services;
using SeaChess.Domain.ValueObjects;

namespace SeaChess.API.Hubs
{
    [Authorize]
    public class ChessHub : Hub
    {
        private readonly IMatchMakingService _matchmaking;
        private readonly IGameStateService _gameState;
        private readonly IUserRepository _userRepo;
        private const string INITIAL_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

        public ChessHub(IMatchMakingService matchmaking, IGameStateService gameState, IUserRepository repository)
        {
            _matchmaking = matchmaking;
            _gameState = gameState;
            _userRepo = repository;
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
            
            if (!Guid.TryParse(userId, out Guid userGuid))
            {
                throw new HubException("UserId không hợp lệ");
            }

            var user = await _userRepo.GetByIdAsync(userGuid);

            int playerElo = user != null ? user.Elo : 1000;

            await _matchmaking.JoinQueueAsync(userId, playerElo);
            
            Console.WriteLine($"[Matchmaking] {userId}(elo: {playerElo}) đang ghép trận...");
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

        public async Task MakeMove(string matchId, string fromPosition, string toPosition, string promotionPiece)
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

            // Get playerColor
            PieceColor playerColor = matchState.WhitePlayerId == userId ? PieceColor.White : PieceColor.Black;

            if(userId != matchState.WhitePlayerId && userId != matchState.BlackPlayerId)
            {
                await Clients.Caller.SendAsync("Error", "Bạn đang không tham trận đấu này.");
                return;
            }

            string[] fenParts = matchState.CurrentFen.Split(" ");
            string currentTurn = fenParts.Length > 1 ? fenParts[1] : "w";

            var now = DateTimeOffset.UtcNow;
            double elapseMs = (now - matchState.LastMoveTime).TotalMicroseconds;

            if (currentTurn == "w")
            {
                matchState.WhiteTimeLeftMs -= elapseMs;
                if (matchState.WhiteTimeLeftMs <= 0)
                {
                    // Gọi hàm kết thúc game
                    matchState.WhiteTimeLeftMs = 0;
                }
            }
            else
            {
                matchState.BlackTimeLeftMs -= elapseMs;
                if (matchState.WhiteTimeLeftMs <= 0)
                {
                    // Gọi hàm kết thúc game
                    matchState.BlackTimeLeftMs = 0;
                }
            }

            matchState.LastMoveTime = now; // reset cho next turn

            bool isValidTurn = (playerColor == PieceColor.White && currentTurn == "w") ||
                (playerColor == PieceColor.Black && currentTurn == "b");

            if (!isValidTurn)
            {
                await Clients.Caller.SendAsync("Error", "Chưa đến lượt của bạn");
                // gửi lại fen chuẩn để client xếp lại nếu user xếp sai (đã xử lý ở client, rảnh thì thêm)
                return;
            }

            // Load Core
            var board = new Board(matchState.CurrentFen);
            var from = Position.Parse(fromPosition);
            var to = Position.Parse(toPosition);

            // Validate bước đi
            var isLegalMove = GameStateAnalyzer.ValidateMove(board, from, to, playerColor);
            if (!isLegalMove)
            {
                await Clients.Caller.SendAsync("Error", "Nước đi không hợp lệ");
                return;
            }

            // Thực thi nước đi & Lấy FEN mới
            board.MakeMove(from, to, promotionPiece);
            string newFen = board.ToFenString(); 

            matchState.CurrentFen = newFen; // Cập nhật redis

            await _gameState.SaveStateAsync(matchState);

            await Clients.Users(new[] { matchState.WhitePlayerId, matchState.BlackPlayerId }).SendAsync("ReceiveMove", new 
            {
                From = fromPosition,
                To = toPosition,
                Promotion = promotionPiece,
                NewFen = newFen,
                WhiteTimeLeftMs = matchState.WhiteTimeLeftMs,
                BlackTimeLeftMs = matchState.BlackTimeLeftMs
            });

            // Kiểm tra kết thúc trận
            PieceColor nextTurnColor = playerColor == PieceColor.White 
                ? PieceColor.Black 
                : PieceColor.White;

            if (GameStateAnalyzer.IsCheckmate(board, nextTurnColor))
            {
                
            }
        }

        private async Task EndGame(MatchState matchState, string? winnerId, string reason)
        {
            if (matchState.Status != "Playing") return;
            matchState.Status = "Finished";
            await _gameState.SaveStateAsync(matchState);

            var whiteUser = await _userRepo.GetByIdAsync(Guid.Parse(matchState.WhitePlayerId));
            var blackUser = await _userRepo.GetByIdAsync(Guid.Parse(matchState.BlackPlayerId));
            if (whiteUser == null || blackUser == null) return;

            int whiteEloChange = 0;
            int blackEloChange = 0;
            string resultForWhite;
            string resultForBlack;

            if (winnerId == null)
            {
                resultForWhite = "draw";
                resultForBlack = "draw";

                whiteUser.Draw++;
                blackUser.Draw++;
            }
            else if (winnerId == matchState.WhitePlayerId)
            {
                resultForWhite = "win";
                resultForBlack = "lose";

                whiteEloChange = EloCalculator.CalculateWinElo(
                    whiteUser.Elo, blackUser.Elo, matchState.WhiteTimeLeftMs
                );
                blackEloChange = EloCalculator.CalculateLoseElo(
                    whiteUser.Elo, blackUser.Elo
                );

                whiteUser.Wins++;
                blackUser.Loses++;
            }
            else
            {
                resultForBlack = "win";
                resultForWhite = "lose";

                blackEloChange = EloCalculator.CalculateWinElo(
                    blackUser.Elo, whiteUser.Elo, matchState.WhiteTimeLeftMs
                );
                whiteEloChange = EloCalculator.CalculateLoseElo(
                    whiteUser.Elo, blackUser.Elo
                );

                blackUser.Wins++;
                whiteUser.Loses++;
            }

            whiteUser.Elo = Math.Max(0, whiteUser.Elo + whiteEloChange);
            blackUser.Elo = Math.Max(0, blackUser.Elo + blackEloChange);
            whiteUser.TotalMatches++;
            blackUser.TotalMatches++;
            whiteUser.Experience += 77;
            blackUser.Experience += 77;

            await _userRepo.UpdateAsync(whiteUser);
            await _userRepo.UpdateAsync(blackUser);

            await Clients.User(matchState.WhitePlayerId).SendAsync("GameOver", new
            {
                Result = resultForWhite,
                Reason = reason,
                EloChange = whiteEloChange,
                NewElo = whiteUser.Elo 
            });

            await Clients.User(matchState.BlackPlayerId).SendAsync("GameOver", new
            {
                Result = resultForBlack,
                Reason = reason,
                EloChange = blackEloChange,
                NewElo = blackUser.Elo
            });

            Console.WriteLine($"[Game Over] {matchState.MatchID} | Reason: {reason} | " +
                    $"White({whiteUser.DisplayName}): {whiteEloChange:+#;-#;0} Elo | " +
                    $"Black({blackUser.DisplayName}): {blackEloChange:+#;-#;0} Elo");
        }

        public async Task Resign(string matchId)
        {
            var userId = Context.UserIdentifier;
            if (userId == null) return;

            var matchState = await _gameState.GetStateAsync(matchId);
            if (matchState == null || matchState.Status != "Playing") return;

            string winnerId = matchState.WhitePlayerId == userId
                ? matchState.BlackPlayerId
                : matchState.WhitePlayerId;

            await EndGame(matchState, winnerId, "Resign");
        }
    }
}