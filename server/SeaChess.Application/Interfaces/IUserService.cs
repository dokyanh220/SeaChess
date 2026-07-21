using SeaChess.Application.DTOs.User;

namespace SeaChess.Application.Interfaces
{
    public interface IUserService
    {
        Task<UserProfileResponse?> GetUserProfileAsync(Guid userId);
        Task<IEnumerable<UserProfileResponse>> SearchUsersAsync(string query, Guid currentUserId);
        Task<UserProfileResponse?> UpdateProfileAsync(Guid userId, string? displayName, string? avatarUrl);
    }
}