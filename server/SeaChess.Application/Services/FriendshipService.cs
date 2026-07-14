using SeaChess.Application.DTOs.User;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;

namespace SeaChess.Application.Services
{
    public class FriendshipService : IFriendshipService
    {
        private readonly IFriendshipRepository _friendshipRepository;
        private readonly IUserRepository _userRepository;
        private readonly IUserService _userService;

        public FriendshipService(IFriendshipRepository friendshipRepository, IUserRepository userRepository, IUserService userService)
        {
            _friendshipRepository = friendshipRepository;
            _userRepository = userRepository;
            _userService = userService;
        }

        public async Task<bool> SendFriendRequestAsync(Guid requesterId, string receiverUsername)
        {
            var receiver = await _userRepository.GetByUsernameAsync(receiverUsername);
            if (receiver == null || receiver.Id == requesterId) return false;

            var existing = await _friendshipRepository.GetFriendshipAsync(requesterId, receiver.Id);
            if (existing != null) return false; // Already friends, pending, or blocked

            var friendship = new Friendship
            {
                Id = Guid.NewGuid(),
                RequesterId = requesterId,
                ReceiverId = receiver.Id,
                Status = FriendshipStatus.Pending
            };

            await _friendshipRepository.AddAsync(friendship);
            return true;
        }

        public async Task<bool> AcceptFriendRequestAsync(Guid receiverId, Guid requesterId)
        {
            var friendship = await _friendshipRepository.GetFriendshipAsync(requesterId, receiverId);
            if (friendship == null || friendship.Status != FriendshipStatus.Pending || friendship.ReceiverId != receiverId)
            {
                return false;
            }

            friendship.Status = FriendshipStatus.Accepted;
            await _friendshipRepository.UpdateAsync(friendship);
            return true;
        }

        public async Task<bool> DeclineFriendRequestAsync(Guid receiverId, Guid requesterId)
        {
            var friendship = await _friendshipRepository.GetFriendshipAsync(requesterId, receiverId);
            if (friendship == null || friendship.Status != FriendshipStatus.Pending || friendship.ReceiverId != receiverId)
            {
                return false;
            }

            friendship.Status = FriendshipStatus.Rejected;
            await _friendshipRepository.UpdateAsync(friendship);
            return true;
        }

        public async Task<bool> RemoveFriendAsync(Guid userId, Guid friendId)
        {
            var friendship = await _friendshipRepository.GetFriendshipAsync(userId, friendId);
            if (friendship == null || friendship.Status != FriendshipStatus.Accepted)
            {
                return false;
            }

            // We can set it to Declined or just delete it. Since we only have status updates, let's set it to Declined for now
            // or maybe delete is better. But our repo only has Update. Let's set status to something else, or maybe we need a Delete method.
            // I'll update it to Declined.
            friendship.Status = FriendshipStatus.Rejected;
            await _friendshipRepository.UpdateAsync(friendship);
            return true;
        }

        public async Task<IEnumerable<UserProfileResponse>> GetFriendsAsync(Guid userId)
        {
            var friendships = await _friendshipRepository.GetFriendsByUserIdAsync(userId);
            var friendsList = new List<UserProfileResponse>();

            foreach (var f in friendships)
            {
                var friendId = f.RequesterId == userId ? f.ReceiverId : f.RequesterId;
                var profile = await _userService.GetUserProfileAsync(friendId);
                if (profile != null)
                {
                    friendsList.Add(profile);
                }
            }

            return friendsList;
        }

        public async Task<IEnumerable<UserProfileResponse>> GetPendingRequestsAsync(Guid userId)
        {
            var friendships = await _friendshipRepository.GetPendingRequestsByUserIdAsync(userId);
            var requestsList = new List<UserProfileResponse>();

            foreach (var f in friendships)
            {
                var profile = await _userService.GetUserProfileAsync(f.RequesterId);
                if (profile != null)
                {
                    requestsList.Add(profile);
                }
            }

            return requestsList;
        }
    }
}
