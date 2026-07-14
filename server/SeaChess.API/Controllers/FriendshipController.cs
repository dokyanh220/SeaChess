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
    public class FriendshipController : ControllerBase
    {
        private readonly IFriendshipService _friendshipService;

        public FriendshipController(IFriendshipService friendshipService)
        {
            _friendshipService = friendshipService;
        }

        private Guid GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userIdClaim == null) throw new UnauthorizedAccessException();
            return Guid.Parse(userIdClaim);
        }

        [HttpPost("request")]
        public async Task<IActionResult> SendFriendRequest([FromBody] SendFriendRequestDto request)
        {
            try
            {
                var userId = GetUserId();
                var success = await _friendshipService.SendFriendRequestAsync(userId, request.ReceiverUsername);
                if (!success) return BadRequest(new { message = "Cannot send friend request." });
                return Ok(new { message = "Friend request sent." });
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized();
            }
        }

        [HttpPost("accept/{requesterId}")]
        public async Task<IActionResult> AcceptFriendRequest(Guid requesterId)
        {
            try
            {
                var userId = GetUserId();
                var success = await _friendshipService.AcceptFriendRequestAsync(userId, requesterId);
                if (!success) return BadRequest(new { message = "Cannot accept friend request." });
                return Ok(new { message = "Friend request accepted." });
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized();
            }
        }

        [HttpPost("decline/{requesterId}")]
        public async Task<IActionResult> DeclineFriendRequest(Guid requesterId)
        {
            try
            {
                var userId = GetUserId();
                var success = await _friendshipService.DeclineFriendRequestAsync(userId, requesterId);
                if (!success) return BadRequest(new { message = "Cannot decline friend request." });
                return Ok(new { message = "Friend request declined." });
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized();
            }
        }

        [HttpPost("remove/{friendId}")]
        public async Task<IActionResult> RemoveFriend(Guid friendId)
        {
            try
            {
                var userId = GetUserId();
                var success = await _friendshipService.RemoveFriendAsync(userId, friendId);
                if (!success) return BadRequest(new { message = "Cannot remove friend." });
                return Ok(new { message = "Friend removed." });
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized();
            }
        }

        [HttpGet("list")]
        public async Task<IActionResult> GetFriends()
        {
            try
            {
                var userId = GetUserId();
                var friends = await _friendshipService.GetFriendsAsync(userId);
                return Ok(friends);
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized();
            }
        }

        [HttpGet("pending")]
        public async Task<IActionResult> GetPendingRequests()
        {
            try
            {
                var userId = GetUserId();
                var requests = await _friendshipService.GetPendingRequestsAsync(userId);
                return Ok(requests);
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized();
            }
        }
    }
}
