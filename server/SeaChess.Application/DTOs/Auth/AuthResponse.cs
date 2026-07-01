namespace SeaChess.Application.DTOs.Auth
{
    public class AuthResponse
    {
        public string Token { get; set; } = string.Empty;
        public Guid Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Displayname { get; set; } = string.Empty;
        public string Elo { get; set; } = string.Empty;
    }
}