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

class PageResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;

  PageResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> itemJson) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PageResponse<T>(
      items: rawItems.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalItems: json['totalItems'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}
