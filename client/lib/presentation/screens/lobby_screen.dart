import 'package:client/presentation/providers/auth_providers.dart';
import 'package:client/presentation/providers/game_providers.dart';
import 'package:client/presentation/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _lobbyScreenState();
}

class _lobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _isConnecting = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initSignalR();
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

        ref
            .read(matchStateProvider.notifier)
            .initMatch(matchId, initialFen, color);

        setState(() => _isSearching = false);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        }
      });
    } catch (e) {
      print("[Client] Lỗi kết nối: $e");
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu profile từ Provider
    final profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('SeaChess'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ========== PHẦN 1: CARD THÔNG TIN CÁ NHÂN ==========
              profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Lỗi tải profile: $err'),
                data: (profile) {
                  if (profile == null) {
                    return const Text('Không tìm thấy thông tin');
                  }
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Avatar + Tên
                          const CircleAvatar(
                            radius: 36,
                            child: Icon(Icons.person, size: 40),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Row hiển thị Level, Elo, Rank
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('Level', '${profile.level}'),
                              _buildStatItem('Elo', '${profile.elo}'),
                              _buildStatItem('Rank', profile.rank),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(), // Đẩy nút xuống phía dưới
              // ========== PHẦN 2: TRẠNG THÁI KẾT NỐI ==========
              if (_isConnecting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Đang kết nối Server...'),
                    ],
                  ),
                ),
              // ========== PHẦN 3: NÚT TÌM TRẬN / HỦY ==========
              if (_isSearching) ...[
                const Text(
                  'Đang tìm đối thủ...',
                  style: TextStyle(fontSize: 16, color: Colors.orange),
                ),
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                // Nút hủy tìm trận
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await ref.read(signalRServiceProvider).cancelMatch();
                      setState(() => _isSearching = false);
                    },
                    child: const Text(
                      'Hủy tìm trận',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ),
                ),
              ] else ...[
                // Nút tìm trận
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isConnecting
                        ? null
                        : () async {
                            setState(() => _isSearching = true);
                            await ref.read(signalRServiceProvider).findMatch();
                          },
                    child: const Text(
                      'Tìm trận',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper hiển thị từng chỉ số (Level, Elo, Rank)
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
