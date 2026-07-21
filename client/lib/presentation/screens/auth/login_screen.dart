import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/screens/main_screen.dart';
import 'package:client/presentation/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/presentation/widgets/primary_button.dart';

// Một StateProvider tạm thời để quản lý trạng thái nút bấm (Loading)
// Ở bước sau, chúng ta sẽ thay thế nó bằng một AuthNotifier thực thụ kết nối với API.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _loginScreenState();
}

class _loginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SeaChess',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXXl),

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
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : () {},
                  child: Text(
                    'Quên mật khẩu?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Nút "Đăng nhập"
              PrimaryButton(
                text: 'Đăng nhập',
                isLoading: isLoading,
                onPressed: () async {
                  final user = _usernameController.text.trim();
                  final pass = _passwordController.text.trim();

                  if (user.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                    );
                    return;
                  }

                  final success = await ref
                      .read(authNotifierProvider.notifier)
                      .login(user, pass);

                  if (success && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng nhập thất bại. Vui lòng kiểm tra lại'),
                        backgroundColor: AppTheme.dangerRed,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Nút chuyển sang Đăng ký
              PrimaryButton(
                text: 'Tạo tài khoản mới',
                isSecondary: true,
                isLoading: isLoading,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Nút Chơi ngay (Guest)
              PrimaryButton(
                text: 'Chơi ngay (Khách)',
                isSecondary: true,
                isLoading: isLoading,
                onPressed: () async {
                  final success = await ref
                      .read(authNotifierProvider.notifier)
                      .guestLogin();

                  if (success && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể tạo tài khoản Khách'),
                        backgroundColor: AppTheme.dangerRed,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
