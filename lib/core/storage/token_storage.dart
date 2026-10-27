import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  // private constructor
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyAccessToken = "access_token";
  static const String _keyRefreshToken = "refresh_token";

  Future<void> saveTokens(
      {required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);

    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
