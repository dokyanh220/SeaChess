import 'package:client/core/services/audio_service.dart';
import 'package:client/core/services/local_storage_service.dart';
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
  // ═══ AI Game Fields ═══
  final bool isAiGame;
  final int? aiDifficulty;
  final bool isAiThinking;
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
    this.whiteTimeMs = 1200000,
    this.blackTimeMs = 1200000,
    this.isInCheck = false,
    this.kingInCheckSquare = '',
    this.attackerSquares = const [],
    this.isGameOver = false,
    this.gameResult = '',
    this.gameReason = '',
    this.eloChange = 0,
    this.newElo = 0,
    this.isAiGame = false,
    this.aiDifficulty,
    this.isAiThinking = false,
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
    bool? isAiGame,
    int? aiDifficulty,
    bool? isAiThinking,
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
      isAiGame: isAiGame ?? this.isAiGame,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      isAiThinking: isAiThinking ?? this.isAiThinking,
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
  final LocalStorageService _storage;

  MatchStateNotifier(this._signalR, this._audioService, this._storage) : super(MatchState()) {
    _audioService.init();

    // ── Nhận nước đi mới ──────────────────────────────────────
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
          isAiThinking: false,
        );

        if (isCheck == true) {
          _audioService.playCheckSound();
        } else {
          _audioService.playMoveSound();
        }
      }
    });

    // ── Trận kết thúc ──────────────────────────────
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

      // Xóa matchId khi trận kết thúc
      _storage.clearActiveMatch();
      _audioService.playGameOverSound();
    });

    // ── Reconnect: nhận lại state sau khi mất kết nối ────────────
    _signalR.onRejoinMatch((args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;

      final matchId = data['MatchId'] ?? data['matchId'] ?? '';
      final fen     = data['Fen']     ?? data['fen']     ?? '';
      final color   = data['MyColor'] ?? data['myColor'] ?? 'white';

      state = MatchState(
        matchId:       matchId,
        fen:           fen,
        myColor:       color,
        whiteTimeMs:   ((data['WhiteTimeLeftMs'] ?? data['whiteTimeLeftMs']) as num?)?.toDouble() ?? 1200000,
        blackTimeMs:   ((data['BlackTimeLeftMs'] ?? data['blackTimeLeftMs']) as num?)?.toDouble() ?? 1200000,
        opponentName:  data['OpponentName']  ?? data['opponentName']  ?? 'Đối thủ',
        opponentLevel: (data['OpponentLevel'] ?? data['opponentLevel'] ?? 1).toInt(),
        opponentElo:   (data['OpponentElo']   ?? data['opponentElo']  ?? 799).toInt(),
        opponentRank:  data['OpponentRank']   ?? data['opponentRank'] ?? 'Unranked',
      );
    });

    // ── Trận AI bắt đầu ─────────────────────────────────────
    _signalR.onAiGameStarted((args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;

      final matchId    = data['MatchId']    ?? data['matchId']    ?? '';
      final fen        = data['Fen']        ?? data['fen']        ?? '';
      final myColor    = data['MyColor']    ?? data['myColor']    ?? 'white';
      final difficulty = (data['Difficulty'] ?? data['difficulty'] ?? 2).toInt();

      state = MatchState(
        matchId:       matchId,
        fen:           fen,
        myColor:       myColor,
        whiteTimeMs:   ((data['WhiteTimeLeftMs'] ?? data['whiteTimeLeftMs']) as num?)?.toDouble() ?? 600000,
        blackTimeMs:   ((data['BlackTimeLeftMs'] ?? data['blackTimeLeftMs']) as num?)?.toDouble() ?? 600000,
        isAiGame:      true,
        aiDifficulty:  difficulty,
        isAiThinking:  false,
        opponentName:  data['OpponentName']  ?? data['opponentName']  ?? 'Stockfish',
        opponentLevel: (data['OpponentLevel'] ?? data['opponentLevel'] ?? 0).toInt(),
        opponentElo:   (data['OpponentElo']   ?? data['opponentElo']   ?? 0).toInt(),
        opponentRank:  data['OpponentRank']   ?? data['opponentRank']  ?? 'AI',
      );

      // Lưu matchId cho reconnect
      _storage.saveActiveMatch(matchId);
    });
  }

  void initMatch(String id, String fen, String color, [Map<String, dynamic>? opponentInfo]) {
    String oppName  = 'Đối thủ';
    int oppLevel    = 1;
    int oppElo      = 799;
    String oppRank  = 'Unranked';

    if (opponentInfo != null) {
      oppName  = opponentInfo['opponentName']  ?? opponentInfo['OpponentName']  ?? 'Đối thủ';
      oppLevel = (opponentInfo['opponentLevel'] ?? opponentInfo['OpponentLevel'] ?? 1).toInt();
      oppElo   = (opponentInfo['opponentElo']  ?? opponentInfo['OpponentElo']  ?? 799).toInt();
      oppRank  = opponentInfo['opponentRank']  ?? opponentInfo['OpponentRank']  ?? 'Unranked';
    }

    state = MatchState(
      matchId:       id,
      fen:           fen,
      myColor:       color,
      opponentName:  oppName,
      opponentLevel: oppLevel,
      opponentElo:   oppElo,
      opponentRank:  oppRank,
    );

    // Lưu matchId xuống để hỗ trợ reconnect khi mất mạng / thoát app
    _storage.saveActiveMatch(id);
  }

  void updateFen(String newFen) {
    state = state.coppyWith(fen: newFen);
  }

  void setAiThinking(bool thinking) {
    state = state.coppyWith(isAiThinking: thinking);
  }
}

final matchStateProvider =
    StateNotifierProvider<MatchStateNotifier, MatchState>((ref) {
      final signalR = ref.watch(signalRServiceProvider);
      final audio   = ref.watch(audioServiceProvider);
      final storage = ref.watch(localStorageServiceProvider);
      return MatchStateNotifier(signalR, audio, storage);
    });
