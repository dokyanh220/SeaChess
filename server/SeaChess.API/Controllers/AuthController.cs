using Microsoft.AspNetCore.Mvc;
using SeaChess.Application.Interfaces;
using SeaChess.Application.DTOs.Auth;
using Microsoft.AspNetCore.Authorization;

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
    }
}