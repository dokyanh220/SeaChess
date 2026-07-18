using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SeaChess.Domain.Entities;

namespace SeaChess.Application.Interfaces
{
    public interface IMatchRepository
    {
        Task<List<Match>> GetMatchHistoryByUserIdAsync(Guid userId, int limit);
        Task AddAsync(Match match);
    }
}
