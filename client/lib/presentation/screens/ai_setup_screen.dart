import 'package:client/domain/enums/ai_difficulty.dart';
import 'package:client/domain/enums/color_preference.dart';
import 'package:client/domain/enums/time_control.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiSetupScreen extends ConsumerStatefulWidget {
  const AiSetupScreen({super.key});

  @override
  ConsumerState<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends ConsumerState<AiSetupScreen> {
  AiDifficulty _difficulty = AiDifficulty.medium;
  ColorPreference _color = ColorPreference.white;
  TimeControl _time = TimeControl.ten;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đăng ký listener: khi nhận AiGameStarted → navigate sang GameScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAiGameListener();
    });
  }

  void _setupAiGameListener() {
    // Lắng nghe state thay đổi → khi có matchId AI → navigate
    ref.listenManual(matchStateProvider, (prev, next) {
      if (next.isAiGame && next.matchId.isNotEmpty && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    });
  }

  Future<void> _startGame() async {
    setState(() => _isLoading = true);
    try {
      final signalR = ref.read(signalRServiceProvider);
      // Đảm bảo SignalR đang kết nối trước khi gửi lệnh
      await signalR.ensureConnected();
      await signalR.startAiGame(
        difficulty: _difficulty.value,
        colorPreference: _color.value,
        timeMinutes: _time.minutes,
      );
      // Navigation sẽ được trigger bởi listener ở trên
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đấu với Máy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════
            // Section 1: Chọn cấp độ
            // ═══════════════════════════════════════════
            _buildSectionTitle('🎯 Chọn cấp độ', colorScheme),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: AiDifficulty.values.map((d) {
                final isSelected = _difficulty == d;
                return GestureDetector(
                  onTap: () => setState(() => _difficulty = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withOpacity(0.3)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : Colors.white.withOpacity(0.08),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${d.icon} ${d.label}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            // ═══════════════════════════════════════════
            // Section 2: Chọn màu quân
            // ═══════════════════════════════════════════
            _buildSectionTitle('♟️ Chọn màu quân', colorScheme),
            const SizedBox(height: 12),
            Row(
              children: ColorPreference.values.map((c) {
                final isSelected = _color == c;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer.withOpacity(0.3)
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : Colors.white.withOpacity(0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(c.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              c.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            // ═══════════════════════════════════════════
            // Section 3: Chọn thời gian
            // ═══════════════════════════════════════════
            _buildSectionTitle('⏱️ Chọn thời gian', colorScheme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: TimeControl.values.map((t) {
                final isSelected = _time == t;
                return GestureDetector(
                  onTap: () => setState(() => _time = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withOpacity(0.3)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : Colors.white.withOpacity(0.08),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${t.icon} ${t.label}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),
            // ═══════════════════════════════════════════
            // Nút Bắt đầu trận đấu
            // ═══════════════════════════════════════════
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3C94D4), Color(0xFF2A7DB8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3C94D4).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _isLoading ? null : _startGame,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Bắt đầu trận đấu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}
