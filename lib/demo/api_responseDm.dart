class ApiResponsedm<T> {
  final bool success;
  final String? message;
  final int? statusCode;
  final T? data;

  ApiResponsedm({
    required this.success,
    required this.statusCode,
    this.message,
    this.data,
  });

  factory ApiResponsedm.fromJson(
      Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return ApiResponsedm<T>(
      success: json["success"] ?? false,
      message: json["message"]?.toString(),
      statusCode: json["statusCode"] is int ? json["statusCode"] : null,
      data: json["data"] != null ? fromJsonT(json["data"]) : null,
    );
  }
}

class User {
  final int id;
  final String username;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }
}

void main() {
  final json = {
    "success": true,
    "message": "Login successful",
    "statusCode": 200,
    "data": {
      "id": 1,
      "username": "thanh",
      "email": "thanh@example.com",
    }
  };

  // Khai báo hàm chuyển JSON thành User

  User resUser(dynamic dataJson) {
    return User.fromJson(dataJson as Map<String, dynamic>);
  }

  final res = ApiResponsedm<User>.fromJson(json, resUser);
  print(res.data?.username);
}
