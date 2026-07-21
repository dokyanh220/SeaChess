using System.ComponentModel.DataAnnotations;

namespace SeaChess.Application.DTOs.User
{
    public class UpdateProfileRequest
    {
        [MaxLength(50, ErrorMessage = "Tên hiển thị tối đa 50 ký tự")]
        public string? Displayname { get; set; }

        public string? AvatarUrl { get; set; }
    }
}