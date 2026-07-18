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
