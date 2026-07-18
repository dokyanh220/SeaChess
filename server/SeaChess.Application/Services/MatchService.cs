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
            var matches = await _matchRepository.GetMatchHistoryByUserIdAsync(userId, limit);
            
            // Lấy danh sách ID của các đối thủ (không phải AI)
            var opponentIds = matches
                .Where(m => !m.IsAiGame)
                .Select(m => m.WhitePlayerId == userId ? m.BlackPlayerId : m.WhitePlayerId)
                .Distinct()
                .ToList();
                
            // Lấy thông tin các đối thủ từ DB
            var opponents = new Dictionary<Guid, User>();
            foreach (var opId in opponentIds)
            {
                var user = await _userRepository.GetByIdAsync(opId);
                if (user != null)
                {
                    opponents[opId] = user;
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
                    if (opponents.TryGetValue(opId, out var opponent))
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
    }
}
