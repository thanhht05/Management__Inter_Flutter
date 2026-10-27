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
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMore => _currentPage + 1 < _totalPages;
  String get keyword => _keyword;
  String? get selectedStatus => _selectedStatus;

  // Tải danh sách (refresh = true sẽ đưa về trang 0)
  Future<void> fetchInterns({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 0;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      if (_isLoadingMore || !hasMore) {
        return;
      }
      _isLoadingMore = true;
      notifyListeners();
    }

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
      _errorMessage = ApiClient.getErrorMessage(e);
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Tìm kiếm theo từ khóa
  void setKeyword(String value) {
    _keyword = value;
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
}
