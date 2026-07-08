import 'package:client/domain/utils/rank_helper.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/widgets/chess_board_widget.dart';
import 'package:client/presentation/widgets/chess_time_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _dialogShown = false;

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
                    onMove: (from, to) {
                      final matchId = ref.read(matchStateProvider).matchId;
                      print("[Client: $matchId] đánh từ $from đến $to");
                      ref
                          .read(signalRServiceProvider)
                          .makeMove(matchId, from, to, 'q');
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
