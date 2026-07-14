using SeaChess.Application.DTOs.User;

namespace SeaChess.Application.Interfaces
{
    public interface IFriendshipService
    {
        Task<bool> SendFriendRequestAsync(Guid requesterId, string receiverUsername);
        Task<bool> AcceptFriendRequestAsync(Guid receiverId, Guid requesterId);
        Task<bool> DeclineFriendRequestAsync(Guid receiverId, Guid requesterId);
        Task<bool> RemoveFriendAsync(Guid userId, Guid friendId);
        Task<IEnumerable<UserProfileResponse>> GetFriendsAsync(Guid userId);
        Task<IEnumerable<UserProfileResponse>> GetPendingRequestsAsync(Guid userId);
    }
}
