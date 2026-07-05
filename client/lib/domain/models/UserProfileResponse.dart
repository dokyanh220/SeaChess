class UserProfile {
  final String displayName;
  final int level;
  final int elo;
  final String rank;
  final int experience;
  final int totalMatches;
  final int wins;
  final int loses;
  final double winRate;

  UserProfile({
    required this.displayName,
    required this.level,
    required this.elo,
    required this.rank,
    required this.experience,
    required this.totalMatches,
    required this.wins,
    required this.loses,
    required this.winRate,
  });

  // Factory để parse JSON trả về từ API
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] ?? '',
      level: json['level'] ?? 1,
      elo: json['elo'] ?? 799,
      rank: json['rank'] ?? 'Unranked',
      experience: json['experience'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      wins: json['wins'] ?? 0,
      loses: json['loses'] ?? 0,
      winRate: (json['winRate'] ?? 0).toDouble(),
    );
  }
}
