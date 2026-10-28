import 'package:dio/dio.dart';
import 'package:dio/browser.dart'; // Hỗ trợ cấu hình Cookie trên Web
import 'package:flutter/foundation.dart';
import 'package:manage_intern/core/constants/api_constants.dart';
import 'package:manage_intern/core/storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio = _createDio();
  // Lưu ETag theo URL (chỉ áp dụng cho GET request)
  final Map<String, _EtagCacheEntry> _etagCache = {};
  // Xóa cache khi logout
  void clearCache() => _etagCache.clear();

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

          // Nếu là GET và đã có ETag trong cache -> Gửi kèm If-None-Match
          if (options.method.toUpperCase() == 'GET') {
            final cacheKey = options.uri.toString();
            final cached = _etagCache[cacheKey];
            if (cached != null) {
              options.headers['If-None-Match'] = cached.etag;
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Nếu GET trả về 200 kèm header ETag -> Lưu vào cache
          if (response.requestOptions.method.toUpperCase() == 'GET' &&
              response.statusCode == 200) {
            final etag = response.headers.value('etag');
            if (etag != null && etag.isNotEmpty) {
              final cacheKey = response.requestOptions.uri.toString();
              _etagCache[cacheKey] = _EtagCacheEntry(
                etag: etag,
                data: response.data,
              );
            }
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;

          // 1. Xử lý khi Server trả về 304 Not Modified (Dữ liệu không đổi)
          if (statusCode == 304 &&
              error.requestOptions.method.toUpperCase() == 'GET') {
            final cacheKey = error.requestOptions.uri.toString();
            final cached = _etagCache[cacheKey];
            if (cached != null && error.response != null) {
              error.response!.data = cached.data;
              error.response!.statusCode = 200;
              return handler.resolve(error.response!);
            }
          }

          // 2. Xử lý khi bị 401 Unauthorized (Refresh Token)
          final isUnauthorized = statusCode == 401;
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

class _EtagCacheEntry {
  final String etag;
  final dynamic data;

  _EtagCacheEntry({required this.etag, required this.data});
}
