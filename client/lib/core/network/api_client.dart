import 'dart:convert';

import 'package:client/core/constants/app_constants.dart';
import 'package:client/core/services/local_storage_service.dart';
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio dio; // late final là cho phép chưa được khởi tạo
  final LocalStorageService _localStorageService;

  ApiClient(this._localStorageService) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppContans.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _localStorageService.getToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // TODO: Xử lý refresh token
          }
          return handler.next(e);
        },
      ),
    );
  }
}
