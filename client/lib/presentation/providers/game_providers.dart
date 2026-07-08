import 'package:client/core/services/audio_service.dart';
import 'package:client/core/services/signalr_service.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/legacy.dart';

class MatchState {
  final String matchId;
  final String fen;
  final String myColor;
  final double whiteTimeMs;
  final double blackTimeMs;
  final bool isInCheck;
  final String kingInCheckSquare;
  final List<String> attackerSquares;
  final bool isGameOver;
  final String gameResult;
  final String gameReason;
  final int eloChange;
  final int newElo;
  // Thông tin đối thủ
  final String opponentName;
  final int opponentLevel;
  final int opponentElo;
  final String opponentRank;
  // Thông tin mình (lấy từ profile)
  final String myName;
  final int myLevel;
  final int myElo;
  final String myRank;

  MatchState({
    this.matchId = '',
    this.fen = '',
    this.myColor = '',
    this.whiteTimeMs = 120000,
    this.blackTimeMs = 120000,
    this.isInCheck = false,
    this.kingInCheckSquare = '',
    this.attackerSquares = const [],
    this.isGameOver = false,
    this.gameResult = '',
    this.gameReason = '',
    this.eloChange = 0,
    this.newElo = 0,
    this.opponentName = 'Đối thủ',
    this.opponentLevel = 0,
    this.opponentElo = 0,
    this.opponentRank = 'Unranked',
    this.myName = '',
    this.myLevel = 0,
    this.myElo = 0,
    this.myRank = 'Unranked',
  });

  MatchState coppyWith({
    String? matchId,
    String? fen,
    String? myColor,
    double? whiteTimeMs,
    double? blackTimeMs,
    bool? isInCheck,
    String? kingInCheckSquare,
    List<String>? attackerSquares,
    bool? isGameOver,
    String? gameResult,
    String? gameReason,
    int? eloChange,
    int? newElo,
    String? opponentName,
    int? opponentLevel,
    int? opponentElo,
    String? opponentRank,
    String? myName,
    int? myLevel,
    int? myElo,
    String? myRank,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      fen: fen ?? this.fen,
      myColor: myColor ?? this.myColor,
      whiteTimeMs: whiteTimeMs ?? this.whiteTimeMs,
      blackTimeMs: blackTimeMs ?? this.blackTimeMs,
      isInCheck: isInCheck ?? this.isInCheck,
      kingInCheckSquare: kingInCheckSquare ?? this.kingInCheckSquare,
      attackerSquares: attackerSquares ?? this.attackerSquares,
      isGameOver: isGameOver ?? this.isGameOver,
      gameResult: gameResult ?? this.gameResult,
      gameReason: gameReason ?? this.gameReason,
      eloChange: eloChange ?? this.eloChange,
      newElo: newElo ?? this.newElo,
      opponentName: opponentName ?? this.opponentName,
      opponentLevel: opponentLevel ?? this.opponentLevel,
      opponentElo: opponentElo ?? this.opponentElo,
      opponentRank: opponentRank ?? this.opponentRank,
      myName: myName ?? this.myName,
      myLevel: myLevel ?? this.myLevel,
      myElo: myElo ?? this.myElo,
      myRank: myRank ?? this.myRank,
    );
  }
}

class MatchStateNotifier extends StateNotifier<MatchState> {
  final SignalrService _signalR;
  final AudioService _audioService;

  MatchStateNotifier(this._signalR, this._audioService) : super(MatchState()) {
    _audioService.init(); // Khởi tạo âm thanh sẵn

    _signalR.onReceiveMove((args) {
      if (args == null || args.isEmpty) return;

      final data = args[0] as Map<String, dynamic>;
      final newFen = data['newFen'] ?? data['NewFen'] ?? '';

      final double? whiteTime = (data['WhiteTimeLeftMs'] ?? data['whiteTimeLeftMs'])?.toDouble();
      final double? blackTime = (data['BlackTimeLeftMs'] ?? data['blackTimeLeftMs'])?.toDouble();

      final bool? isCheck = data['IsInCheck'] ?? data['isInCheck'] ?? false;
      final String kingSquare = data['KingSquare'] ?? data['kingSquare'] ?? '';
      final List<dynamic> attackersRaw = data['AttackerSquares'] ?? data['attackerSquares'] ?? [];
      final List<String> attackers = attackersRaw.map((e) => e.toString()).toList();

      if (newFen.isNotEmpty) {
        state = state.coppyWith(
          fen: newFen,
          whiteTimeMs: whiteTime,
          blackTimeMs: blackTime,
          isInCheck: isCheck,
          kingInCheckSquare: kingSquare,
          attackerSquares: attackers,
        );

        // Phát âm thanh chiếu hoặc âm thanh đi cờ bình thường
        if (isCheck == true) {
          _audioService.playCheckSound();
        } else {
          _audioService.playMoveSound();
        }
      }
    });

    _signalR.onGameOver((args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;

      state = state.coppyWith(
        isGameOver: true,
        gameResult: data['result'] ?? data['Result'] ?? '',
        gameReason: data['reason'] ?? data['Reason'] ?? '',
        eloChange: (data['eloChange'] ?? data['EloChange'] ?? 0).toInt(),
        newElo: (data['newElo'] ?? data['NewElo'] ?? 0).toInt(),
      );

      _audioService.playGameOverSound();
    });
  }

  void initMatch(String id, String fen, String color, [Map<String, dynamic>? opponentInfo]) {
    String oppName = 'Đối thủ';
    int oppLevel = 1;
    int oppElo = 799;
    String oppRank = 'Unranked';

    if (opponentInfo != null) {
      oppName = opponentInfo['opponentName'] ?? opponentInfo['OpponentName'] ?? 'Đối thủ';
      oppLevel = (opponentInfo['opponentLevel'] ?? opponentInfo['OpponentLevel'] ?? 1).toInt();
      oppElo = (opponentInfo['opponentElo'] ?? opponentInfo['OpponentElo'] ?? 799).toInt();
      oppRank = opponentInfo['opponentRank'] ?? opponentInfo['OpponentRank'] ?? 'Unranked';
    }

    state = MatchState(
      matchId: id, 
      fen: fen, 
      myColor: color,
      opponentName: oppName,
      opponentLevel: oppLevel,
      opponentElo: oppElo,
      opponentRank: oppRank,
    );
  }

  void updateFen(String newFen) {
    state = state.coppyWith(fen: newFen);
  }
}

final matchStateProvider =
    StateNotifierProvider<MatchStateNotifier, MatchState>((ref) {
      final signalR = ref.watch(signalRServiceProvider);
      final audio = ref.watch(audioServiceProvider);
      return MatchStateNotifier(signalR, audio);
    });
