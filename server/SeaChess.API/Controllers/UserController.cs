using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SeaChess.Application.DTOs.User;
using SeaChess.Application.Interfaces;

namespace SeaChess.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly IUserService _service;

        public UserController(IUserService service)
        {
            _service = service;
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetMyProfile()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userIdClaim == null) return Unauthorized();

            var userProfle = await _service.GetUserProfileAsync(Guid.Parse(userIdClaim));
            if (userProfle == null) return NotFound();

            return Ok(userProfle);
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchUsers([FromQuery] string q)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userIdClaim == null) return Unauthorized();

            var currentUserId = Guid.Parse(userIdClaim);
            var users = await _service.SearchUsersAsync(q, currentUserId);

            return Ok(users);
        }

        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest req)
        {
            // Lấy từ jwt (claim 'sub')
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (userIdClaim == null) return Unauthorized();

            var userId = Guid.Parse(userIdClaim);

            var updatedProfile = await _service.UpdateProfileAsync(
                userId,
                req.Displayname,
                req.AvatarUrl
            );

            if (updatedProfile == null) return NotFound();

            return Ok(updatedProfile);
        }

        // [HttpPost("verify")]
    }
}