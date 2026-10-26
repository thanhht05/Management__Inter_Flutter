class ApiResponse<T> {
  final bool success;
  final String? code;
  final String? message;
  final int? statusCode;
  final T? data;

  ApiResponse(
      {required this.success,
      this.code,
      this.message,
      this.statusCode,
      this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json["success"] ?? false,
      code: json["code"]?.toString(),
      message: json["message"]?.toString(),
      statusCode: json["statusCode"] is int ? json["statusCode"] : null,
      data: json["data"] != null ? fromJsonT(json["data"]) : null,
    );
  }
}
