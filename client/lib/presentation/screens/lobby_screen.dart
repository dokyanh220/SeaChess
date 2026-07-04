import 'package:client/presentation/providers/auth_providers.dart';
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
        print("[Client] Tìm thấy trận");
        print("Data match: $args");

        setState(() => _isSearching = false);

        // TODO: chuyển sang gamescreen
      });
    } catch (e) {
      print("[Client] Lỗi kết nối: $e");
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sảnh Chờ Tạm'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isConnecting)
              const CircularProgressIndicator()
            else
              const Text(
                'SignalR đã sẵn sàng',
                style: TextStyle(color: Colors.green, fontSize: 18),
              ),
            const SizedBox(height: 16),
            const Text(
              'Đăng nhập thành công!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                backgroundColor: _isSearching ? Colors.orange : Colors.blue,
              ),
              onPressed: _isConnecting || _isSearching
                  ? null
                  : () async {
                      setState(() => _isSearching = true);
                      print("[Client] Đang gửi yêu cầu tìm trận...");

                      await ref.read(signalRServiceProvider).findMatch();
                    },
              child: Text(
                _isSearching ? 'Đang tìm đối thủ...' : 'Chơi',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
