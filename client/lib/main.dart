import 'package:client/core/services/local_storage_service.dart';
import 'package:client/presentation/screens/game_screen.dart';
import 'package:client/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/providers/theme_provider.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/presentation/providers/auth_providers.dart';
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

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isLoading = true;
  bool _hasMatch = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLogin();
  }

  Future<void> _checkAuthAndLogin() async {
    final storage = LocalStorageService();
    final token = await storage.getToken();
    final matchId = await storage.getActiveMatch();

    if (token == null || token.isEmpty) {
      // Auto login as guest
      final success = await ref.read(authNotifierProvider.notifier).guestLogin();
      if (!success) {
        // Fallback: If network fails or something, we still show some UI.
        // But for now, we'll just let it stay on main screen or show error.
      }
    }

    if (mounted) {
      setState(() {
        _hasMatch = (matchId != null && matchId.isNotEmpty);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasMatch) {
      return const GameScreen(isRejoining: true);
    }

    return const MainScreen();
  }
}
