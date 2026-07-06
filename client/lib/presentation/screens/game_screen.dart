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
      appBar: AppBar(
        title: const Text('SeaChess Arena'),
        automaticallyImplyLeading:
            false, // Tạm thời ẩn nút Back để không lỡ tay thoát
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hiển thị thông tin đối thủ (Tương lai sẽ làm đẹp sau)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đối thủ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Đồng hồ của đối thủ
                    ChessTimerWidget(
                      initialTimeMs: opponentTimeMs,
                      // Đồng hồ đối thủ chạy khi không phải lượt của mình
                      isRunning: !isMyTurn,
                    ),
                  ],
                ),
              ),

              // Trung tâm màn hình: BÀN CỜ
              Padding(
                padding: const EdgeInsets.all(8.0),
                // Truyền chuỗi FEN mới nhất vào Widget
                child: ChessBoardWidget(
                  fen: matchState.fen,
                  myColor: matchState.myColor,
                  kingInCheckSquare: matchState.isInCheck ? matchState.kingInCheckSquare : '',
                  attackerSquares: matchState.isInCheck ? matchState.attackerSquares : const [],
                  onMove: (from, to) {
                    final matchId = ref.read(matchStateProvider).matchId;
                    print("[Client: ${matchId}] đánh từ $from đến $to");

                    // Gọi SignalR gửi lên Server
                    // Mặc định promotion (phong cấp) để là 'q' (Hậu) tạm thời.
                    ref
                        .read(signalRServiceProvider)
                        .makeMove(matchId, from, to, 'q');
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bạn (${matchState.myColor == 'white' ? 'Trắng ⚪' : 'Đen ⚫'})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Đồng hồ của mình
                    ChessTimerWidget(
                      initialTimeMs: myTimeMs,
                      // Đồng hồ mình chạy khi đang là lượt của mình
                      isRunning: isMyTurn,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, MatchState state) {
    String title;
    Color titleColor;
    IconData icon;
    switch (state.gameResult) {
      case 'win':
        title = 'Chiến Thắng! 🎉';
        titleColor = Colors.green;
        icon = Icons.emoji_events;
        break;
      case 'lose':
        title = 'Thất Bại 😢';
        titleColor = Colors.red;
        icon = Icons.sentiment_dissatisfied;
        break;
      default:
        title = 'Hòa Cờ 🤝';
        titleColor = Colors.orange;
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
            Text('Lý do: $reasonText', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Elo: ', style: TextStyle(fontSize: 16)),
                Text(
                  eloText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: state.eloChange >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Elo hiện tại: ${state.newElo}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              Navigator.of(context).pop(); // Quay về Lobby
            },
            child: const Text('Về Sảnh Chờ'),
          ),
        ],
      ),
    );
  }
}
