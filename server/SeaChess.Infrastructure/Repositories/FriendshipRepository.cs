using Microsoft.EntityFrameworkCore;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using SeaChess.Infrastructure.Data;

namespace SeaChess.Infrastructure.Repositories
{
    public class FriendshipRepository : IFriendshipRepository
    {
        private readonly ApplicationDbContext _context;

        public FriendshipRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<Friendship?> GetFriendshipAsync(Guid userId1, Guid userId2)
        {
            return await _context.Friendships
                .FirstOrDefaultAsync(f => 
                    (f.RequesterId == userId1 && f.ReceiverId == userId2) ||
                    (f.RequesterId == userId2 && f.ReceiverId == userId1));
        }

        public async Task<Friendship?> GetFriendshipByIdAsync(Guid friendshipId)
        {
            return await _context.Friendships.FindAsync(friendshipId);
        }

        public async Task AddAsync(Friendship friendship)
        {
            await _context.Friendships.AddAsync(friendship);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(Friendship friendship)
        {
            friendship.UpdatedAt = DateTime.UtcNow;
            _context.Friendships.Update(friendship);
            await _context.SaveChangesAsync();
        }

        public async Task<IEnumerable<Friendship>> GetFriendsByUserIdAsync(Guid userId)
        {
            return await _context.Friendships
                .Where(f => (f.RequesterId == userId || f.ReceiverId == userId) && f.Status == FriendshipStatus.Accepted)
                .ToListAsync();
        }

        public async Task<IEnumerable<Friendship>> GetPendingRequestsByUserIdAsync(Guid userId)
        {
            return await _context.Friendships
                .Where(f => f.ReceiverId == userId && f.Status == FriendshipStatus.Pending)
                .ToListAsync();
        }
    }
}
