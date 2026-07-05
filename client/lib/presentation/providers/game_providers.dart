import 'package:client/core/services/signalr_service.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/legacy.dart';

class MatchState {
  final String matchId;
  final String fen;
  final String myColor;
  final double whiteTimeMs;
  final double blackTimeMs;

  MatchState({
    this.matchId = '',
    this.fen = '',
    this.myColor = '',
    this.whiteTimeMs = 120000,
    this.blackTimeMs = 120000,
  });

  MatchState coppyWith({
    String? matchId,
    String? fen,
    String? myColor,
    double? whiteTimeMs,
    double? blackTimeMs,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      fen: fen ?? this.fen,
      myColor: myColor ?? this.myColor,
      whiteTimeMs: whiteTimeMs ?? this.whiteTimeMs,
      blackTimeMs: blackTimeMs ?? this.blackTimeMs,
    );
  }
}

class MatchStateNotifier extends StateNotifier<MatchState> {
  final SignalrService _signalR;

  MatchStateNotifier(this._signalR) : super(MatchState()) {
    _signalR.onReceiveMove((args) {
      if (args == null || args.isEmpty) return;

      final data = args[0] as Map<String, dynamic>;
      final newFen = data['newFen'] ?? data['NewFen'] ?? '';

      final double? whiteTime = data['WhiteTimeLeftMs']?.toDouble();
      final double? blackTime = data['BlackTimeLeftMs']?.toDouble();

      if (newFen.isNotEmpty) {
        state = state.coppyWith(
          fen: newFen,
          whiteTimeMs: whiteTime,
          blackTimeMs: blackTime,
        );
      }
    });
  }

  void initMatch(String id, String fen, String color) {
    state = MatchState(matchId: id, fen: fen, myColor: color);
  }

  void updateFen(String newFen) {
    state = state.coppyWith(fen: newFen);
  }
}

final matchStateProvider =
    StateNotifierProvider<MatchStateNotifier, MatchState>((ref) {
      final signalR = ref.watch(signalRServiceProvider);
      return MatchStateNotifier(signalR);
    });
