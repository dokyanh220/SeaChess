using SeaChess.Application.DTOs.Auth;

namespace SeaChess.Application.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse> LoginAsync(LoginRequest request);
        Task<bool> SendVerificationEmailAsync(Guid userId);
        Task<bool> VerifyEmailAsync(string token);
    }
}