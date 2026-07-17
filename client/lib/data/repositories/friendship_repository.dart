import 'package:client/core/network/api_client.dart';
import 'package:client/domain/models/UserProfileResponse.dart';

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

  Future<List<UserProfile>> getFriends() async {
    try {
      final response = await _apiClient.dio.get('friendship/list');
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => UserProfile.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi lấy danh sách bạn bè: $e');
      return [];
    }
  }

  Future<List<UserProfile>> getPendingRequests() async {
    try {
      final response = await _apiClient.dio.get('friendship/pending');
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => UserProfile.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi lấy danh sách lời mời: $e');
      return [];
    }
  }

  Future<bool> acceptFriendRequest(String requesterId) async {
    try {
      final response = await _apiClient.dio.post('friendship/accept/$requesterId');
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi chấp nhận lời mời: $e');
      return false;
    }
  }

  Future<bool> declineFriendRequest(String requesterId) async {
    try {
      final response = await _apiClient.dio.post('friendship/decline/$requesterId');
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi từ chối lời mời: $e');
      return false;
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      final response = await _apiClient.dio.post('friendship/remove/$friendId');
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi xóa bạn bè: $e');
      return false;
    }
  }

  Future<bool> cancelFriendRequest(String receiverId) async {
    try {
      final response = await _apiClient.dio.post('friendship/cancel/$receiverId');
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi hủy lời mời: $e');
      return false;
    }
  }
}
