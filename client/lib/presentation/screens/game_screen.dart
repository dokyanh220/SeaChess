import 'package:client/domain/utils/rank_helper.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/screens/main_screen.dart';
import 'package:client/presentation/widgets/chess_board_widget.dart';
import 'package:client/presentation/widgets/chess_time_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:client/presentation/widgets/captured_pieces_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/domain/models/match_history_model.dart';
import 'package:client/presentation/providers/match_history_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  /// [isRejoining] = true khi user quay lại từ restart app / mất mạng.
  /// GameScreen sẽ tự gọi Hub.RejoinMatch() để lấy lại state.
  final bool isRejoining;

  const GameScreen({super.key, this.isRejoining = false});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRejoining) {
      // Sau khi widget build xong mới gọi để đảm bảo providers sẵn sàng
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryRejoin());
    }
  }

  /// Gọi Hub.RejoinMatch() — server sẽ gửi lại toàn bộ state hoặc NoActiveMatch
  Future<void> _tryRejoin() async {
    final signalR = ref.read(signalRServiceProvider);

    // Đăng ký trước (sẽ được buffer nếu chưa connect)
    signalR.onNoActiveMatch((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    });

    try {
      // Phải connect() trước — khi isRejoining=true, app bỏ qua LobbyScreen
      // nên SignalR chưa được khởi tạo. connect() sẽ flush pending handlers.
      await signalR.connect();
      await signalR.rejoinMatch();
    } catch (e) {
      debugPrint('[Rejoin] Lỗi khi rejoin: $e');
      // Lỗi kết nối → về Lobby
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi trạng thái ván cờ liên tục
    final matchState = ref.watch(matchStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<MatchState>(matchStateProvider, (prev, next) async {
      if (next.isGameOver && !_dialogShown) {
        _dialogShown = true;
        
        if (next.isAiGame) {
          int result = 0; // MatchResult.Pending
          if (next.gameResult == 'win') {
            result = next.myColor == 'white' ? 1 : 2; // WhiteWin or BlackWin
          } else if (next.gameResult == 'lose') {
            result = next.myColor == 'white' ? 2 : 1; 
          } else {
            result = 3; // Draw
          }
          
          final request = AiMatchResultRequest(
            difficulty: next.aiDifficulty ?? 0,
            playerColor: next.myColor == 'white' ? 0 : 1,
            result: result,
            initialTimeSeconds: 600, // Tạm fix 10p, có thể cấu hình sau
            pgn: next.fenHistory.join(';'),
          );
          
          try {
             final response = await ref.read(matchHistoryRepositoryProvider).saveAiMatchResult(request);
             if (mounted) {
               _showGameOverDialog(context, next, aiResponse: response);
             }
          } catch (e) {
             debugPrint('Lỗi khi lưu kết quả AI: $e');
             if (mounted) {
               _showGameOverDialog(context, next);
             }
          }
        } else {
          _showGameOverDialog(context, next);
        }
      }
    });

    List<String> fenParts = matchState.fen.split(' ');
    String currentTurn = fenParts.length > 1 ? fenParts[1] : 'w';

    bool isMyTurn =
        (matchState.myColor == 'white' && currentTurn == 'w') ||
        (matchState.myColor == 'black' && currentTurn == 'b');

    double myTimeMs = matchState.myColor == 'white'
        ? matchState.whiteTimeMs
        : matchState.blackTimeMs;
    double opponentTimeMs = matchState.myColor == 'white'
        ? matchState.blackTimeMs
        : matchState.whiteTimeMs;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ========== TOP BAR ==========
            _buildTopBar(colorScheme),

            // ========== OPPONENT INFO ==========
            _buildProfileCard(
              matchState: matchState,
              timeMs: opponentTimeMs,
              isRunning: !isMyTurn,
              colorScheme: colorScheme,
              isOpponent: true,
            ),

            // ========== CHESS BOARD ==========
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                child: Center(
                  child: ChessBoardWidget(
                    fen: matchState.fen,
                    myColor: matchState.myColor,
                    kingInCheckSquare: matchState.isInCheck
                        ? matchState.kingInCheckSquare
                        : '',
                    attackerSquares: matchState.isInCheck
                        ? matchState.attackerSquares
                        : const [],
                    isLocked: matchState.isAiThinking,
                    onMove: (from, to, promotion) {
                      final matchId = ref.read(matchStateProvider).matchId;

                      if (matchState.isAiGame) {
                        ref
                            .read(matchStateProvider.notifier)
                            .setAiThinking(true);
                      }

                      if (promotion != null) {
                        _showPromotionDialog(context, matchId, from, to);
                      } else {
                        ref
                            .read(signalRServiceProvider)
                            .makeMove(matchId, from, to, 'q');
                      }
                    },
                  ),
                ),
              ),
            ),

            // ========== PLAYER INFO ==========
            _buildProfileCard(
              matchState: matchState,
              timeMs: myTimeMs,
              isRunning: isMyTurn,
              colorScheme: colorScheme,
              isOpponent: false,
            ),

            // ========== ACTION BUTTONS ==========
            _buildActionButtons(
              matchState,
              colorScheme,
            ),
            const SizedBox(height: AppTheme.spacingSm),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () {
              final matchState = ref.read(matchStateProvider);
              if (matchState.isGameOver) {
                Navigator.of(context).pop();
              } else {
                _showResignConfirmDialog(
                  context,
                  matchState.matchId,
                  matchState.isAiGame,
                  colorScheme,
                );
              }
            },
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'SeaChess Arena',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Info bar cho người chơi / đối thủ
  Widget _buildProfileCard({
    required MatchState matchState,
    required double timeMs,
    required bool isRunning,
    required ColorScheme colorScheme,
    required bool isOpponent,
  }) {
    final name = isOpponent ? matchState.opponentName : matchState.myName;
    final elo = isOpponent ? matchState.opponentElo : matchState.myElo;
    final rank = isOpponent ? matchState.opponentRank : matchState.myRank;
    final level = isOpponent ? matchState.opponentLevel : matchState.myLevel;

    final bool isMyColorWhite = matchState.myColor == 'white';
    final bool showWhitePieces = isOpponent ? isMyColorWhite : !isMyColorWhite;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning
              ? colorScheme.tertiary.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Placeholder
          CircleAvatar(
            radius: 20,
            backgroundColor: isOpponent ? colorScheme.error.withOpacity(0.2) : colorScheme.primary.withOpacity(0.2),
            child: Icon(
              isOpponent ? Icons.person_outline : Icons.person,
              color: isOpponent ? colorScheme.error : colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Tên
                Text(
                  name.isEmpty ? (isOpponent ? 'Đối thủ' : 'Tôi') : name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Hàng 2: Elo, Rank
                Row(
                  children: [
                    if (elo > 0)
                      _buildSmallChip(
                        'Elo $elo',
                        colorScheme.secondaryContainer,
                      ),
                    if (elo > 0) const SizedBox(width: 6),
                    _buildSmallChip(
                      rank,
                      Color(RankHelper.getRankColor(rank)),
                    ),
                    if (level > 0) ...[
                      const SizedBox(width: 6),
                      _buildSmallChip('Lv.$level', colorScheme.primaryContainer),
                    ]
                  ],
                ),
              ],
            ),
          ),
          // Timer
          ChessTimerWidget(initialTimeMs: timeMs, isRunning: isRunning),
            ],
          ),
          if (matchState.fen.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: CapturedPiecesWidget(
                currentFen: matchState.fen, 
                isWhite: showWhitePieces,
              ),
            ),
        ],
      ),
    );
  }

  /// Chip nhỏ hiển thị Level / Elo
  Widget _buildSmallChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Action buttons: Đầu hàng / Thoát trận + Xin hòa
  Widget _buildActionButtons(
    MatchState matchState,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Nút Đầu hàng
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _showResignConfirmDialog(
                  context,
                  matchState.matchId,
                  matchState.isAiGame,
                  colorScheme,
                ),
                icon: Icon(
                  matchState.isAiGame ? Icons.exit_to_app : Icons.flag,
                  color: colorScheme.error,
                  size: 20,
                ),
                label: Text(
                  matchState.isAiGame ? 'Thoát trận' : 'Đầu hàng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút Xin hòa (disabled)
          Expanded(
            child: SizedBox(
              height: 48,
              child: Tooltip(
                message: 'Tính năng sắp ra mắt',
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: null, // Disabled
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🤝', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ],
                  ),
                  label: Text(
                    'Cầu hòa',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog chọn quân phong cấp khi tốt đến hàng cuối
  void _showPromotionDialog(
    BuildContext context,
    String matchId,
    String from,
    String to,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final matchState = ref.read(matchStateProvider);
    final pieceColor = matchState.myColor == 'white' ? 'w' : 'b';

    // Danh sách quân phong cấp: Hậu được đánh dấu isRecommended
    final promotionPieces = [
      {
        'key': 'q',
        'label': 'Hậu',
        'asset': 'assets/pieces/${pieceColor}q.png',
        'recommended': true,
      },
      {
        'key': 'r',
        'label': 'Xe',
        'asset': 'assets/pieces/${pieceColor}r.png',
        'recommended': false,
      },
      {
        'key': 'b',
        'label': 'Tượng',
        'asset': 'assets/pieces/${pieceColor}b.png',
        'recommended': false,
      },
      {
        'key': 'n',
        'label': 'Mã',
        'asset': 'assets/pieces/${pieceColor}n.png',
        'recommended': false,
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.18),
                blurRadius: 40,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Tiêu đề ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Phong Cấp Tốt',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn quân cờ để phong cấp',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),
              // ── Divider ───────────────────────────────
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
              const SizedBox(height: 20),

              // ── 4 Nút chọn quân ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: promotionPieces.map((p) {
                  return _PromotionPieceCard(
                    asset: p['asset'] as String,
                    label: p['label'] as String,
                    isRecommended: p['recommended'] as bool,
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref
                          .read(signalRServiceProvider)
                          .makeMove(matchId, from, to, p['key'] as String);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog xác nhận đầu hàng

  void _showResignConfirmDialog(
    BuildContext context,
    String matchId,
    bool isAiGame,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isAiGame ? Icons.exit_to_app : Icons.flag,
              color: colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isAiGame ? 'Thoát trận?' : 'Đầu hàng?',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          isAiGame
              ? 'Bạn có muốn thoát trận đấu với AI này không?'
              : 'Bạn chắc chắn muốn đầu hàng ván cờ này?',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              ref.read(signalRServiceProvider).resign(matchId);
              if (isAiGame) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              isAiGame ? 'Thoát' : 'Đầu hàng',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, MatchState state, {AiMatchResultResponse? aiResponse}) {
    final colorScheme = Theme.of(context).colorScheme;
    String title;
    Color titleColor;
    IconData icon;
    switch (state.gameResult) {
      case 'win':
        title = 'Chiến Thắng! 🎉';
        titleColor = const Color(0xFF4ADE80);
        icon = Icons.emoji_events;
        break;
      case 'lose':
        title = 'Thất Bại 😢';
        titleColor = colorScheme.error;
        icon = Icons.sentiment_dissatisfied;
        break;
      default:
        title = 'Hòa Cờ 🤝';
        titleColor = colorScheme.secondary;
        icon = Icons.handshake;
    }
    // Chuyển reason sang tiếng Việt
    String reasonText = switch (state.gameReason) {
      'Checkmate' => 'Chiếu bí',
      'Timeout' => 'Hết giờ',
      'Resign' => 'Đầu hàng',
      'Stalemate' => 'Hết nước đi (Hòa)',
      'FiftyMoveRule' => 'Luật 50 nước (Hòa)',
      _ => state.gameReason,
    };
    
    int eloChange = aiResponse != null ? aiResponse.eloChange : state.eloChange;
    int newElo = aiResponse != null ? aiResponse.newElo : state.newElo;
    
    String eloText = eloChange >= 0 ? '+$eloChange' : '$eloChange';
    
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc bấm nút
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: titleColor, size: 32),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: titleColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lý do: $reasonText',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Elo: ',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  eloText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: eloChange >= 0
                        ? const Color(0xFF4ADE80)
                        : colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Elo hiện tại: $newElo',
              style: TextStyle(fontSize: 14, color: colorScheme.outline),
            ),
            if (aiResponse != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Kinh nghiệm: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '+${aiResponse.xpChange} XP',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Cấp độ hiện tại: ${aiResponse.newLevel} (${aiResponse.newExperience}/${aiResponse.newLevel * 100} XP)',
                style: TextStyle(fontSize: 14, color: colorScheme.outline),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Về Sảnh Chờ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widget card chọn quân phong cấp — có press animation và
// golden highlight khi isRecommended (Hậu)
// ══════════════════════════════════════════════════════════════
class _PromotionPieceCard extends StatefulWidget {
  final String asset;
  final String label;
  final bool isRecommended;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PromotionPieceCard({
    required this.asset,
    required this.label,
    required this.isRecommended,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_PromotionPieceCard> createState() => _PromotionPieceCardState();
}

class _PromotionPieceCardState extends State<_PromotionPieceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  // Màu vàng cho quân Hậu (gợi ý)
  static const Color _goldColor = Color(0xFFE8A833);
  static const Color _goldColorDim = Color(0xFFB8860B);

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _scaleCtrl.reverse(); // scale xuống
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _scaleCtrl.forward(); // scale lên lại
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final bool rec = widget.isRecommended;

    // Màu border/glow theo loại quân
    final borderColor = rec
        ? (_isPressed ? _goldColorDim : _goldColor)
        : (_isPressed
              ? cs.primary.withOpacity(0.5)
              : cs.outline.withOpacity(0.3));

    final bgColor = rec
        ? (_isPressed
              ? _goldColor.withOpacity(0.18)
              : _goldColor.withOpacity(0.10))
        : (_isPressed
              ? cs.primary.withOpacity(0.12)
              : cs.primary.withOpacity(0.05));

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── Card chính ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 70,
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: rec ? 1.8 : 1.2),
                boxShadow: rec
                    ? [
                        BoxShadow(
                          color: _goldColor.withOpacity(
                            _isPressed ? 0.35 : 0.22,
                          ),
                          blurRadius: _isPressed ? 12 : 18,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ảnh quân cờ
                  Image.asset(
                    widget.asset,
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.crop_square_rounded,
                      size: 50,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tên quân
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: rec ? FontWeight.w700 : FontWeight.w500,
                      color: rec ? _goldColor : cs.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // ── Badge "Gợi ý" phía trên card (chỉ cho Hậu) ──
            if (rec)
              Positioned(
                top: -11,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8A833), Color(0xFFFFD700)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _goldColor.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⭐', style: TextStyle(fontSize: 9)),
                      SizedBox(width: 2),
                      Text(
                        'Gợi ý',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
