using System;
using System.Threading.Tasks;
using Moq;
using SeaChess.Application.Interfaces;
using SeaChess.Application.Services;
using SeaChess.Domain.Entities;
using SeaChess.Domain.Enums;
using Xunit;

namespace SeaChess.Tests
{
    public class FriendshipServiceTests
    {
        private readonly Mock<IFriendshipRepository> _mockFriendshipRepo;
        private readonly Mock<IUserRepository> _mockUserRepo;
        private readonly Mock<IUserService> _mockUserService;
        private readonly FriendshipService _service;

        public FriendshipServiceTests()
        {
            _mockFriendshipRepo = new Mock<IFriendshipRepository>();
            _mockUserRepo = new Mock<IUserRepository>();
            _mockUserService = new Mock<IUserService>();

            _service = new FriendshipService(
                _mockFriendshipRepo.Object,
                _mockUserRepo.Object,
                _mockUserService.Object
            );
        }

        [Fact]
        public async Task SendFriendRequestAsync_ShouldReturnFalse_WhenReceiverNotFound()
        {
            // Arrange
            var requesterId = Guid.NewGuid();
            var receiverUsername = "notfound";
            _mockUserRepo.Setup(repo => repo.GetByUsernameAsync(receiverUsername))
                .ReturnsAsync((User?)null);

            // Act
            var result = await _service.SendFriendRequestAsync(requesterId, receiverUsername);

            // Assert
            Assert.False(result);
            _mockFriendshipRepo.Verify(repo => repo.AddAsync(It.IsAny<Friendship>()), Times.Never);
        }

        [Fact]
        public async Task SendFriendRequestAsync_ShouldReturnFalse_WhenRequesterIsReceiver()
        {
            // Arrange
            var requesterId = Guid.NewGuid();
            var receiverUsername = "myself";
            var receiver = new User { Id = requesterId, Username = receiverUsername };
            _mockUserRepo.Setup(repo => repo.GetByUsernameAsync(receiverUsername))
                .ReturnsAsync(receiver);

            // Act
            var result = await _service.SendFriendRequestAsync(requesterId, receiverUsername);

            // Assert
            Assert.False(result);
            _mockFriendshipRepo.Verify(repo => repo.AddAsync(It.IsAny<Friendship>()), Times.Never);
        }

        [Fact]
        public async Task SendFriendRequestAsync_ShouldReturnFalse_WhenFriendshipExists()
        {
            // Arrange
            var requesterId = Guid.NewGuid();
            var receiverId = Guid.NewGuid();
            var receiverUsername = "friend";
            var receiver = new User { Id = receiverId, Username = receiverUsername };
            
            _mockUserRepo.Setup(repo => repo.GetByUsernameAsync(receiverUsername))
                .ReturnsAsync(receiver);
                
            _mockFriendshipRepo.Setup(repo => repo.GetFriendshipAsync(requesterId, receiverId))
                .ReturnsAsync(new Friendship { Status = FriendshipStatus.Pending });

            // Act
            var result = await _service.SendFriendRequestAsync(requesterId, receiverUsername);

            // Assert
            Assert.False(result);
            _mockFriendshipRepo.Verify(repo => repo.AddAsync(It.IsAny<Friendship>()), Times.Never);
        }

        [Fact]
        public async Task SendFriendRequestAsync_ShouldReturnTrue_AndAddFriendship()
        {
            // Arrange
            var requesterId = Guid.NewGuid();
            var receiverId = Guid.NewGuid();
            var receiverUsername = "newfriend";
            var receiver = new User { Id = receiverId, Username = receiverUsername };
            
            _mockUserRepo.Setup(repo => repo.GetByUsernameAsync(receiverUsername))
                .ReturnsAsync(receiver);
                
            _mockFriendshipRepo.Setup(repo => repo.GetFriendshipAsync(requesterId, receiverId))
                .ReturnsAsync((Friendship?)null);

            // Act
            var result = await _service.SendFriendRequestAsync(requesterId, receiverUsername);

            // Assert
            Assert.True(result);
            _mockFriendshipRepo.Verify(repo => repo.AddAsync(It.Is<Friendship>(f => 
                f.RequesterId == requesterId && 
                f.ReceiverId == receiverId && 
                f.Status == FriendshipStatus.Pending)), Times.Once);
        }

        [Fact]
        public async Task AcceptFriendRequestAsync_ShouldReturnFalse_WhenFriendshipNotFound()
        {
            // Arrange
            var receiverId = Guid.NewGuid();
            var requesterId = Guid.NewGuid();
            
            _mockFriendshipRepo.Setup(repo => repo.GetFriendshipAsync(requesterId, receiverId))
                .ReturnsAsync((Friendship?)null);

            // Act
            var result = await _service.AcceptFriendRequestAsync(receiverId, requesterId);

            // Assert
            Assert.False(result);
            _mockFriendshipRepo.Verify(repo => repo.UpdateAsync(It.IsAny<Friendship>()), Times.Never);
        }

        [Fact]
        public async Task AcceptFriendRequestAsync_ShouldReturnTrue_AndUpdateStatus()
        {
            // Arrange
            var receiverId = Guid.NewGuid();
            var requesterId = Guid.NewGuid();
            var friendship = new Friendship 
            { 
                RequesterId = requesterId, 
                ReceiverId = receiverId, 
                Status = FriendshipStatus.Pending 
            };
            
            _mockFriendshipRepo.Setup(repo => repo.GetFriendshipAsync(requesterId, receiverId))
                .ReturnsAsync(friendship);

            // Act
            var result = await _service.AcceptFriendRequestAsync(receiverId, requesterId);

            // Assert
            Assert.True(result);
            Assert.Equal(FriendshipStatus.Accepted, friendship.Status);
            _mockFriendshipRepo.Verify(repo => repo.UpdateAsync(friendship), Times.Once);
        }
    }
}
