import 'dart:async';


import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/screens/game_screen.dart';
import 'package:client/presentation/screens/ai_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/screens/match_history_screen.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/presentation/widgets/primary_button.dart';
import 'package:client/presentation/widgets/player_profile_card.dart';
import 'package:client/presentation/widgets/guest_profile_card.dart';
import 'package:client/presentation/widgets/statistic_card.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _isConnecting = false;
  bool _isSearching = false;

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
    try {
      ref.read(signalRServiceProvider).offMatchStarted();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initSignalR() async {
    setState(() => _isConnecting = true);

    try {
      final signalR = ref.read(signalRServiceProvider);
      signalR.offMatchStarted(); // prevent multiple handlers
      await signalR.connect();

      signalR.onMatchStarted((args) {
        if (args == null || args.length < 3) return;

        final matchId = args[0].toString();
        final initialFen = args[1].toString();
        final color = args[2].toString();

        Map<String, dynamic> opponentInfo = {};
        if (args.length > 3 && args[3] != null) {
          if (args[3] is Map) {
            opponentInfo = Map<String, dynamic>.from(args[3] as Map);
          }
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
            ref.invalidate(userProfileProvider);
          });
        }
      });
    } catch (e) {
      debugPrint("[Client] Lỗi kết nối: $e");
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _startSearchTimer() {
    _searchSeconds = 0;
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _searchSeconds++);
      }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SeaChess',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        )
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi tải profile: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Không tìm thấy thông tin'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  // Profile Section
                  if (profile.isGuest)
                    GuestProfileCard(userId: profile.userId)
                  else ...[
                    PlayerProfileCard(
                      username: profile.displayName,
                      elo: profile.elo,
                      level: profile.level,
                      exp: profile.currentLevelExp,
                      maxExp: profile.expForNextLevel,
                      rank: profile.rank,
                      avatarUrl: profile.avatarUrl ?? '',
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Stats Section
                    StatisticCard(
                      totalMatches: profile.totalMatches,
                      wins: profile.wins,
                      losses: profile.loses,
                      draws: profile.draws,
                      winRate: profile.winRate,
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingLg),

                  // Matchmaking Section
                  if (_isSearching)
                    _buildSearchingUI()
                  else
                    Column(
                      children: [
                        PrimaryButton(
                          text: 'TÌM TRẬN',
                          onPressed: _isConnecting
                              ? () {}
                              : () async {
                                  setState(() => _isSearching = true);
                                  _startSearchTimer();
                                  final signalR = ref.read(signalRServiceProvider);
                                  await signalR.ensureConnected();
                                  await signalR.findMatch();
                                },
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        PrimaryButton(
                          text: 'Đấu với Máy',
                          isSecondary: true,
                          onPressed: _isConnecting
                              ? () {}
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AiSetupScreen()),
                                  );
                                },
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        PrimaryButton(
                          text: 'Lịch sử trận đấu',
                          isSecondary: true,
                          onPressed: _isConnecting
                              ? () {}
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const MatchHistoryScreen()),
                                  );
                                },
                        ),
                      ],
                    ),

                  if (_isConnecting)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                      child: Text(
                        'Đang kết nối Server...',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _buildSearchingUI() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryBlue,
            strokeWidth: 3,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Đang tìm đối thủ...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            _formatSearchTime(),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontFamily: 'monospace',
                ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          PrimaryButton(
            text: 'Hủy tìm trận',
            isSecondary: true,
            onPressed: () async {
              await ref.read(signalRServiceProvider).cancelMatch();
              _stopSearchTimer();
              setState(() => _isSearching = false);
            },
          ),
        ],
      ),
    );
  }
}
