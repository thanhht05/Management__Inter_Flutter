import 'package:flutter/foundation.dart';
import 'package:manage_intern/core/network/api_client.dart';
import 'package:manage_intern/core/storage/token_storage.dart';
import 'package:manage_intern/modles/user_model.dart';
import 'package:manage_intern/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TokenStorage _storage = TokenStorage.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Kiểm tra trạng thái đăng nhập khi mở app

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    final hasToken = await _storage.hasAccessToken();

    if (hasToken) {
      _isAuthenticated = true;
      await fetchMyInfo();
    } else {
      _isAuthenticated = false;
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  // Xử lý Login

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response =
          await _authService.login(username: username, password: password);

      if (response.success && response.data != null) {
        _currentUser = response.data!.userResponse;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? "Đăng nhập thất bại.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = ApiClient.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tải thông tin cá nhân
  Future<void> fetchMyInfo() async {
    try {
      final res = await _authService.getMyInfo();
      if (res.success && res.data != null) {
        _currentUser = res.data;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Xử lý Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }
}
