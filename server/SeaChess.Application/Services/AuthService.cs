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
        private readonly IEmailService _emailService;

        public AuthService(IUserRepository context, IConfiguration config, IEmailService emailService)
        {
            _context = context;
            _config = config;
            _emailService = emailService;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
        {
            if (await _context.ExistsByUsernameOrEmailAsync(req.Username, req.Email))
            {
                throw new Exception("Email or username already exists");
            }

            string passwordHash = BCrypt.Net.BCrypt.HashPassword(req.Password);

            var random = new Random();
            string playerId;
            bool exists;
            do
            {
                playerId = random.Next(10000000, 99999999).ToString();
                exists = await _context.ExistsByPlayerIdAsync(playerId);
            } while (exists);

            var user = new User
            {
                Id = Guid.NewGuid(),
                PlayerId = playerId,
                Username = req.Username,
                DisplayName = req.Displayname,
                Email = req.Email,
                PasswordHash = passwordHash,
                Experience = 0,
                Elo = 0,
                TotalMatches = 0,
                Wins = 0,
                Loses = 0,
                Draw = 0,
                EmailVerified = false,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            await _context.AddAsync(user);

            // Gửi email xác thực sau khi đăng ký (không fail registration nếu lỗi gửi email)
            try
            {
                await SendVerificationEmailAsync(user.Id);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Warning] Không gửi được email xác thực: {ex.Message}");
            }

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

        // ── Guest Mode ─────────────────────────────────────────────

        public async Task<AuthResponse> GuestLoginAsync()
        {
            var random = new Random();
            string playerId;
            bool exists;
            do
            {
                playerId = random.Next(10000000, 99999999).ToString();
                exists = await _context.ExistsByPlayerIdAsync(playerId);
            } while (exists);

            var guestId = Guid.NewGuid();
            var user = new User
            {
                Id = guestId,
                PlayerId = playerId,
                Username = "guest_" + guestId.ToString("N")[..12],
                DisplayName = "Khách " + playerId,
                Email = string.Empty,
                PasswordHash = string.Empty,
                Experience = 0,
                Elo = 0,
                TotalMatches = 0,
                Wins = 0,
                Loses = 0,
                Draw = 0,
                EmailVerified = false,
                IsActive = true,
                IsGuest = true, // Quan trọng
                CreatedAt = DateTime.UtcNow
            };

            await _context.AddAsync(user);

            var token = GenerateJwtToken(user);
            return new AuthResponse
            {
                Token = token,
                UserId = user.Id,
                Username = user.Username,
                Displayname = user.DisplayName
            };
        }

        public async Task<AuthResponse> UpgradeGuestAsync(Guid guestId, RegisterRequest req)
        {
            var user = await _context.GetByIdAsync(guestId);
            if (user == null || !user.IsGuest)
            {
                throw new Exception("Invalid guest account.");
            }

            if (await _context.ExistsByUsernameOrEmailAsync(req.Username, req.Email))
            {
                throw new Exception("Email or username already exists.");
            }

            user.Username = req.Username;
            user.Email = req.Email;
            user.DisplayName = req.Displayname;
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password);
            user.IsGuest = false;
            user.UpdatedAt = DateTime.UtcNow;

            await _context.UpdateAsync(user);

            try
            {
                await SendVerificationEmailAsync(user.Id);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Warning] Không gửi được email xác thực: {ex.Message}");
            }

            var token = GenerateJwtToken(user);
            return new AuthResponse
            {
                Token = token,
                UserId = user.Id,
                Username = user.Username,
                Displayname = user.DisplayName
            };
        }

        // ── Email Verification ──────────────────────────────────────

        /// <summary>
        /// Gửi email xác thực cho user
        /// </summary>
        public async Task<bool> SendVerificationEmailAsync(Guid userId)
        {
            var user = await _context.GetByIdAsync(userId);
            if (user == null || user.EmailVerified) return false;

            var token = GenerateEmailVerificationToken(userId);
            var baseUrl = _config["AppSettings:BaseUrl"] ?? "http://localhost:5039";
            var verificationLink = $"{baseUrl}/api/auth/verify-email?token={token}";

            await _emailService.SendVerificationEmailAsync(
                user.Email, user.Username, verificationLink);

            return true;
        }

        /// <summary>
        /// Xác thực email từ token trong link
        /// </summary>
        public async Task<bool> VerifyEmailAsync(string token)
        {
            try
            {
                var jwtSettings = _config.GetSection("JwtSettings");
                var key = Encoding.ASCII.GetBytes(jwtSettings["SecretKey"]!);

                // Validate token
                var handler = new JwtSecurityTokenHandler();
                var principal = handler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = jwtSettings["Issuer"],
                    ValidateAudience = true,
                    ValidAudience = jwtSettings["Audience"],
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                }, out _);

                // Kiểm tra purpose claim — chống token confusion attack
                var purposeClaim = principal.FindFirst("purpose")?.Value;
                if (purposeClaim != "email_verification") return false;

                // Lấy userId từ token
                var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (userIdClaim == null) return false;

                var user = await _context.GetByIdAsync(Guid.Parse(userIdClaim));
                if (user == null || user.EmailVerified) return false;

                // Cập nhật trạng thái
                user.EmailVerified = true;
                user.UpdatedAt = DateTime.UtcNow;
                await _context.UpdateAsync(user);

                return true;
            }
            catch
            {
                return false; // Token hết hạn hoặc không hợp lệ
            }
        }

        // ── Token Generation ────────────────────────────────────────

        private string GenerateJwtToken(User user)
        {
            var jwtSettings = _config.GetSection("JwtSettings");
            var key = Encoding.ASCII.GetBytes(jwtSettings["secretKey"]!);

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

        /// <summary>
        /// JWT token riêng cho verify email — hết hạn 24 giờ, có claim "purpose"
        /// </summary>
        private string GenerateEmailVerificationToken(Guid userId)
        {
            var jwtSettings = _config.GetSection("JwtSettings");
            var key = Encoding.ASCII.GetBytes(jwtSettings["SecretKey"]!);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
                    new Claim("purpose", "email_verification") // Phân biệt với login token
                }),
                Expires = DateTime.UtcNow.AddHours(24),
                Issuer = jwtSettings["Issuer"],
                Audience = jwtSettings["Audience"],
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature)
            };

            var handler = new JwtSecurityTokenHandler();
            return handler.WriteToken(handler.CreateToken(tokenDescriptor));
        }
    }
}