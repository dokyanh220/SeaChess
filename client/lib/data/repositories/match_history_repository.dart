import 'package:dio/dio.dart';
import 'package:client/domain/models/match_history_model.dart';
import 'package:client/core/network/api_client.dart';

class MatchHistoryRepository {
  final ApiClient _apiClient;

  MatchHistoryRepository(this._apiClient);

  Future<List<MatchHistoryModel>> getMatchHistory({int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/match/history',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MatchHistoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load match history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
