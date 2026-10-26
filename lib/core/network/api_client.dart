import 'package:dio/dio.dart';
import 'package:manage_intern/core/constants/api_constants.dart';
import 'package:manage_intern/core/storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio = _createDio();

  Dio _createDio() {
    final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }));

    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await TokenStorage.instance.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers["authorization"] = "Bearer ${token}";
      }
      return handler.next(options);
    }, onError: (DioException e, handler) {
      // Khi bị 401 Unauthorized (Token hết hạn), xóa token cũ
      if (e.response?.statusCode == 401) {
        TokenStorage.instance.clearAll();
      }
      return handler.next(e);
    }));
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
        return 'Tên đăng nhập hoặc mật khẩu không chính xác.';
      }
      return 'Lỗi máy chủ (${error.response?.statusCode ?? "Network"}).';
    }
    return error.toString();
  }
}
