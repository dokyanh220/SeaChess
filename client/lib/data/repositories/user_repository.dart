import 'package:client/core/network/api_client.dart';
import 'package:client/domain/models/UserProfileResponse.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final response = await _apiClient.dio.get('user/search', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => UserProfile.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Lỗi search user: $e');
      return [];
    }
  }

  Future<UserProfile?> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        'user/profile',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Lỗi cập nhật profile: $e');
      return null;
    }
  }
}
