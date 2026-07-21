namespace SeaChess.Application.DTOs.User
{
    public class UserProfileResponse
    {
        public Guid Id { get; set; } // Keep internal Guid if needed, or just change UserId to string
        public string UserId { get; set; } = string.Empty; // This will map to PlayerId
        public string Username { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public int Experience { get; set; }
        public int Elo { get; set; }
        public int TotalMatches { get; set; }
        public int Wins { get; set; }
        public int Loses { get; set; }
        public int Draw { get; set; }
        public DateTime CreatedAt { get; set; }  

        // Tính toán trong service k có trên db
        public double WinRate { get; set; }
        public int Level { get; set; }
        public string Rank { get; set; } = string.Empty;
        public bool EmailVerified { get; set; }
        public string FriendshipStatus { get; set; } = "None"; // None, Pending, Accepted, Rejected
    }
}