using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using SeaChess.Application.Interfaces;

namespace SeaChess.Infrastructure.Services
{
    public class SmtpEmailService : IEmailService
    {
        private readonly IConfiguration _config;

        public SmtpEmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendVerificationEmailAsync(
            string toEmail, string username, string verificationLink)
        {
            var emailSettings = _config.GetSection("EmailSettings");

            // Tạo SMTP client
            using var smtp = new SmtpClient
            {
                Host = emailSettings["SmtpHost"]!,            // vd: "smtp.gmail.com"
                Port = int.Parse(emailSettings["SmtpPort"]!), // vd: 587
                EnableSsl = true,
                Credentials = new NetworkCredential(
                    emailSettings["SenderEmail"],
                    emailSettings["SenderPassword"]            // App Password 16 ký tự
                )
            };

            // Tạo email HTML
            var message = new MailMessage
            {
                From = new MailAddress(emailSettings["SenderEmail"]!, "SeaChess"),
                Subject = "🔐 Xác thực email SeaChess",
                IsBodyHtml = true,
                Body = $@"
                    <div style='font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 20px;
                                border: 1px solid #e0e0e0; border-radius: 12px;'>
                        <h2 style='color: #1a73e8; text-align: center;'>♟ SeaChess</h2>
                        <p>Chào <strong>{username}</strong>! 👋</p>
                        <p>Cảm ơn bạn đã đăng ký tài khoản SeaChess.</p>
                        <p>Nhấn nút bên dưới để xác thực email của bạn:</p>
                        <div style='text-align: center; margin: 24px 0;'>
                            <a href='{verificationLink}'
                               style='display: inline-block; padding: 14px 28px;
                                      background: linear-gradient(135deg, #1a73e8, #0d47a1);
                                      color: white; text-decoration: none; border-radius: 8px;
                                      font-weight: bold; font-size: 16px;'>
                                ✉️ Xác thực Email
                            </a>
                        </div>
                        <hr style='border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;'/>
                        <p style='color: #888; font-size: 12px; text-align: center;'>
                            Link này sẽ hết hạn sau 24 giờ.<br/>
                            Nếu bạn không đăng ký tài khoản, hãy bỏ qua email này.
                        </p>
                    </div>"
            };

            message.To.Add(toEmail);

            // Gửi email
            await smtp.SendMailAsync(message);
        }
    }
}
