import 'package:client/data/repositories/friendship_repository.dart';
import 'package:client/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FriendshipRepository(apiClient);
});
