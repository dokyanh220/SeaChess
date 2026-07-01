using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using SeaChess.Application.DTOs.Auth;
using SeaChess.Application.Interfaces;
using SeaChess.Domain.Entities;

namespace SeaChess.Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _context;
        private readonly IConfiguration _config;

        public AuthService(IUserRepository context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
        {
            if (await _context.ExistsByUsernameOrEmailAsync(req.Username, req.Email))
            {
                throw new Exception("Email or username already exists");
            }

            string passwordHash = BCrypt.Net.BCrypt.HashPassword(req.Password);

            var user = new User
            {
                Id = Guid.NewGuid(),
                Username = req.Username,
                DisplayName = req.Displayname,
                Email = req.Email,
                PasswordHash = passwordHash,
                Elo = 500,
                TotalMatches = 0,
                Wins = 0,
                Loses = 0,
                Draw = 0,
                EmailVerified = false,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            await _context.AddAsync(user);

            var token = GenerateJwtToken(user);
            return new AuthResponse { 
                Token = token, 
                UserId = user.Id, 
                Username = user.Username, 
                Displayname = user.DisplayName
            };
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest req)
        {
            var user = await _context.GetByUsernameAsync(req.Username);

            if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            {
                throw new Exception("Invalid username or password.");
            }

            var token = GenerateJwtToken(user);
            return new AuthResponse { 
                Token = token, 
                UserId = user.Id, 
                Username = user.Username, 
                Displayname = user.DisplayName
            };
        }

        private string GenerateJwtToken(User user)
        {
            var jwtSettings = _config.GetSection("JwtSettings");
            var key = Encoding.ASCII.GetBytes(jwtSettings["secrectKey"]!);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                   new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                   new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
                   new Claim("Displayname", user.DisplayName)
                }),
                Expires = DateTime.UtcNow.AddMinutes(double.Parse(jwtSettings["ExpirationMinutes"]!)),
                Issuer = jwtSettings["Issuer"],
                Audience = jwtSettings["Audience"],
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}