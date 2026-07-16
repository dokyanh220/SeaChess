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
}
