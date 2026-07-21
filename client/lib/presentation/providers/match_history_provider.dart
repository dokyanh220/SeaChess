import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/domain/models/match_history_model.dart';
import 'package:client/data/repositories/match_history_repository.dart';
import 'package:client/presentation/providers/auth_providers.dart';

final matchHistoryRepositoryProvider = Provider<MatchHistoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchHistoryRepository(apiClient);
});

final matchHistoryProvider = FutureProvider.autoDispose<List<MatchHistoryModel>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) {
    return [];
  }
  
  final repository = ref.watch(matchHistoryRepositoryProvider);
  return repository.getMatchHistory(limit: 20);
});
