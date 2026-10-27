import 'package:dio/dio.dart';
import 'package:dio/browser.dart'; // Hỗ trợ cấu hình Cookie trên Web
import 'package:flutter/foundation.dart';
import 'package:manage_intern/core/constants/api_constants.dart';
import 'package:manage_intern/core/storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        extra: {'withCredentials': true}, // Cho phép gửi & nhận Cookie trên Web
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Kích hoạt withCredentials trên Flutter Web
    if (kIsWeb) {
      final adapter = dio.httpClientAdapter;
      if (adapter is BrowserHttpClientAdapter) {
        adapter.withCredentials = true;
      }
    }

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isAuthPath =
              error.requestOptions.path.contains('/auth/login') ||
                  error.requestOptions.path.contains('/auth/refresh');

          if (isUnauthorized && !isAuthPath) {
            final refreshToken = await TokenStorage.instance.getRefreshToken();

            try {
              // Tạo refreshDio có hỗ trợ Cookie
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: ApiConstants.baseUrl,
                  extra: {'withCredentials': true},
                  headers: {
                    'Content-Type': 'application/json',
                    // Gắn header Cookie thủ công (hoạt động tốt trên cả Mobile Android/iOS)
                    if (refreshToken != null)
                      'Cookie': 'REFRESH_TOKEN=$refreshToken',
                  },
                ),
              );

              if (kIsWeb) {
                final adapter = refreshDio.httpClientAdapter;
                if (adapter is BrowserHttpClientAdapter) {
                  adapter.withCredentials = true;
                }
              }

              // Gọi API refresh
              final response = await refreshDio.post(
                ApiConstants.refreshToken,
                options: Options(extra: {'withCredentials': true}),
              );

              if (response.statusCode == 200 &&
                  response.data['success'] == true) {
                final newAccessToken = response.data['data']['accessToken'];
                final newRefreshToken = response.data['data']['refreshToken'];

                await TokenStorage.instance.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                );

                // Retry request ban đầu với token mới
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final retryResponse = await dio.fetch(options);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              await TokenStorage.instance.clearAll();
            }
          }

          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map &&
          error.response?.data['message'] != null) {
        return error.response!.data['message'].toString();
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến máy chủ. Kiểm tra Base URL.';
      }
      if (error.response?.statusCode == 401) {
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }
      return 'Lỗi máy chủ (${error.response?.statusCode ?? "Network"}).';
    }
    return error.toString();
  }
}
