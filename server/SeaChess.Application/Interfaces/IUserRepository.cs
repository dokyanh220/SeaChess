using SeaChess.Domain.Entities;

namespace SeaChess.Application.Interfaces
{
    public interface IUserRepository
    {
        Task<bool> ExistsByUsernameOrEmailAsync(string username, string email);
        Task<User?> GetByUsernameAsync(string username);
        Task AddAsync(User user);
    }
}