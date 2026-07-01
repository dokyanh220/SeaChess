using System.Runtime.InteropServices;
using SeaChess.Application.DTOs.User;
using SeaChess.Application.Interfaces;

namespace SeaChess.Application.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _context;

        public UserService(IUserRepository context)
        {
            _context = context;
        }

        public async Task<UserProfileResponse> GetUserProfileAsync(Guid userId)
        {
            var user = await _context.GetByIdAsync(userId);
            if (user == null) return null;

            double winRate = user.TotalMatches == 0
                ? 0
                : Math.Round((double)user.Wins / user.TotalMatches * 100, 2);
            int level = Math.Max(1, (user.Experience / 1000) + 1);
            string rank = DetermineRank(user.Elo);

            return new UserProfileResponse
            {
                UserId = user.Id,
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

        private string DetermineRank(int elo)
        {
            return elo switch
            {
                < 800 => "Unranked",
                < 1200 => "Bronze",
                < 1600 => "Silver",
                < 2000 => "Gold",
                < 2400 => "Platinum",
                < 2800 => "Diamond",
                < 3200 => "Master",
                _ => "Legend"
            };
        }
    }
}