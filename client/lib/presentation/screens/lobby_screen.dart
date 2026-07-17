import 'dart:async';

import 'package:client/domain/utils/rank_helper.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/screens/game_screen.dart';
import 'package:client/presentation/screens/ai_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _isConnecting = false;
  bool _isSearching = false;

  // Stopwatch đếm thời gian tìm trận
  Timer? _searchTimer;
  int _searchSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initSignalR();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSignalR() async {
    setState(() => _isConnecting = true);

    try {
      final signalR = ref.read(signalRServiceProvider);

      await signalR.connect();
      print("[Client] kết nối thành công");

      signalR.onMatchStarted((args) {
        if (args == null || args.length < 3) return;
        print("[Client] Ghép trận thành công");

        final matchId = args[0].toString();
        final initialFen = args[1].toString();
        final color = args[2].toString();

        Map<String, dynamic> opponentInfo = {};
        if (args.length > 3 && args[3] is Map) {
          opponentInfo = args[3] as Map<String, dynamic>;
        }

        ref
            .read(matchStateProvider.notifier)
            .initMatch(matchId, initialFen, color, opponentInfo);

        _stopSearchTimer();
        setState(() => _isSearching = false);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          ).then((_) {
            // Khi từ GameScreen quay về LobbyScreen, cần lấy lại profile
            ref.invalidate(userProfileProvider);
          });
        }
      });
    } catch (e) {
      print("[Client] Lỗi kết nối: $e");
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  void _startSearchTimer() {
    _searchSeconds = 0;
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _searchSeconds++);
    });
  }

  void _stopSearchTimer() {
    _searchTimer?.cancel();
    _searchSeconds = 0;
  }

  String _formatSearchTime() {
    int minutes = _searchSeconds ~/ 60;
    int seconds = _searchSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi tải profile: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Không tìm thấy thông tin'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // ========== HEADER ==========
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SeaChess',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ========== PROFILE CARD ==========
                  _buildProfileCard(profile, colorScheme),
                  const SizedBox(height: 12),

                  // ========== STATS PANEL ==========
                  _buildStatsPanel(profile, colorScheme),
                  const SizedBox(height: 16),

                  // ========== EXP BAR ==========
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildExpBar(profile, colorScheme),
                  ),
                  const SizedBox(height: 24),

                  // ========== MATCHMAKING ==========
                  _buildMatchmakingSection(colorScheme),

                  // ========== CONNECTING STATUS ==========
                  if (_isConnecting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Đang kết nối Server...',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic profile, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bên trái: Tên, ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${profile.userId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Bên phải: Icon rank + tên rank + progress bar elo
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      RankHelper.getRankLargeAssetPath(profile.rank),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.shield,
                        size: 30,
                        color: Color(RankHelper.getRankColor(profile.rank)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile.rank,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(RankHelper.getRankColor(profile.rank)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final int currentElo = profile.elo as int;
                  // Giả lập mốc Elo tiếp theo (target) là bội số của 100 tiếp theo
                  final int targetElo = ((currentElo ~/ 100) + 1) * 100;
                  final double progress = (currentElo % 100) / 100.0;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Elo: $currentElo / $targetElo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Progress bar Elo
                      Container(
                        width: 100,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(RankHelper.getRankColor(profile.rank)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge hiển thị label + value
  Widget _buildBadge(
    String label,
    String value,
    Color accentColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge cho Rank với icon nhỏ
  Widget _buildRankBadge(String rank, ColorScheme colorScheme) {
    final rankColor = Color(RankHelper.getRankColor(rank));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: rankColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rankColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Image.asset(
              RankHelper.getRankAssetPath(rank),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.shield, size: 14, color: rankColor),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rank,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: rankColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh EXP progress bar
  Widget _buildExpBar(dynamic profile, ColorScheme colorScheme) {
    final progress = profile.expProgress as double;
    final currentExp = profile.currentLevelExp as int;
    final maxExp = profile.expForNextLevel as int;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            Text(
              '$currentExp / $maxExp',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                  ),
                ),
                // Progress fill
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Panel thống kê: TotalMatches, WinRate, Wins, Losses, Draws
  Widget _buildStatsPanel(dynamic profile, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Cấp độ',
                  '${profile.level}',
                  colorScheme.primary,
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Trận đấu',
                  '${profile.totalMatches}',
                  colorScheme.onSurface,
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Tỉ lệ thắng',
                  '${profile.winRate.toStringAsFixed(1)}%',
                  colorScheme.tertiary,
                  colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Thắng',
                  '${profile.wins}',
                  const Color(0xFF4ADE80),
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Thua',
                  '${profile.loses}',
                  const Color(0xFFFF6B6B),
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Hòa',
                  '${profile.draws}',
                  const Color(0xFFFFB95F),
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Từng stat item
  Widget _buildStatItem(
    String label,
    String value,
    Color valueColor,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Section tìm trận: nút tìm / hủy + stopwatch
  Widget _buildMatchmakingSection(ColorScheme colorScheme) {
    if (_isSearching) {
      return Column(
        children: [
          // Searching animation container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primaryContainer.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Pulsing indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đang tìm đối thủ...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                // Stopwatch timer
                Text(
                  _formatSearchTime(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.tertiary,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Nút Hủy
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () async {
                await ref.read(signalRServiceProvider).cancelMatch();
                _stopSearchTimer();
                setState(() => _isSearching = false);
              },
              child: Text(
                'Hủy tìm trận',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ═══ Nút Đấu với Máy + Tìm Trận ═══
    return Column(
      children: [
        // Nút Đấu với Máy
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.primaryContainer),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: _isConnecting
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiSetupScreen()),
                    );
                  },
            label: Text(
              'Đấu với Máy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Nút Tìm Trận
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
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
              onPressed: _isConnecting
                  ? null
                  : () async {
                      setState(() => _isSearching = true);
                      _startSearchTimer();
                      final signalR = ref.read(signalRServiceProvider);
                      await signalR.ensureConnected();
                      await signalR.findMatch();
                    },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 10),
                  Text(
                    'Tìm Trận',
                    style: TextStyle(
                      fontSize: 20,
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
    );
  }
}
