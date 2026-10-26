class RoleModel {
  final String roleName;
  final String? desc;
  RoleModel({required this.roleName, this.desc});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
        roleName: json["roleName"] ?? "", desc: json["description"]);
  }
}

class DepartmentSummaryModel {
  final int id;
  final String title;
  DepartmentSummaryModel({required this.id, required this.title});
  factory DepartmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return DepartmentSummaryModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? dateOfBirth;
  final bool isActive;
  final RoleModel? role;
  final DepartmentSummaryModel? department;
  final int? internCount;
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.dateOfBirth,
    this.isActive = true,
    this.role,
    this.department,
    this.internCount,
  });
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      isActive: json['isActive'] ?? true,
      role: json['role'] != null ? RoleModel.fromJson(json['role']) : null,
      department: json['department'] != null
          ? DepartmentSummaryModel.fromJson(json['department'])
          : null,
      internCount: json['internCount'],
    );
  }
}

class LoginDataModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel? userResponse;
  LoginDataModel({
    required this.accessToken,
    this.refreshToken,
    this.userResponse,
  });
  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    return LoginDataModel(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'],
      userResponse: json['userResponse'] != null
          ? UserModel.fromJson(json['userResponse'])
          : null,
    );
  }
}
