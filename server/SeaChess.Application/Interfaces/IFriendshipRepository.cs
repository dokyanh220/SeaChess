using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;

namespace SeaChess.Application.Interfaces
{
    public interface IFriendshipRepository
    {
        Task<Friendship?> GetFriendshipAsync(Guid userId1, Guid userId2);
        Task<Friendship?> GetFriendshipByIdAsync(Guid friendshipId);
        Task AddAsync(Friendship friendship);
        Task UpdateAsync(Friendship friendship);
        Task<IEnumerable<Friendship>> GetFriendsByUserIdAsync(Guid userId);
        Task<IEnumerable<Friendship>> GetPendingRequestsByUserIdAsync(Guid userId);
    }
}
