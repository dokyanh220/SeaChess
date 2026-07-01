using Microsoft.Extensions.Configuration;
using SeaChess.Application.DTOs.Auth;
using SeaChess.Application.Interfaces;
using SeaChess.Infrastructure.Data;

namespace SeaChess.Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthService(ApplicationDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
        {
            
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest req)
        {
            
        }
    }
}