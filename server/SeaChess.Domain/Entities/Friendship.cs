using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SeaChess.Domain.Enums;

namespace SeaChess.Domain.Entities
{
    public class Friendship
    {
        public Guid Id { get; set; }
        public Guid RequesterId { get; set; }
        public Guid ReceiverId { get; set; }
        public FriendshipStatus Status { get; set; } = FriendshipStatus.Pending;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}