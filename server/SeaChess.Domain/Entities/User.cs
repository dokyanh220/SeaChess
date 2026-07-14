namespace SeaChess.Domain.Entities
{
    public class User
    {
        public Guid Id { get; set; }   
        public string PlayerId { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public int TotalMatches { get; set; }
        public int Experience { get; set; } = 0;
        public int Wins { get; set; }
        public int Loses { get; set; }
        public int Draw { get; set; }
        public int Elo { get; set; } = 799;
        public bool EmailVerified { get; set; } = false;
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}