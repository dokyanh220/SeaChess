import 'package:client/core/services/local_storage_service.dart';
import 'package:client/presentation/screens/game_screen.dart';
import 'package:client/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'package:client/core/theme/app_theme.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: SeaChessApp()));
}

class SeaChessApp extends ConsumerWidget {
  const SeaChessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'SeaChess',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
