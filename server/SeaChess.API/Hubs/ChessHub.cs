using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using SeaChess.Application.DTOs.AI;
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
        private readonly IStockfishService _stockfish;
        private readonly IMatchRepository _matchRepo;
        private const string INITIAL_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

        public ChessHub(IMatchMakingService matchmaking, IGameStateService gameState, IUserRepository repository, IStockfishService stockfish, IMatchRepository matchRepo)
        {
            _matchmaking = matchmaking;
            _gameState = gameState;
            _userRepo = repository;
            _stockfish = stockfish;
            _matchRepo = matchRepo;
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

        public async Task StartAiGame(int difficulty, string colorPreference, int timeMinutes)
        {
            var userId = Context.UserIdentifier;
            if (userId == null) return;

            if (!Enum.IsDefined(typeof(AiDifficulty), difficulty))
            {
                await Clients.Caller.SendAsync("Error", "Cấp độ không hợp lệ");
                return;
            }

            int[] validTimes = { 5, 10, 15, 30};
            if (!validTimes.Contains(timeMinutes))
            {
                await Clients.Caller.SendAsync("Error", "Thời gian không hợp lệ");
                return;
            }

            // Xác định màu
            PieceColor playerColor;
            switch (colorPreference.ToLower())
            {
                case "white":
                    playerColor = PieceColor.White;
                    break;
                case "black":
                    playerColor = PieceColor.Black;
                    break;
                case "random":
                    playerColor = Random.Shared.Next(2) == 0 ? PieceColor.White : PieceColor.Black;
                    break;
                default:
                    playerColor = PieceColor.White;
                    break;
            }

            var aiColor = playerColor == PieceColor.White ? PieceColor.Black : PieceColor.White;

            // Tạo matchstate trong redis
            var matchId = Guid.NewGuid().ToString();
            var timeMs = timeMinutes * 60 * 1000;

            var matchState = new MatchState
            {
                MatchID = matchId,
                CurrentFen = INITIAL_FEN,
                WhitePlayerId = playerColor == PieceColor.White ? userId : "AI",
                BlackPlayerId = playerColor == PieceColor.Black ? userId : "AI",
                WhiteTimeLeftMs = timeMs,
                BlackTimeLeftMs = timeMs,
                LastMoveTime = DateTimeOffset.UtcNow,
                Status = "Playing",
                IsAiGame = true,
                AiDifficulty = (AiDifficulty)difficulty,
                AiColor = aiColor
            };

            // Nếu Ai đi trước
            string? firstAiMove = null;
            if (aiColor == PieceColor.White)
            {
                firstAiMove = await _stockfish.GetBestMoveAsync(INITIAL_FEN, (AiDifficulty)difficulty); // lấy bestmove mở đầu

                var board = new Board(INITIAL_FEN);
                var from = Position.Parse(firstAiMove[..2]);
                var to = Position.Parse(firstAiMove[2..4]);
                string? promo = firstAiMove.Length > 4 ?firstAiMove[4..] : null;
                board.MakeMove(from, to, promo);

                matchState.CurrentFen = board.ToFenString();
                matchState.LastMoveTime = DateTimeOffset.UtcNow;
            }

            // Lưu state vào redis
            await _gameState.SaveStateAsync(matchState);
            await _gameState.SetActiveMatchForUserAsync(userId, matchId);

            // Get user cho client
            var user = await _userRepo.GetByIdAsync(Guid.Parse(userId));
            string difficultyLabel = ((AiDifficulty)difficulty) switch
            {
                AiDifficulty.Beginner => "Mới chơi",
                AiDifficulty.Easy => "Dễ",
                AiDifficulty.Medium => "Trung bình",
                AiDifficulty.Hard => "Khó",
                _ => "AI",
            };

            // Gửi event AiGameStarted cho client
            await Clients.Caller.SendAsync("AiGameStarted", new
            {
                MatchId = matchId,
                Fen = matchState.CurrentFen,
                MyColor = playerColor == PieceColor.White ? "white" : "black",
                WhiteTimeLeftMs = timeMs,
                BlackTimeLeftMs = timeMs,
                Difficulty = difficulty,
                AiMove = firstAiMove, // null(user đi trước) hoặc AI
                OpponentName = $"Bot ({difficultyLabel})",
                OpponentLevel = 0,
                OpponentElo = 0,
                OpponentRank = "AI"
            });
        }

        public async Task RejoinMatch()
        {
            var userId = Context.UserIdentifier;
            if (userId == null) return;

            // Tìm matchId đang active của user này
            var matchId = await _gameState.GetActiveMatchForUserAsync(userId);
            if (matchId == null)
            {
                await Clients.Caller.SendAsync("NoActiveMatch");
                return;
            }

            var matchState = await _gameState.GetStateAsync(matchId);
            if (matchState == null || matchState.Status != "Playing")
            {
                // Trận đã kết thúc hoặc không tồn tại → xóa key cũ
                await _gameState.ClearActiveMatchForUserAsync(userId);
                await Clients.Caller.SendAsync("NoActiveMatch");
                return;
            }

            string myColor = matchState.WhitePlayerId == userId ? "white" : "black";
            string opponentId = matchState.WhitePlayerId == userId
                ? matchState.BlackPlayerId
                : matchState.WhitePlayerId;

            // Lấy thông tin đối thủ
            string opponentName  = "Đối thủ";
            int    opponentLevel = 1;
            int    opponentElo   = 0;
            string opponentRank  = "Unranked";

            if (Guid.TryParse(opponentId, out Guid opponentGuid))
            {
                var opponentUser = await _userRepo.GetByIdAsync(opponentGuid);
                if (opponentUser != null)
                {
                    opponentName  = opponentUser.DisplayName ?? "Đối thủ";
                    opponentLevel = opponentUser.Experience;
                    opponentElo   = opponentUser.Elo;
                }
            }

            Console.WriteLine($"[Reconnect] {userId} rejoined match {matchId} as {myColor}");

            await Clients.Caller.SendAsync("RejoinMatch", new
            {
                MatchId         = matchId,
                Fen             = matchState.CurrentFen,
                MyColor         = myColor,
                WhiteTimeLeftMs = matchState.WhiteTimeLeftMs,
                BlackTimeLeftMs = matchState.BlackTimeLeftMs,
                OpponentName    = opponentName,
                OpponentLevel   = opponentLevel,
                OpponentElo     = opponentElo,
                OpponentRank    = opponentRank,
            });
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
            double elapseMs = (now - matchState.LastMoveTime).TotalMilliseconds;

            if (currentTurn == "w")
            {
                matchState.WhiteTimeLeftMs -= elapseMs;
                if (matchState.WhiteTimeLeftMs <= 0)
                {
                    matchState.WhiteTimeLeftMs = 0;

                    await EndGame(matchState, matchState.BlackPlayerId, "Timeout");
                    return;
                }
            }
            else
            {
                matchState.BlackTimeLeftMs -= elapseMs;
                if (matchState.BlackTimeLeftMs <= 0)
                {
                    matchState.BlackTimeLeftMs = 0;

                    await EndGame(matchState, matchState.WhitePlayerId, "Timeout");
                    return;
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

            // Kiểm tra kết thúc trận
            PieceColor nextTurnColor = playerColor == PieceColor.White 
                ? PieceColor.Black 
                : PieceColor.White;
            
            var checkInfo = GameStateAnalyzer.GetCheckInfo(board, nextTurnColor);

            matchState.CurrentFen = newFen; // Cập nhật redis

            await _gameState.SaveStateAsync(matchState);

            if (matchState.IsAiGame)
            {
                await Clients.Caller.SendAsync("ReceiveMove", new 
                {
                    From = fromPosition,
                    To = toPosition,
                    Promotion = promotionPiece,
                    NewFen = newFen,
                    WhiteTimeLeftMs = matchState.WhiteTimeLeftMs,
                    BlackTimeLeftMs = matchState.BlackTimeLeftMs,
                    IsInCheck = checkInfo.IsCheck,
                    KingSquare = checkInfo.KingPosition?.ToString(),
                    AttackerSquares = checkInfo.AttackerPositions.Select(p => p.ToString()).ToList()
                });
            }
            else
            {
                await Clients.Users(new[] { matchState.WhitePlayerId, matchState.BlackPlayerId }).SendAsync("ReceiveMove", new 
                {
                    From = fromPosition,
                    To = toPosition,
                    Promotion = promotionPiece,
                    NewFen = newFen,
                    WhiteTimeLeftMs = matchState.WhiteTimeLeftMs,
                    BlackTimeLeftMs = matchState.BlackTimeLeftMs,
                    IsInCheck = checkInfo.IsCheck,
                    KingSquare = checkInfo.KingPosition?.ToString(),
                    AttackerSquares = checkInfo.AttackerPositions.Select(p => p.ToString()).ToList()
                });
            }

            // Check bí và luật để endgame
            if (GameStateAnalyzer.IsCheckmate(board, nextTurnColor))
            {
                string winnerId = userId;
                await EndGame(matchState, winnerId, "Checkmate");
                return;
            }

            if (GameStateAnalyzer.IsStalemate(board, nextTurnColor))
            {
                await EndGame(matchState, null, "Stalemate");
                return;
            }

            if (GameStateAnalyzer.IsFiftyMoveRule(board))
            {
                await EndGame(matchState, null, "FiftyMoveRule");
                return;
            }

            // Ai Game
            if (matchState.IsAiGame)
            {
                await Task.Delay(500); // Thêm delay để giao diện mượt mà hơn
                var aiMoveStr = await _stockfish.GetBestMoveAsync(
                    matchState.CurrentFen, matchState.AiDifficulty!.Value);
                
                var aiFrom = Position.Parse(aiMoveStr[..2]);
                var aiTo = Position.Parse(aiMoveStr[2..4]);
                string? aiPromo = aiMoveStr.Length > 4 ? aiMoveStr[4..] : null;

                var aiBoard = new Board(matchState.CurrentFen);
                aiBoard.MakeMove(aiFrom, aiTo, aiPromo);

                string aiFen = aiBoard.ToFenString();

                // Trừ thời gian suy nghĩ Ai = thinkTime từ config
                var thinkTime = StockfishConfig.GetSettings(matchState.AiDifficulty!.Value).ThinkTimeMs;
                if (matchState.AiColor == PieceColor.White)
                {
                    matchState.WhiteTimeLeftMs -= thinkTime;
                }
                else
                {
                    matchState.BlackTimeLeftMs -= thinkTime;
                }

                matchState.CurrentFen = aiFen;
                matchState.LastMoveTime = DateTimeOffset.UtcNow;

                await _gameState.SaveStateAsync(matchState);

                // Kiểm tra state sau nước Ai
                PieceColor humanColor = matchState.AiColor == PieceColor.White ? PieceColor.Black : PieceColor.White;
                var aiCheckInfo = GameStateAnalyzer.GetCheckInfo(aiBoard, humanColor);

                // Gửi nước đi về client (receiveMove)
                await Clients.Caller.SendAsync("ReceiveMove", new
                {
                    From = aiMoveStr[..2],
                    To = aiMoveStr[2..4],
                    Promotion = aiPromo ?? "",
                    NewFen = aiFen,
                    WhiteTimeLeftMs = matchState.WhiteTimeLeftMs,
                    BlackTimeLeftMs = matchState.BlackTimeLeftMs,
                    IsInCheck = aiCheckInfo.IsCheck,
                    KingSquare = aiCheckInfo.KingPosition?.ToString(),
                    AttackerSquares = aiCheckInfo.AttackerPositions
                        .Select(p => p.ToString()).ToList()
                });

                // Check bí và luật để endgame
                if (GameStateAnalyzer.IsCheckmate(aiBoard, humanColor))
                {
                    string winnerId = userId;
                    await EndGame(matchState, winnerId, "Checkmate");
                    return;
                }

                if (GameStateAnalyzer.IsStalemate(aiBoard, nextTurnColor))
                {
                    await EndGame(matchState, null, "Stalemate");
                    return;
                }

                if (GameStateAnalyzer.IsFiftyMoveRule(aiBoard))
                {
                    await EndGame(matchState, null, "FiftyMoveRule");
                    return;
                }
            }
        }

        private async Task EndGame(MatchState matchState, string? winnerId, string reason)
        {
            if (matchState.Status != "Playing") return;
            matchState.Status = "Finished";
            
            if (matchState.IsAiGame)
            {
                await _gameState.DeleteStateAsync(matchState.MatchID);
            }
            else
            {
                await _gameState.SaveStateAsync(matchState);
            }

            if (matchState.IsAiGame)
            {
                string humanId = matchState.WhitePlayerId == "AI" ? matchState.BlackPlayerId : matchState.WhitePlayerId;
                string humanColor = matchState.WhitePlayerId == "AI" ? "black" : "white";

                string resultForHuman;
                if (winnerId == null)
                {
                    resultForHuman = "draw";
                }
                else if (winnerId == "AI")
                {
                    resultForHuman = "lose";
                }
                else
                {
                    resultForHuman = "win";
                }

                await _gameState.ClearActiveMatchForUserAsync(humanId);

                await Clients.User(humanId).SendAsync("GameOver", new
                {
                    Result = resultForHuman,
                    Reason = reason,
                    EloChange = 0,
                    NewElo = 0,
                });

                // Console.WriteLine($"[AI Game Over] {matchState.MatchID} | " +
                //     $"Result: {resultForHuman} | Reason: {reason}");
                return;
            }

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

            // Xóa mapping userId → matchId (đã kết thúc, không cần reconnect nữa)
            await _gameState.ClearActiveMatchForUserAsync(matchState.WhitePlayerId);
            await _gameState.ClearActiveMatchForUserAsync(matchState.BlackPlayerId);

            var dbMatchResult = winnerId == null ? MatchResult.Draw 
                : winnerId == matchState.WhitePlayerId ? MatchResult.WhiteWin 
                : MatchResult.BlackWin;
                
            if (reason == "Aborted") dbMatchResult = MatchResult.Aborted;

            var match = new Match
            {
                Id = Guid.NewGuid(),
                WhitePlayerId = Guid.Parse(matchState.WhitePlayerId),
                BlackPlayerId = Guid.Parse(matchState.BlackPlayerId),
                Result = dbMatchResult,
                InitialTimeSeconds = 600, // TODO: lưu thời gian thực tế nếu có
                IsAiGame = false,
                PGN = matchState.CurrentFen, // Tạm lưu FEN cuối
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow
            };
            
            await _matchRepo.AddAsync(match);

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

            if (matchState.IsAiGame)
            {
                await _gameState.DeleteStateAsync(matchId);
                await _gameState.ClearActiveMatchForUserAsync(userId);
                // Console.WriteLine($"[AI Game Quit] {matchState.MatchID} deleted by {userId}");
                return;
            }

            string winnerId = matchState.WhitePlayerId == userId
                ? matchState.BlackPlayerId
                : matchState.WhitePlayerId;

            await EndGame(matchState, winnerId, "Resign");
        }
    }
}