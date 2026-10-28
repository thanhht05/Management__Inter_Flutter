import 'package:manage_intern/core/constants/api_constants.dart';
import 'package:manage_intern/core/network/api_client.dart';
import 'package:manage_intern/core/network/api_response.dart';
import 'package:manage_intern/core/storage/token_storage.dart';
import 'package:manage_intern/modles/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;
  final TokenStorage _storage = TokenStorage.instance;

  Future<ApiResponse<LoginDataModel>> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.login,
      data: {
        'email': username,
        'password': password,
      },
    );

    // convert json to LoginDataModel
    final apiResponse = ApiResponse<LoginDataModel>.fromJson(
      response.data as Map<String, dynamic>,
      (dataJson) => LoginDataModel.fromJson(dataJson as Map<String, dynamic>),
    );
    // Lưu token vào Storage nếu login thành công
    if (apiResponse.success && apiResponse.data != null) {
      await _storage.saveTokens(
          accessToken: apiResponse.data!.accessToken,
          refreshToken: apiResponse.data!.refreshToken);
    }
    return apiResponse;
  }

  Future<ApiResponse<void>> changePassword(
      {required String oldPass,
      required String newPass,
      required String confirmPass}) async {
    final response = await _client.dio.post(ApiConstants.changePassword, data: {
      "oldPassword": oldPass,
      "newPassword": newPass,
      "confirmPassword": confirmPass
    });
    return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>, (_) => null);
  }

  Future<ApiResponse<UserModel>> getMyInfo() async {
    final response = await _client.dio.get(ApiConstants.getMyInfo);

    return ApiResponse<UserModel>.fromJson(
      response.data as Map<String, dynamic>,
      (dataJson) => UserModel.fromJson(dataJson as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (_) {
    } finally {
      _client.clearCache();
      await _storage.clearAll();
    }
  }
}
