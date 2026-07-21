import 'package:flutter/material.dart';

/// Modal hiển thị trạng thái gửi email xác thực
/// Có 3 trạng thái: đang gửi (loading), thành công, thất bại
class EmailVerificationModal extends StatelessWidget {
  final Future<bool> Function() onSendEmail;

  const EmailVerificationModal({
    super.key,
    required this.onSendEmail,
  });

  /// Hiển thị modal từ bất kỳ đâu
  static Future<void> show(BuildContext context, Future<bool> Function() onSendEmail) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmailVerificationModal(onSendEmail: onSendEmail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: FutureBuilder<bool>(
        future: onSendEmail(),
        builder: (context, snapshot) {
          // ── Đang gửi ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Đang gửi email xác thực...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng đợi trong giây lát',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final success = snapshot.data == true;

          // ── Thành công / Thất bại ──
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: success
                        ? Colors.green.withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                  ),
                  child: Icon(
                    success ? Icons.mark_email_read_rounded : Icons.error_outline_rounded,
                    size: 36,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 20),

                // Tiêu đề
                Text(
                  success ? 'Đã gửi email xác thực!' : 'Gửi thất bại',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Mô tả
                Text(
                  success
                      ? 'Kiểm tra hộp thư email của bạn và nhấn vào link xác thực.\n\nNếu không thấy email, hãy kiểm tra thư mục Spam.'
                      : 'Không thể gửi email xác thực.\nEmail có thể đã được xác thực hoặc hệ thống đang gặp sự cố.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Nút đóng
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: success ? Colors.green : colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      success ? 'Đã hiểu' : 'Đóng',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
