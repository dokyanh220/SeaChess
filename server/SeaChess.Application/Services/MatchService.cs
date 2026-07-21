using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SeaChess.Application.DTOs.Match;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;

namespace SeaChess.Application.Services
{
    public class MatchService : IMatchService
    {
        private readonly IMatchRepository _matchRepository;
        private readonly IUserRepository _userRepository;

        public MatchService(IMatchRepository matchRepository, IUserRepository userRepository)
        {
            _matchRepository = matchRepository;
            _userRepository = userRepository;
        }

        public async Task<List<MatchHistoryDto>> GetMatchHistoryAsync(Guid userId, int limit)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user != null && user.IsGuest)
            {
                limit = Math.Min(limit, 5);
            }

            var matches = await _matchRepository.GetMatchHistoryByUserIdAsync(userId, limit);
            
            // Lấy danh sách ID của các đối thủ (không phải AI)
            var opponentIds = matches
                .Where(m => !m.IsAiGame)
                .Select(m => m.WhitePlayerId == userId ? m.BlackPlayerId : m.WhitePlayerId)
                .Where(id => id.HasValue)
                .Select(id => id.Value)
                .Distinct()
                .ToList();
                
            // Lấy thông tin các đối thủ từ DB
            var opponents = new Dictionary<Guid, User>();
            foreach (var opId in opponentIds)
            {
                var opponentUser = await _userRepository.GetByIdAsync(opId);
                if (opponentUser != null)
                {
                    opponents[opId] = opponentUser;
                }
            }
            
            var result = new List<MatchHistoryDto>();
            
            foreach (var match in matches)
            {
                bool isWhite = match.WhitePlayerId == userId;
                string opponentName = "AI";
                int opponentElo = 1000;
                
                if (match.IsAiGame)
                {
                    opponentName = $"Máy ({match.AiDifficulty})";
                    opponentElo = (int)(match.AiDifficulty ?? AiDifficulty.Beginner) * 400 + 400; // Fake elo cho máy
                }
                else
                {
                    var opId = isWhite ? match.BlackPlayerId : match.WhitePlayerId;
                    if (opId.HasValue && opponents.TryGetValue(opId.Value, out var opponent))
                    {
                        opponentName = opponent.Username;
                        opponentElo = opponent.Elo;
                    }
                    else
                    {
                        opponentName = "Unknown Player";
                    }
                }
                
                result.Add(new MatchHistoryDto
                {
                    Id = match.Id,
                    OpponentName = opponentName,
                    OpponentElo = opponentElo,
                    Result = match.Result,
                    IsWhite = isWhite,
                    IsAiGame = match.IsAiGame,
                    AiDifficulty = match.AiDifficulty,
                    PGN = match.PGN,
                    CreatedAt = match.CreatedAt,
                    InitialTimeSeconds = match.InitialTimeSeconds
                });
            }
            
            return result;
        }

        public async Task<AiMatchResultResponse> SaveAiMatchResultAsync(Guid userId, AiMatchResultDto dto)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null) throw new Exception("User not found");

            int eloChange = 0;
            int xpChange = 0;

            bool isWin = (dto.PlayerColor == PieceColor.White && dto.Result == MatchResult.WhiteWin) || 
                         (dto.PlayerColor == PieceColor.Black && dto.Result == MatchResult.BlackWin);
            bool isLoss = (dto.PlayerColor == PieceColor.White && dto.Result == MatchResult.BlackWin) || 
                          (dto.PlayerColor == PieceColor.Black && dto.Result == MatchResult.WhiteWin);
            bool isDraw = dto.Result == MatchResult.Draw || dto.Result == MatchResult.Aborted;

            switch (dto.Difficulty)
            {
                case AiDifficulty.Beginner:
                    eloChange = isWin ? 5 : isLoss ? -5 : 0;
                    xpChange = isWin ? 10 : isLoss ? 2 : 5;
                    break;
                case AiDifficulty.Easy:
                    eloChange = isWin ? 10 : isLoss ? -10 : 0;
                    xpChange = isWin ? 20 : isLoss ? 5 : 10;
                    break;
                case AiDifficulty.Medium:
                    eloChange = isWin ? 15 : isLoss ? -15 : 0;
                    xpChange = isWin ? 30 : isLoss ? 10 : 15;
                    break;
                case AiDifficulty.Hard:
                    eloChange = isWin ? 20 : isLoss ? -20 : 0;
                    xpChange = isWin ? 50 : isLoss ? 15 : 20;
                    break;
            }

            if (user.IsGuest)
            {
                eloChange = 0;
                xpChange = 0;
            }
            else
            {
                user.Elo = Math.Max(0, user.Elo + eloChange);
                user.Experience += xpChange;
                user.TotalMatches++;

                if (isWin) user.Wins++;
                else if (isLoss) user.Loses++;
                else user.Draw++;
            }

            // Tính Level hiện tại để trả về
            int CalculateLevel(int exp)
            {
                int lvl = 1;
                int expNeeded = 0;
                while (true)
                {
                    expNeeded += 100 * lvl * lvl;
                    if (exp < expNeeded) break;
                    lvl++;
                }
                return lvl;
            }

            int newLevel = CalculateLevel(user.Experience);

            await _userRepository.UpdateAsync(user);

            var match = new Match
            {
                Id = Guid.NewGuid(),
                WhitePlayerId = dto.PlayerColor == PieceColor.White ? userId : null,
                BlackPlayerId = dto.PlayerColor == PieceColor.Black ? userId : null,
                Result = dto.Result,
                InitialTimeSeconds = dto.InitialTimeSeconds,
                IsAiGame = true,
                AiDifficulty = dto.Difficulty,
                AiColor = dto.PlayerColor == PieceColor.White ? PieceColor.Black : PieceColor.White,
                PGN = dto.Pgn,
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow
            };

            await _matchRepository.AddAsync(match);

            return new AiMatchResultResponse
            {
                EloChange = eloChange,
                XpChange = xpChange,
                NewElo = user.Elo,
                NewLevel = newLevel,
                NewExperience = user.Experience
            };
        }
    }
}
