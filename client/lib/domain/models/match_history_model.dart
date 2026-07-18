class MatchHistoryModel {
  final String id;
  final String opponentName;
  final int opponentElo;
  final int result; // 0: Pending, 1: WhiteWin, 2: BlackWin, 3: Draw, 4: Abandoned
  final bool isWhite;
  final bool isAiGame;
  final int? aiDifficulty; // 0, 1, 2...
  final String? pgn;
  final DateTime createdAt;
  final int initialTimeSeconds;

  MatchHistoryModel({
    required this.id,
    required this.opponentName,
    required this.opponentElo,
    required this.result,
    required this.isWhite,
    required this.isAiGame,
    this.aiDifficulty,
    this.pgn,
    required this.createdAt,
    required this.initialTimeSeconds,
  });

  factory MatchHistoryModel.fromJson(Map<String, dynamic> json) {
    return MatchHistoryModel(
      id: json['id'] as String,
      opponentName: json['opponentName'] as String? ?? 'Unknown',
      opponentElo: json['opponentElo'] as int? ?? 1000,
      result: json['result'] as int? ?? 0,
      isWhite: json['isWhite'] as bool? ?? true,
      isAiGame: json['isAiGame'] as bool? ?? false,
      aiDifficulty: json['aiDifficulty'] as int?,
      pgn: json['pgn'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      initialTimeSeconds: json['initialTimeSeconds'] as int? ?? 600,
    );
  }
}

class AiMatchResultRequest {
  final int difficulty; // 0: Beginner, 1: Easy, 2: Medium, 3: Hard
  final int playerColor; // 0: White, 1: Black
  final int result; // 0: Pending, 1: WhiteWin, 2: BlackWin, 3: Draw, 4: Aborted
  final int initialTimeSeconds;
  final String? pgn;

  AiMatchResultRequest({
    required this.difficulty,
    required this.playerColor,
    required this.result,
    required this.initialTimeSeconds,
    this.pgn,
  });

  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty,
      'playerColor': playerColor,
      'result': result,
      'initialTimeSeconds': initialTimeSeconds,
      'pgn': pgn,
    };
  }
}

class AiMatchResultResponse {
  final int eloChange;
  final int xpChange;
  final int newElo;
  final int newLevel;
  final int newExperience;

  AiMatchResultResponse({
    required this.eloChange,
    required this.xpChange,
    required this.newElo,
    required this.newLevel,
    required this.newExperience,
  });

  factory AiMatchResultResponse.fromJson(Map<String, dynamic> json) {
    return AiMatchResultResponse(
      eloChange: json['eloChange'] as int? ?? 0,
      xpChange: json['xpChange'] as int? ?? 0,
      newElo: json['newElo'] as int? ?? 0,
      newLevel: json['newLevel'] as int? ?? 1,
      newExperience: json['newExperience'] as int? ?? 0,
    );
  }
}
