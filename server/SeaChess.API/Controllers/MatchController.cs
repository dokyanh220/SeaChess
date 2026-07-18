using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SeaChess.Application.Interfaces;

namespace SeaChess.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MatchController : ControllerBase
    {
        private readonly IMatchService _matchService;

        public MatchController(IMatchService matchService)
        {
            _matchService = matchService;
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory([FromQuery] int limit = 20)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var userId))
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            // Theo yêu cầu hiển thị max 20 trận
            if (limit > 50) limit = 50;
            if (limit <= 0) limit = 20;

            var history = await _matchService.GetMatchHistoryAsync(userId, limit);
            return Ok(history);
        }

        [HttpPost("ai-result")]
        public async Task<IActionResult> SaveAiMatch([FromBody] SeaChess.Application.DTOs.Match.AiMatchResultDto dto)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var userId))
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            try
            {
                var response = await _matchService.SaveAiMatchResultAsync(userId, dto);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
