import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _tokenKey       = 'jwt_token';
  static const String _activeMatchKey = 'active_match_id';

  // ── JWT Token ─────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Active Match (để reconnect) ───────────────────────────

  /// Lưu matchId khi bắt đầu trận (gọi trong onMatchStarted)
  Future<void> saveActiveMatch(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeMatchKey, matchId);
  }

  /// Lấy matchId đang dở (gọi trong AuthGate khi app khởi động)
  Future<String?> getActiveMatch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeMatchKey);
  }

  /// Xóa matchId khi trận kết thúc (gọi trong onGameOver)
  Future<void> clearActiveMatch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeMatchKey);
  }
}
