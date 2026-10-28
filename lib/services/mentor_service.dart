import 'package:manage_intern/core/constants/api_constants.dart';
import 'package:manage_intern/core/network/api_client.dart';
import 'package:manage_intern/core/network/api_response.dart';
import 'package:manage_intern/modles/user_model.dart';

class MentorService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResponse<PageResponse<UserModel>>> getAllMentors({
    int page = 0,
    int limit = 10,
    String? keyword,
    String? startDate,
    String? endDate,
    int? departmentId,
    bool? isActive,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (departmentId != null) 'department_id': departmentId,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await _client.dio.get(
      ApiConstants.mentors,
      queryParameters: queryParams,
    );

    return ApiResponse<PageResponse<UserModel>>.fromJson(
      response.data as Map<String, dynamic>,
      (dataJson) => PageResponse<UserModel>.fromJson(
        dataJson as Map<String, dynamic>,
        (itemJson) => UserModel.fromJson(itemJson),
      ),
    );
  }

  Future<List<DepartmentSummaryModel>> getDepartments() async {
    final response = await _client.dio.get(
      ApiConstants.departments,
      queryParameters: {'page': 0, 'limit': 50},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    final list = data is List
        ? data
        : (data is Map ? (data['items'] as List? ?? []) : []);
    return list
        .map((e) => DepartmentSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiResponse<UserModel>> updateMentor(
    String userId,
    UserUpdateRequest request,
  ) async {
    final response = await _client.dio.put(
      ApiConstants.userDetail(userId),
      data: request.toJson(),
    );
    return ApiResponse<UserModel>.fromJson(
      response.data as Map<String, dynamic>,
      (dataJson) => UserModel.fromJson(dataJson as Map<String, dynamic>),
    );
  }
}
