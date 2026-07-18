using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Entities;
using SeaChess.Infrastructure.Data;

namespace SeaChess.Infrastructure.Repositories
{
    public class MatchRepository : IMatchRepository
    {
        private readonly ApplicationDbContext _context;

        public MatchRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<Match>> GetMatchHistoryByUserIdAsync(Guid userId, int limit)
        {
            return await _context.Matches
                .Where(m => m.WhitePlayerId == userId || m.BlackPlayerId == userId)
                .OrderByDescending(m => m.CreatedAt)
                .Take(limit)
                .ToListAsync();
        }

        public async Task AddAsync(Match match)
        {
            await _context.Matches.AddAsync(match);
            await _context.SaveChangesAsync();
        }
    }
}
