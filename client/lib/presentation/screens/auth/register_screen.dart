import 'package:client/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/presentation/widgets/primary_button.dart';

// Provider tạm thời quản lý trạng thái loading cho màn hình Đăng ký
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _registerScreenState();
}

class _registerScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.primary), // Nút quay lại mặc định của Flutter
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text(
                'Tạo tài khoản',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
              Text(
                'Tham gia SeaChess ngay',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),

              // Ô nhập Tên đăng nhập
              TextFormField(
                controller: _usernameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Ô nhập Tên hiển thị
              TextFormField(
                controller: _displayNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị (Tên trong game)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Ô nhập Email
              TextFormField(
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Ô nhập Mật khẩu
              TextFormField(
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Ô Xác nhận Mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !isLoading,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Nút Đăng Ký
              PrimaryButton(
                text: 'Đăng ký',
                isLoading: isLoading,
                onPressed: () async {
                  final user = _usernameController.text.trim();
                  final displayName = _displayNameController.text.trim();
                  final email = _emailController.text.trim();
                  final pass = _passwordController.text.trim();
                  final confirmPass = _confirmPasswordController.text.trim();

                  if (user.isEmpty ||
                      email.isEmpty ||
                      pass.isEmpty ||
                      displayName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đủ thông tin!')),
                    );
                    return;
                  }

                  if (pass.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mật khẩu tối thiểu 6 ký tự')),
                    );
                    return;
                  }

                  if (pass != confirmPass) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mật khẩu xác nhận không khớp!')),
                    );
                    return;
                  }

                  final success = await ref
                      .read(authNotifierProvider.notifier)
                      .register(user, pass, email, displayName);

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng ký thành công! Hãy đăng nhập.'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng ký thất bại. Lỗi hệ thống'),
                        backgroundColor: AppTheme.dangerRed,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),
              
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Đã có tài khoản? Đăng nhập',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
