import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/widgets/chess_board_widget.dart';
import 'package:client/presentation/widgets/chess_time_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi trạng thái ván cờ liên tục
    final matchState = ref.watch(matchStateProvider);

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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              // Thông báo đến lượt cho sinh động
              if (isMyTurn)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    "Đến lượt của bạn!",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
