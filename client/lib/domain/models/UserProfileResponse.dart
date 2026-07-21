class UserProfile {
  final String id;
  final String userId;
  final String username;
  final String displayName;
  final int level;
  final int elo;
  final String rank;
  final int experience;
  final int totalMatches;
  final int wins;
  final int loses;
  final int draws;
  final double winRate;
  final String friendshipStatus;
  final String? avatarUrl;
  final bool isOnline;
  final bool emailVerified;

  UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.level,
    required this.elo,
    required this.rank,
    required this.experience,
    required this.totalMatches,
    required this.wins,
    required this.loses,
    required this.draws,
    required this.winRate,
    this.friendshipStatus = 'None',
    this.avatarUrl,
    this.isOnline = false,
    this.emailVerified = false,
  });

  /// EXP tích lũy cần để đạt level hiện tại
  /// Server formula: mỗi level cần += 100 * level * level
  int get _expForCurrentLevel {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += 100 * i * i;
    }
    return total;
  }

  UserProfile copyWith({
    String? friendshipStatus,
    String? avatarUrl,
    bool? isOnline,
    bool? emailVerified,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      username: username,
      displayName: displayName,
      level: level,
      elo: elo,
      rank: rank,
      experience: experience,
      totalMatches: totalMatches,
      wins: wins,
      loses: loses,
      draws: draws,
      winRate: winRate,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  /// EXP cần để lên level tiếp theo (chỉ phần của level hiện tại)
  int get expForNextLevel => 100 * level * level;

  /// EXP đã kiếm trong level hiện tại
  int get currentLevelExp => experience - _expForCurrentLevel;

  /// Tiến trình EXP hiện tại (0.0 - 1.0)
  double get expProgress {
    if (expForNextLevel <= 0) return 0.0;
    return (currentLevelExp / expForNextLevel).clamp(0.0, 1.0);
  }

  // Factory để parse JSON trả về từ API
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      level: json['level'] ?? 1,
      elo: json['elo'] ?? 0,
      rank: json['rank'] ?? 'Unranked',
      experience: json['experience'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      wins: json['wins'] ?? 0,
      loses: json['loses'] ?? 0,
      draws: json['draws'] ?? json['draw'] ?? 0,
      winRate: (json['winRate'] ?? 0).toDouble(),
      friendshipStatus: json['friendshipStatus'] ?? 'None',
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
    );
  }
}
