using SeaChess.Application.DTOs.User;

namespace SeaChess.Application.Interfaces
{
    public interface IUserService
    {
        Task<UserProfileResponse> GetUserProfileAsync(Guid userId);
    }
}