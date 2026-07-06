import 'package:client/core/services/local_storage_service.dart';
import 'package:client/presentation/screens/lobby_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: SeaChessApp()));
}

class SeaChessApp extends StatelessWidget {
  const SeaChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeaChess',
      debugShowCheckedModeBanner: false, // Tắt dải băng đỏ "Debug"
      theme: ThemeData(
        // Chọn một tông màu trầm, sang trọng phù hợp với cờ vua
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark, // Chế độ Dark Mode cho ngầu
        ),
        useMaterial3: true,
      ),
      // Tạm thời hiển thị một màn hình trống để xác nhận app chạy lên
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: LocalStorageService().getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return const LobbyScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
