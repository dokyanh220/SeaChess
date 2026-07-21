namespace SeaChess.Application.Interfaces
{
    public interface IEmailService
    {
        /// <summary>
        /// Gửi email xác thực cho user mới đăng ký
        /// </summary>
        /// <param name="toEmail">Email người nhận</param>
        /// <param name="username">Tên user để chào</param>
        /// <param name="verificationLink">Link xác thực đầy đủ</param>
        Task SendVerificationEmailAsync(string toEmail, string username, string verificationLink);
    }
}
