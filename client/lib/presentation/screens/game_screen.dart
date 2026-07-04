import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/widgets/chess_board_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi trạng thái ván cờ liên tục
    final matchState = ref.watch(matchStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SeaChess Arena'),
        automaticallyImplyLeading:
            false, // Tạm thời ẩn nút Back để không lỡ tay thoát
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hiển thị thông tin đối thủ (Tương lai sẽ làm đẹp sau)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bạn cầm quân: ${matchState.myColor == 'white' ? 'Trắng ⚪' : 'Đen ⚫'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
        ],
      ),
    );
  }
}
