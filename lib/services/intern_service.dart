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

  Future<ApiResponse<InternModel>> getInternById(int id) async {
    final response = await _client.dio.get(ApiConstants.internDetail(id));
    return ApiResponse<InternModel>.fromJson(
      response.data as Map<String, dynamic>,
      (dataJson) => InternModel.fromJson(dataJson as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<InternModel>> createIntern(
      InternCreationRequest request) async {
    final response =
        await _client.dio.post(ApiConstants.interns, data: request.toJson());
    return ApiResponse<InternModel>.fromJson(
      response.data as Map<String, dynamic>,
      (dataJson) => InternModel.fromJson(dataJson as Map<String, dynamic>),
    );
  }

  // Lấy danh sách items từ data (hỗ trợ cả dạng List thuần và PageResponse)
  List<Map<String, dynamic>> _extractItems(dynamic body) {
    final data = (body as Map<String, dynamic>)['data'];
    final list = data is List
        ? data
        : (data is Map ? (data['items'] as List? ?? []) : []);
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<PositionSummaryModel>> getPositions() async {
    final response = await _client.dio.get(ApiConstants.positions,
        queryParameters: {'page': 0, 'limit': 50});
    return _extractItems(response.data)
        .map(PositionSummaryModel.fromJson)
        .toList();
  }

  Future<List<InternshipBatchSummaryModel>> getInternshipBatches() async {
    final response = await _client.dio.get(ApiConstants.internshipBatches,
        queryParameters: {'page': 0, 'limit': 50});
    return _extractItems(response.data)
        .map(InternshipBatchSummaryModel.fromJson)
        .toList();
  }

  Future<List<MentorSummaryModel>> getMentors() async {
    final response = await _client.dio.get(ApiConstants.mentors);
    return _extractItems(response.data)
        .map(MentorSummaryModel.fromJson)
        .toList();
  }
}
