import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static String baseUrl = defaultBaseUrl;

  // Endpoints cho Module Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String getMyInfo = '/users/get-my-info';

  static const String changePassword = '/users/change-password';
}
