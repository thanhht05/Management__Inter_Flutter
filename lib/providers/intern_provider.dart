import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:manage_intern/core/network/api_client.dart';
import 'package:manage_intern/modles/intern_model.dart';
import 'package:manage_intern/services/intern_service.dart';

class InternProvider extends ChangeNotifier {
  final InternService _internService = InternService();

  List<InternModel> _interns = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // State cho màn hình chi tiết
  InternModel? _selectedIntern;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  // Thông tin phân trang
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalItems = 0;
  final int _pageSize = 5;

  // Các bộ lọc hiện tại
  String _keyword = '';
  String? _selectedStatus;
  int? _selectedPositionId;
  String? _selectedMentorId;
  String? _startDate;
  String? _endDate;

  List<InternModel> get interns => _interns;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  InternModel? get selectedIntern => _selectedIntern;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMore => _currentPage + 1 < _totalPages;
  String get keyword => _keyword;
  String? get selectedStatus => _selectedStatus;

  // Mỗi lần gọi fetchInterns tăng 1; response nào không còn là mới nhất sẽ bị bỏ qua
  int _requestSeq = 0;

  // Tải danh sách (refresh = true sẽ đưa về trang 0)
  Future<void> fetchInterns({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 0;
      _isLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
      notifyListeners();
    } else {
      if (_isLoadingMore || !hasMore) {
        return;
      }
      _isLoadingMore = true;
      notifyListeners();
    }

    final seq = ++_requestSeq;

    try {
      final targetPage = refresh ? 0 : _currentPage + 1;
      final res = await _internService.getAllInterns(
          page: targetPage,
          limit: _pageSize,
          keyword: _keyword,
          status: _selectedStatus,
          positionId: _selectedPositionId,
          mentorId: _selectedMentorId,
          startDate: _startDate,
          endDate: _endDate);

      // Có request mới hơn đã được gửi -> bỏ qua kết quả cũ này
      if (seq != _requestSeq) return;

      if (res.success && res.data != null) {
        final pageData = res.data!;
        if (refresh) {
          _interns = pageData.items;
        } else {
          _interns.addAll(pageData.items);
        }
        _currentPage = pageData.currentPage;
        _totalPages = pageData.totalPages;
        _totalItems = pageData.totalItems;
      } else {
        _errorMessage = res.message ?? 'Không thể tải danh sách thực tập sinh';
      }
    } catch (e) {
      if (seq != _requestSeq) return;
      _errorMessage = ApiClient.getErrorMessage(e);
    } finally {
      if (seq == _requestSeq) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  // Tìm kiếm theo từ khóa
  void setKeyword(String value) {
    final keyword = value.trim();
    if (keyword == _keyword) return;
    _keyword = keyword;
    fetchInterns(refresh: true);
  }

  // Lọc theo trạng thái (null = Tất cả)
  void setStatusFilter(String? status) {
    _selectedStatus = status;
    fetchInterns(refresh: true);
  }

  // Xóa toàn bộ bộ lọc
  void clearFilters() {
    _keyword = '';
    _selectedStatus = null;
    _selectedPositionId = null;
    _selectedMentorId = null;
    _startDate = null;
    _endDate = null;
    fetchInterns(refresh: true);
  }

  // ===== Form tạo mới thực tập sinh =====
  List<PositionSummaryModel> _positions = [];
  List<InternshipBatchSummaryModel> _batches = [];
  List<MentorSummaryModel> _mentors = [];
  bool _isFormDataLoading = false;
  String? _formDataError;
  bool _isSubmitting = false;
  String? _submitError;
  String? _submitErrorCode;

  List<PositionSummaryModel> get positions => _positions;
  List<InternshipBatchSummaryModel> get batches => _batches;
  List<MentorSummaryModel> get mentors => _mentors;
  bool get isFormDataLoading => _isFormDataLoading;
  String? get formDataError => _formDataError;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  String? get submitErrorCode => _submitErrorCode;

  // Tải song song 3 danh sách cho Dropdown
  Future<void> loadFormMasterData() async {
    _isFormDataLoading = true;
    _formDataError = null;
    _submitError = null;
    _submitErrorCode = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _internService.getPositions(),
        _internService.getInternshipBatches(),
        _internService.getMentors(),
      ]);
      _positions = results[0] as List<PositionSummaryModel>;
      _batches = results[1] as List<InternshipBatchSummaryModel>;
      _mentors = results[2] as List<MentorSummaryModel>;
    } catch (e) {
      _formDataError = ApiClient.getErrorMessage(e);
    } finally {
      _isFormDataLoading = false;
      notifyListeners();
    }
  }

  // Tạo mới thực tập sinh. Trả về true nếu thành công.
  Future<bool> createIntern(InternCreationRequest request) async {
    _isSubmitting = true;
    _submitError = null;
    _submitErrorCode = null;
    notifyListeners();
    try {
      final res = await _internService.createIntern(request);
      if (res.success) {
        _isSubmitting = false;
        notifyListeners();
        await fetchInterns(refresh: true);
        return true;
      }
      _submitError = res.message ?? 'Tạo thực tập sinh thất bại';
      _submitErrorCode = res.code;
      return false;
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        _submitErrorCode = e.response?.data['code']?.toString();
      }
      _submitError = ApiClient.getErrorMessage(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Cập nhật thực tập sinh. Trả về true nếu thành công.
  Future<bool> updateIntern(int id, InternUpdateRequest request) async {
    _isSubmitting = true;
    _submitError = null;
    _submitErrorCode = null;
    notifyListeners();
    try {
      final res = await _internService.updateIntern(id, request);
      if (res.success) {
        if (_selectedIntern?.id == id && res.data != null) {
          _selectedIntern = res.data;
        }
        _isSubmitting = false;
        notifyListeners();
        await fetchInterns(refresh: true);
        return true;
      }
      _submitError = res.message ?? 'Cập nhật thực tập sinh thất bại';
      _submitErrorCode = res.code;
      return false;
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        _submitErrorCode = e.response?.data['code']?.toString();
      }
      _submitError = ApiClient.getErrorMessage(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Tải thông tin chi tiết 1 thực tập sinh theo ID
  Future<void> fetchInternDetail(int id, {InternModel? initialData}) async {
    if (initialData != null) {
      _selectedIntern = initialData;
    } else if (_selectedIntern?.id != id) {
      _selectedIntern = null;
    }
    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final res = await _internService.getInternById(id);
      if (res.success && res.data != null) {
        _selectedIntern = res.data;
      } else {
        _detailErrorMessage =
            res.message ?? 'Không thể tải thông tin chi tiết thực tập sinh';
      }
    } catch (e) {
      _detailErrorMessage = ApiClient.getErrorMessage(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }
}
