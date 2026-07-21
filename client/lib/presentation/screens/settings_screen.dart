import 'package:client/main.dart';
import 'package:client/core/services/local_storage_service.dart';
import 'package:client/presentation/screens/edit_profile_screen.dart';
import 'package:client/presentation/providers/theme_provider.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/match_history_provider.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/providers/notification_providers.dart';
import 'package:client/presentation/widgets/email_verification_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ===== Game =====
  bool _showMoves = true;
  bool _showCoordinates = true;
  bool _threefoldRepetition = true;

  // ===== Chung =====
  bool _moveSounds = true;
  bool _checkSounds = true;
  bool _vibrateOnCheck = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ========== TOP BAR ==========
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      'Cài đặt',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ========== ACCOUNT SECTION ==========
            SliverToBoxAdapter(
              child: _buildSectionHeader('Tài khoản', Icons.person_rounded, colorScheme),
            ),
            SliverToBoxAdapter(
              child: _buildAccountSection(colorScheme),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ========== GAME SECTION ==========
            SliverToBoxAdapter(
              child: _buildSectionHeader('Game', Icons.sports_esports_rounded, colorScheme),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsCard(colorScheme, [
                _buildSwitchTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Hiện nước đi',
                  subtitle: 'Hiển thị nước đi hợp lệ khi chọn quân',
                  value: _showMoves,
                  onChanged: (v) => setState(() => _showMoves = v),
                  colorScheme: colorScheme,
                ),
                _buildDivider(colorScheme),
                _buildSwitchTile(
                  icon: Icons.grid_on_rounded,
                  title: 'Hiện trục tọa độ',
                  subtitle: 'Hiển thị ký hiệu a–h, 1–8 trên bàn cờ',
                  value: _showCoordinates,
                  onChanged: (v) => setState(() => _showCoordinates = v),
                  colorScheme: colorScheme,
                ),
                _buildDivider(colorScheme),
                _buildSwitchTile(
                  icon: Icons.repeat_rounded,
                  title: 'Luật lặp lại 3 lần',
                  subtitle: 'Tự động hòa khi trạng thái lặp lại 3 lần',
                  value: _threefoldRepetition,
                  onChanged: (v) => setState(() => _threefoldRepetition = v),
                  colorScheme: colorScheme,
                ),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ========== GENERAL SECTION ==========
            SliverToBoxAdapter(
              child: _buildSectionHeader('Chung', Icons.tune_rounded, colorScheme),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsCard(colorScheme, [
                _buildSwitchTile(
                  icon: Icons.volume_up_rounded,
                  title: 'Âm thanh nước đi',
                  subtitle: 'Phát âm thanh khi di chuyển quân cờ',
                  value: _moveSounds,
                  onChanged: (v) => setState(() => _moveSounds = v),
                  colorScheme: colorScheme,
                ),
                _buildDivider(colorScheme),
                _buildSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Âm thanh Chiếu',
                  subtitle: 'Phát âm thanh đặc biệt khi bị chiếu tướng',
                  value: _checkSounds,
                  onChanged: (v) => setState(() => _checkSounds = v),
                  colorScheme: colorScheme,
                ),
                _buildDivider(colorScheme),
                _buildSwitchTile(
                  icon: Icons.vibration_rounded,
                  title: 'Rung khi chiếu',
                  subtitle: 'Rung thiết bị khi bị chiếu tướng',
                  value: _vibrateOnCheck,
                  onChanged: (v) => setState(() => _vibrateOnCheck = v),
                  colorScheme: colorScheme,
                ),
                _buildDivider(colorScheme),
                _buildSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Chế độ Tối',
                  subtitle: 'Giao diện tối (Dark Mode)',
                  value: ref.watch(themeModeProvider) == ThemeMode.dark ||
                      (ref.watch(themeModeProvider) == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness == Brightness.dark),
                  onChanged: (v) {
                    ref.read(themeModeProvider.notifier).toggleTheme(context);
                  },
                  colorScheme: colorScheme,
                ),
                _buildDivider(colorScheme),
                _buildNavigationTile(
                  icon: Icons.shield_outlined,
                  title: 'Quyền riêng tư',
                  subtitle: 'Quản lý thông tin hiển thị của bạn',
                  colorScheme: colorScheme,
                ),
                _buildDivider(colorScheme),
                _buildNavigationTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Đánh giá',
                  subtitle: 'Đánh giá SeaChess trên Store',
                  colorScheme: colorScheme,
                ),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showLogoutConfirm(context, colorScheme),
                    icon: Icon(Icons.logout_rounded, color: colorScheme.error, size: 20),
                    label: Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ========== VERSION ==========
            SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'SeaChess v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ===== HELPER WIDGETS =====

  Widget _buildAccountSection(ColorScheme colorScheme) {
    final profileAsync = ref.watch(userProfileProvider);
    final isGuest = profileAsync.asData?.value?.isGuest ?? false;

    if (isGuest) {
      return _buildSettingsCard(colorScheme, [
        _buildNavigationTile(
          icon: Icons.app_registration_rounded,
          title: 'Đăng ký tài khoản',
          subtitle: 'Lưu trữ thông tin và lịch sử trận đấu',
          colorScheme: colorScheme,
          iconColor: Colors.blue,
          onTap: () {
             // Show upgrade modal or navigate to a special register screen
             // Will implement UpgradeModal soon
             _showUpgradeModal(context, colorScheme);
          },
        ),
        _buildDivider(colorScheme),
        _buildNavigationTile(
          icon: Icons.login_rounded,
          title: 'Đăng nhập',
          subtitle: 'Sử dụng tài khoản đã có (sẽ mất dữ liệu Khách)',
          colorScheme: colorScheme,
          iconColor: Colors.green,
          onTap: () {
            _showLogoutConfirm(context, colorScheme, isLogin: true);
          },
        ),
      ]);
    }

    return _buildSettingsCard(colorScheme, [
      _buildNavigationTile(
        icon: Icons.edit_rounded,
        title: 'Chỉnh sửa hồ sơ',
        subtitle: 'Đổi tên hiển thị, ảnh đại diện',
        colorScheme: colorScheme,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ).then((_) {
            ref.invalidate(userProfileProvider);
          });
        },
      ),
      _buildDivider(colorScheme),
      _buildEmailVerificationTile(colorScheme),
      _buildDivider(colorScheme),
      _buildConnectTile(
        icon: Icons.facebook_rounded,
        title: 'Kết nối với Facebook',
        iconColor: const Color(0xFF1877F2),
        colorScheme: colorScheme,
      ),
      _buildDivider(colorScheme),
      _buildConnectTile(
        icon: Icons.g_mobiledata_rounded,
        title: 'Kết nối với Google',
        iconColor: const Color(0xFFEA4335),
        colorScheme: colorScheme,
      ),
    ]);
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: colorScheme.tertiary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ColorScheme colorScheme, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colorScheme.onSurface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.tertiary,
            activeTrackColor: colorScheme.tertiary.withValues(alpha: 0.3),
            inactiveThumbColor: colorScheme.outline,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tính năng đang phát triển'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.onSurface).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? colorScheme.onSurface),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// Tile xác thực email — hiện trạng thái verified / chưa verified
  Widget _buildEmailVerificationTile(ColorScheme colorScheme) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final isVerified = profile.emailVerified;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isVerified
              ? null
              : () {
                  final authRepo = ref.read(authRepositoryProvider);
                  EmailVerificationModal.show(
                    context,
                    () => authRepo.resendVerificationEmail(),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isVerified ? Icons.verified_rounded : Icons.email_outlined,
                    size: 20,
                    color: isVerified ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác thực email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVerified
                            ? 'Email đã được xác thực ✓'
                            : 'Nhấn để gửi email xác thực',
                        style: TextStyle(
                          fontSize: 12,
                          color: isVerified ? Colors.green : Colors.orange,
                          fontWeight: isVerified ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Xác thực',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildConnectTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tính năng đang phát triển'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Liên kết',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, ColorScheme colorScheme, {bool isLogin = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isLogin ? 'Đăng nhập' : 'Đăng xuất',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          isLogin
              ? 'Tài khoản Khách hiện tại và lịch sử đấu sẽ bị xóa. Bạn có chắc muốn tiếp tục để Đăng nhập tài khoản khác?'
              : 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: TextStyle(color: colorScheme.outline)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isLogin ? Colors.blue : colorScheme.error),
            onPressed: () async {
              // Ngắt kết nối SignalR trước
              await ref.read(signalRServiceProvider).disconnect();

              // Xóa token lưu trữ
              await LocalStorageService().removeToken();

              // Reset cache các provider dữ liệu người dùng
              ref.invalidate(userProfileProvider);
              ref.invalidate(matchHistoryProvider);
              ref.invalidate(notificationStateProvider);
              ref.invalidate(matchStateProvider);

              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
            child: Text(isLogin ? 'Tiếp tục' : 'Đăng xuất', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpgradeModal(BuildContext context, ColorScheme colorScheme) {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final displaynameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Consumer(
          builder: (ctx, ref, _) {
            final isLoading = ref.watch(authNotifierProvider);
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đăng ký tài khoản',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nâng cấp để lưu trữ thông tin, kết bạn và chat!',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên đăng nhập',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: displaynameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên hiển thị',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) => v!.length < 6 ? 'Ít nhất 6 ký tự' : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                final success = await ref
                                    .read(authNotifierProvider.notifier)
                                    .upgradeGuest(
                                      usernameController.text.trim(),
                                      passwordController.text.trim(),
                                      emailController.text.trim(),
                                      displaynameController.text.trim(),
                                    );

                                if (success && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nâng cấp tài khoản thành công!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  ref.invalidate(userProfileProvider);
                                } else if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nâng cấp thất bại, email hoặc tên đăng nhập có thể đã tồn tại.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
