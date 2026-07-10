import 'package:client/domain/utils/rank_helper.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/screens/lobby_screen.dart';
import 'package:client/presentation/widgets/chess_board_widget.dart';
import 'package:client/presentation/widgets/chess_time_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LobbyScreen()),
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LobbyScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi trạng thái ván cờ liên tục
    final matchState = ref.watch(matchStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<MatchState>(matchStateProvider, (prev, next) {
      if (next.isGameOver && !_dialogShown) {
        _dialogShown = true;
        _showGameOverDialog(context, next);
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
      body: SafeArea(
        child: Column(
          children: [
            // ========== TOP BAR ==========
            _buildTopBar(colorScheme),

            // ========== OPPONENT INFO ==========
            _buildOpponentInfo(matchState, opponentTimeMs, !isMyTurn, colorScheme),

            // ========== CHESS BOARD ==========
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: ChessBoardWidget(
                    fen: matchState.fen,
                    myColor: matchState.myColor,
                    kingInCheckSquare:
                        matchState.isInCheck ? matchState.kingInCheckSquare : '',
                    attackerSquares:
                        matchState.isInCheck ? matchState.attackerSquares : const [],
                    onMove: (from, to, promotion) {
                      final matchId = ref.read(matchStateProvider).matchId;
                      print("[Client: $matchId] đánh từ $from đến $to");
                      if (promotion != null) {
                        // Tốt phong cấp: hỏi người dùng chọn quân
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

            // ========== ACTION BUTTONS & MY TIMER ==========
            _buildActionButtonsAndTimer(matchState, myTimeMs, isMyTurn, colorScheme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Top bar thay thế AppBar
  Widget _buildTopBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'SeaChess Arena',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Info bar cho đối thủ
  Widget _buildOpponentInfo(MatchState matchState, double timeMs, bool isRunning, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning
              ? colorScheme.tertiary.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Tên, Elo, Rank
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        matchState.opponentName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (matchState.opponentElo > 0)
                      _buildSmallChip('Elo ${matchState.opponentElo}', colorScheme.secondaryContainer),
                    const SizedBox(width: 6),
                    _buildSmallChip(
                      matchState.opponentRank, 
                      Color(RankHelper.getRankColor(matchState.opponentRank)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Hàng 2: Lv. X
                if (matchState.opponentLevel > 0)
                  _buildSmallChip('Lv.${matchState.opponentLevel}', colorScheme.primaryContainer),
              ],
            ),
          ),
          // Timer
          ChessTimerWidget(
            initialTimeMs: timeMs,
            isRunning: isRunning,
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

  /// Action buttons: Đầu hàng + Xin hòa + My Timer
  Widget _buildActionButtonsAndTimer(MatchState matchState, double timeMs, bool isRunning, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Nút Đầu hàng
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showResignConfirmDialog(
                  context,
                  matchState.matchId,
                  colorScheme,
                ),
                icon: Text(
                  '🏳️',
                  style: const TextStyle(fontSize: 16),
                ),
                label: Text(
                  'Đầu hàng',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nút Xin hòa (disabled)
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 42,
              child: Tooltip(
                message: 'Tính năng sắp ra mắt',
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: null, // Disabled
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🤝',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ],
                  ),
                  label: Text(
                    'Xin hòa',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // My Timer
          ChessTimerWidget(
            initialTimeMs: timeMs,
            isRunning: isRunning,
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
      {'key': 'q', 'label': 'Hậu',   'asset': 'assets/pieces/${pieceColor}q.png', 'recommended': true},
      {'key': 'r', 'label': 'Xe',    'asset': 'assets/pieces/${pieceColor}r.png', 'recommended': false},
      {'key': 'b', 'label': 'Tượng', 'asset': 'assets/pieces/${pieceColor}b.png', 'recommended': false},
      {'key': 'n', 'label': 'Mã',    'asset': 'assets/pieces/${pieceColor}n.png', 'recommended': false},
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
              Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.2),
              ),
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
                      ref.read(signalRServiceProvider).makeMove(
                        matchId, from, to, p['key'] as String,
                      );
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
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.flag, color: colorScheme.error, size: 28),
            const SizedBox(width: 8),
            Text(
              'Đầu hàng?',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          'Bạn chắc chắn muốn đầu hàng ván cờ này?',
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
            },
            child: const Text(
              'Đầu hàng',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, MatchState state) {
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
    String eloText = state.eloChange >= 0
        ? '+${state.eloChange}'
        : '${state.eloChange}';
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
                    color: state.eloChange >= 0
                        ? const Color(0xFF4ADE80)
                        : colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Elo hiện tại: ${state.newElo}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.outline,
              ),
            ),
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
              Navigator.of(context).pop(); // Đóng dialog
              Navigator.of(context).pop(); // Quay về Lobby
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
  static const Color _goldColor    = Color(0xFFE8A833);
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
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
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
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
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
                          color: _goldColor.withOpacity(_isPressed ? 0.35 : 0.22),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

