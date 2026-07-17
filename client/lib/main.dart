import 'package:client/core/services/local_storage_service.dart';
import 'package:client/presentation/screens/game_screen.dart';
import 'package:client/presentation/screens/main_screen.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Oceanic Grandmaster Design System
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF0B1326),
          primary: const Color(0xFFADC6FF),
          primaryContainer: const Color(0xFF4D8EFF),
          secondary: const Color(0xFFFFB95F),
          secondaryContainer: const Color(0xFFEE9800),
          tertiary: const Color(0xFF4CD7F6),
          tertiaryContainer: const Color(0xFF009EB9),
          error: const Color(0xFFFFB4AB),
          onSurface: const Color(0xFFDAE2FD),
          onSurfaceVariant: const Color(0xFFC2C6D6),
          outline: const Color(0xFF8C909F),
          outlineVariant: const Color(0xFF424754),
          surfaceContainerHighest: const Color(0xFF2D3449),
          surfaceContainerHigh: const Color(0xFF222A3D),
          surfaceContainer: const Color(0xFF171F33),
          surfaceContainerLow: const Color(0xFF131B2E),
          surfaceContainerLowest: const Color(0xFF060E20),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B1326),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// Đọc token và matchId đang dở từ SharedPreferences
  Future<({String? token, String? matchId})> _loadStoredData() async {
    final storage = LocalStorageService();
    final token   = await storage.getToken();
    final matchId = await storage.getActiveMatch();
    return (token: token, matchId: matchId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String? token, String? matchId})>(
      future: _loadStoredData(),
      builder: (context, snapshot) {
        // Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token   = snapshot.data?.token;
        final matchId = snapshot.data?.matchId;

        // Chưa đăng nhập
        if (token == null || token.isEmpty) {
          return const LoginScreen();
        }

        // Có trận đang dở → vào GameScreen, nó sẽ tự gọi rejoinMatch()
        if (matchId != null && matchId.isNotEmpty) {
          return const GameScreen(isRejoining: true);
        }

        // Bình thường → vào MainScreen
        return const MainScreen();
      },
    );
  }
}
