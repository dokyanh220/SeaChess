import 'package:client/core/network/api_client.dart';
import 'package:client/core/services/local_storage_service.dart';
import 'package:client/domain/models/UserProfileResponse.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final LocalStorageService _localStorageService;

  AuthRepository(this._apiClient, this._localStorageService);

  Future<bool> register(
    String username,
    String displayName,
    String password,
    String email,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/register',
        data: {
          'username': username,
          'displayname': displayName,
          'password': password,
          'email': email,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['token'];

        await _localStorageService.saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];

        await _localStorageService.saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return false;
    }
  }

  Future<bool> guestLogin() async {
    try {
      final response = await _apiClient.dio.post('auth/guest-login');
      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _localStorageService.saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi đăng nhập khách: $e');
      return false;
    }
  }

  Future<bool> upgradeGuest(
    String username,
    String displayName,
    String password,
    String email,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/upgrade-guest',
        data: {
          'username': username,
          'displayname': displayName,
          'password': password,
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _localStorageService.saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi nâng cấp tài khoản khách: $e');
      return false;
    }
  }

  Future<UserProfile?> getMyProfile() async {
    try {
      // Bỏ qua browser cache bằng cách thêm timestamp (đặc biệt khi chạy Flutter Web / Chrome)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final res = await _apiClient.dio.get('user/me?t=$timestamp');
      if (res.statusCode == 200) {
        return UserProfile.fromJson(res.data);
      }
      return null;
    } catch (e) {
      print('Lỗi lấy data user: $e');
      return null;
    }
  }

  /// Gửi lại email xác thực
  Future<bool> resendVerificationEmail() async {
    try {
      final response = await _apiClient.dio.post('auth/send-verification');
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi gửi email xác thực: $e');
      return false;
    }
  }
}
