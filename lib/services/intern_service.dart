import 'package:manage_intern/core/constants/api_constants.dart';
import 'package:manage_intern/core/network/api_client.dart';
import 'package:manage_intern/core/network/api_response.dart';
import 'package:manage_intern/modles/intern_model.dart';

class InternService {
  final ApiClient _client = ApiClient.instance;

  Future<ApiResponse<PageResponse<InternModel>>> getAllInterns(
      {int page = 0,
      int limit = 5,
      String? keyword,
      String? status,
      String? startDate,
      String? endDate,
      int? positionId,
      String? mentorId}) async {
    final Map<String, dynamic> queryParams = {
      "page": page,
      "limit": limit,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (positionId != null) 'position_id': positionId,
      if (mentorId != null && mentorId.isNotEmpty) 'mentor_id': mentorId,
    };

    final response = await _client.dio
        .get(ApiConstants.interns, queryParameters: queryParams);
    return ApiResponse<PageResponse<InternModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (dataJson) => PageResponse<InternModel>.fromJson(
            dataJson as Map<String, dynamic>,
            (itemJson) => InternModel.fromJson(itemJson)));
  }
}
