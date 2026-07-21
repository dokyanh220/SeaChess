using Microsoft.AspNetCore.Mvc;
using SeaChess.Application.Interfaces;
using SeaChess.Application.DTOs.Auth;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace SeaChess.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _service;

        public AuthController(IAuthService service)
        {
            _service = service;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest req)
        {
            try
            {
                var res = await _service.RegisterAsync(req);
                return Ok(res);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            try
            {
                var response = await _service.LoginAsync(req);
                return Ok(response);   
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [Authorize]
        [HttpDelete("logout")]
        public IActionResult Logout()
        {
            return Ok(new { Message = "Bye bye" });
        }

        // ── Email Verification Endpoints ────────────────────────

        /// <summary>
        /// Gửi lại email xác thực (user nhấn nút trên app)
        /// </summary>
        [Authorize]
        [HttpPost("send-verification")]
        public async Task<IActionResult> SendVerificationEmail()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userIdClaim == null) return Unauthorized();

            var success = await _service.SendVerificationEmailAsync(Guid.Parse(userIdClaim));
            if (!success)
                return BadRequest(new { message = "Không thể gửi email xác thực. Email có thể đã được xác thực." });

            return Ok(new { message = "Email xác thực đã được gửi!" });
        }

        /// <summary>
        /// Xác thực email từ link trong email (mở trên browser → trả HTML)
        /// </summary>
        [AllowAnonymous]
        [HttpGet("verify-email")]
        public async Task<IActionResult> VerifyEmail([FromQuery] string token)
        {
            var success = await _service.VerifyEmailAsync(token);

            if (success)
            {
                return Content(@"
                    <html>
                    <head><meta charset='utf-8'/><meta name='viewport' content='width=device-width, initial-scale=1'/></head>
                    <body style='font-family: Arial, sans-serif; text-align: center; padding: 60px 20px;
                                 background: linear-gradient(135deg, #e8f5e9, #f1f8e9);'>
                        <div style='max-width: 400px; margin: auto; background: white; padding: 40px;
                                    border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);'>
                            <div style='font-size: 64px;'>✅</div>
                            <h1 style='color: #2e7d32; margin: 16px 0;'>Xác thực thành công!</h1>
                            <p style='color: #555;'>Email của bạn đã được xác thực.<br/>Quay lại app SeaChess để tiếp tục chơi cờ! ♟</p>
                        </div>
                    </body>
                    </html>", "text/html");
            }

            return Content(@"
                <html>
                <head><meta charset='utf-8'/><meta name='viewport' content='width=device-width, initial-scale=1'/></head>
                <body style='font-family: Arial, sans-serif; text-align: center; padding: 60px 20px;
                             background: linear-gradient(135deg, #ffebee, #fce4ec);'>
                    <div style='max-width: 400px; margin: auto; background: white; padding: 40px;
                                border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);'>
                        <div style='font-size: 64px;'>❌</div>
                        <h1 style='color: #c62828; margin: 16px 0;'>Link không hợp lệ</h1>
                        <p style='color: #555;'>Link đã hết hạn hoặc đã được sử dụng.<br/>Vui lòng gửi lại email xác thực từ app.</p>
                    </div>
                </body>
                </html>", "text/html");
        }
    }
}