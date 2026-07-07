/// Utility class for rank-related operations
class RankHelper {
  /// Tách base rank từ full rank string server trả về
  /// Ví dụ: "Gold III" → "Gold", "Senior Master" → "SeniorMaster"
  static String _getBaseRank(String rank) {
    // Xử lý các rank đặc biệt có space
    if (rank == 'Grand Master') return 'GrandMaster';
    if (rank == 'Senior Master') return 'SeniorMaster';
    if (rank == 'Master') return 'Master';
    if (rank == 'Unranked') return 'Unranked';

    // Tách tier (I, II, III) ra khỏi tên rank
    // "Gold III" → "Gold", "Bronze I" → "Bronze"
    final parts = rank.split(' ');
    if (parts.length >= 2) {
      final possibleTier = parts.last;
      if (['I', 'II', 'III', 'IV', 'V'].contains(possibleTier)) {
        return parts.sublist(0, parts.length - 1).join('');
      }
    }

    return rank;
  }

  /// Mapping base rank → tên file asset nhỏ (assets/rank/simple/)
  /// Lưu ý: một số file có space thừa trong tên (Bronze .png, Gold .png)
  static String getRankAssetPath(String rank) {
    final base = _getBaseRank(rank);

    final Map<String, String> rankFileMap = {
      'Unranked': 'assets/rank/simple/Unranked.png',
      'Bronze': 'assets/rank/simple/Bronze .png',
      'Silver': 'assets/rank/simple/Silver.png',
      'Gold': 'assets/rank/simple/Gold .png',
      'Platinum': 'assets/rank/simple/Platinum.png',
      'Diamond': 'assets/rank/simple/Diamond.png',
      'Expert': 'assets/rank/simple/Expert.png',
      'Master': 'assets/rank/simple/Master.png',
      'GrandMaster': 'assets/rank/simple/GrandMaster.png',
      'SeniorMaster': 'assets/rank/simple/SeniorMaster.png',
      'Legend': 'assets/rank/simple/Legend.png',
    };

    return rankFileMap[base] ?? 'assets/rank/simple/Unranked.png';
  }

  /// Lấy tên file rank icon lớn (assets/rank/) cho lobby
  static String getRankLargeAssetPath(String rank) {
    final base = _getBaseRank(rank);

    final Map<String, String> rankFileMap = {
      'Unranked': 'assets/rank/simple/Unranked.png',
      'Bronze': 'assets/rank/Bronze.png',
      'Silver': 'assets/rank/Silver.png',
      'Gold': 'assets/rank/Gold.png',
      'Platinum': 'assets/rank/Platinum.png',
      'Diamond': 'assets/rank/Diamond.png',
      'Expert': 'assets/rank/Expert.png',
      'Master': 'assets/rank/Master.png',
      'GrandMaster': 'assets/rank/Grandmaster.png',
      'SeniorMaster': 'assets/rank/SeniorMaster.png',
      'Legend': 'assets/rank/Legend.png',
    };

    return rankFileMap[base] ?? 'assets/rank/simple/Unranked.png';
  }

  /// Màu đại diện cho mỗi rank
  static int getRankColor(String rank) {
    final base = _getBaseRank(rank);

    final Map<String, int> colorMap = {
      'Unranked': 0xFF8C909F,
      'Bronze': 0xFFCD7F32,
      'Silver': 0xFFC0C0C0,
      'Gold': 0xFFFFD700,
      'Platinum': 0xFF4CD7F6,
      'Diamond': 0xFFB9F2FF,
      'Expert': 0xFF9B59B6,
      'Master': 0xFFFF6B6B,
      'GrandMaster': 0xFFFF4500,
      'SeniorMaster': 0xFFFF1493,
      'Legend': 0xFFFFD700,
    };

    return colorMap[base] ?? 0xFF8C909F;
  }
}
