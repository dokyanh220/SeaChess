import 'package:client/core/network/api_client.dart';

class FriendshipRepository {
  final ApiClient _apiClient;

  FriendshipRepository(this._apiClient);

  Future<bool> sendFriendRequest(String username) async {
    try {
      final response = await _apiClient.dio.post('friendship/request', data: {
        'receiverUsername': username,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi gửi lời mời kết bạn : $e');
      return false;
    }
  }
}
