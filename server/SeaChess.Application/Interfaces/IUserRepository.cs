using SeaChess.Domain.Entities;

namespace SeaChess.Application.Interfaces
{
    public interface IUserRepository
    {
        Task<bool> ExistsByUsernameOrEmailAsync(string username, string email);
        Task<bool> ExistsByPlayerIdAsync(string playerId);
        Task<User?> GetByUsernameAsync(string username);
        Task AddAsync(User user);
        Task<User?> GetByIdAsync(Guid userId);
        Task UpdateAsync(User user);
        Task<IEnumerable<User>> SearchUsersAsync(string query, Guid currentUserId);
    }
}