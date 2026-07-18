using System.Runtime.InteropServices;
using SeaChess.Application.DTOs.User;
using SeaChess.Application.Interfaces;

namespace SeaChess.Application.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _context;
        private readonly IFriendshipRepository _friendshipRepo;

        public UserService(IUserRepository context, IFriendshipRepository friendshipRepo)
        {
            _context = context;
            _friendshipRepo = friendshipRepo;
        }

        public async Task<UserProfileResponse?> GetUserProfileAsync(Guid userId)
        {
            var user = await _context.GetByIdAsync(userId);
            if (user == null) return null;

            double winRate = user.TotalMatches == 0
                ? 0
                : Math.Round((double)user.Wins / user.TotalMatches * 100, 2);
            int level = CalculateLevel(user.Experience);
            string rank = DetermineRank(user.TotalMatches, user.Elo);

            return new UserProfileResponse
            {
                Id = user.Id,
                UserId = user.PlayerId,
                Username = user.Username,
                DisplayName = user.DisplayName,
                AvatarUrl = user.AvatarUrl,
                Experience = user.Experience,
                Elo = user.Elo,
                TotalMatches = user.TotalMatches,
                Wins = user.Wins,
                Loses = user.Loses,
                Draw = user.Draw,
                CreatedAt = user.CreatedAt,
                WinRate = winRate,
                Level = level,
                Rank = rank
            };
        }

        private string DetermineRank(int totalMatch, int elo)
        {
            if (totalMatch < 2) return "Unranked";
            return elo switch
            {
                < 199 => "Bronze III",
                < 299 => "Bronze II",
                < 399 => "Bronze I",
                < 499 => "Silver III",
                < 599 => "Silver II",
                < 699 => "Silver I",
                < 799 => "Gold III",
                < 899 => "Gold II",
                < 999 => "Gold I",
                < 1200 => "Platinum III",
                < 1300 => "Platinum II",
                < 1400 => "Platinum I",
                < 1500 => "Diamond III",
                < 1600 => "Diamond II",
                < 1700 => "Diamond I",
                < 1900 => "Master",
                < 2200 => "Senior Master",
                _ => "Grand Master"
            };
        }

        private int CalculateLevel(int exp)
        {
            int level = 1;
            int expNeeded = 0;

            while (true)
            {
                expNeeded += 100 * level * level;
                if (exp < expNeeded) break;
                level++;
            }

            return level;
        }

        public async Task<IEnumerable<UserProfileResponse>> SearchUsersAsync(string query, Guid currentUserId)
        {
            var users = await _context.SearchUsersAsync(query, currentUserId);
            var results = new List<UserProfileResponse>();
            
            foreach(var user in users) 
            {
                var friendship = await _friendshipRepo.GetFriendshipAsync(currentUserId, user.Id);
                string fStatus = "None";
                if (friendship != null) {
                    fStatus = friendship.Status.ToString();
                }

                results.Add(new UserProfileResponse
                {
                    Id = user.Id,
                    UserId = user.PlayerId,
                    Username = user.Username,
                    DisplayName = user.DisplayName,
                    AvatarUrl = user.AvatarUrl,
                    Experience = user.Experience,
                    Elo = user.Elo,
                    TotalMatches = user.TotalMatches,
                    Wins = user.Wins,
                    Loses = user.Loses,
                    Draw = user.Draw,
                    CreatedAt = user.CreatedAt,
                    WinRate = user.TotalMatches == 0 ? 0 : Math.Round((double)user.Wins / user.TotalMatches * 100, 2),
                    Level = CalculateLevel(user.Experience),
                    Rank = DetermineRank(user.TotalMatches, user.Elo),
                    FriendshipStatus = fStatus
                });
            }
            
            return results;
        }
    }
}