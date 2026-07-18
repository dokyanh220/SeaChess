using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SeaChess.Application.DTOs.Match;

namespace SeaChess.Application.Interfaces
{
    public interface IMatchService
    {
        Task<List<MatchHistoryDto>> GetMatchHistoryAsync(Guid userId, int limit);
    }
}
