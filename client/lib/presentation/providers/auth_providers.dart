import 'package:client/core/network/api_client.dart';
import 'package:client/core/services/local_storage_service.dart';
import 'package:client/core/services/signalr_service.dart';
import 'package:client/data/repositories/auth_repository.dart';
import 'package:client/domain/models/UserProfileResponse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return ApiClient(localStorage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localStorage = ref.watch(localStorageProvider);
  return AuthRepository(apiClient, localStorage);
});

class AuthNotifier extends StateNotifier<bool> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(false);

  Future<bool> register(
    String username,
    String password,
    String email,
    String displayName,
  ) async {
    state = true;

    final isSuccess = await _repository.register(
      username,
      displayName,
      password,
      email,
    );

    state = false;
    return isSuccess;
  }

  Future<bool> login(String username, String password) async {
    state = true;

    final isSuccess = await _repository.login(username, password);

    state = false;
    return isSuccess;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

final signalRServiceProvider = Provider<SignalrService>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return SignalrService(localStorage);
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getMyProfile();
});
