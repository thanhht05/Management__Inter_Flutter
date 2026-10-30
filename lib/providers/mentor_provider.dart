import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:manage_intern/core/network/api_client.dart';
import 'package:manage_intern/modles/user_model.dart';
import 'package:manage_intern/services/mentor_service.dart';

class MentorProvider extends ChangeNotifier {
  final MentorService _mentorService = MentorService();

  List<UserModel> _mentors = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 0;
  int _totalPages = 0;
  int _totalItems = 0;
  final int _pageSize = 10;

  // Filters
  String _keyword = '';
  int? _selectedDepartmentId;
  bool? _selectedIsActive;
  String? _startDate;
  String? _endDate;

  // Master Data
  List<DepartmentSummaryModel> _departments = [];
  bool _isDepartmentsLoading = false;

  // Update State
  bool _isUpdating = false;
  String? _updateError;
  String? _updateErrorCode;

  // Getters
  List<UserModel> get mentors => _mentors;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMore => _currentPage + 1 < _totalPages;

  String get keyword => _keyword;
  int? get selectedDepartmentId => _selectedDepartmentId;
  bool? get selectedIsActive => _selectedIsActive;
  String? get startDate => _startDate;
  String? get endDate => _endDate;

  List<DepartmentSummaryModel> get departments => _departments;
  bool get isDepartmentsLoading => _isDepartmentsLoading;

  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;
  String? get updateErrorCode => _updateErrorCode;

  int _requestSeq = 0;

  Future<void> fetchMentors({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 0;
      _isLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
      notifyListeners();
    } else {
      if (_isLoadingMore || !hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    final seq = ++_requestSeq;

    try {
      final targetPage = refresh ? 0 : _currentPage + 1;
      final res = await _mentorService.getAllMentors(
        page: targetPage,
        limit: _pageSize,
        keyword: _keyword,
        departmentId: _selectedDepartmentId,
        isActive: _selectedIsActive,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (seq != _requestSeq) return;

      if (res.success && res.data != null) {
        final pageData = res.data!;
        if (refresh) {
          _mentors = pageData.items;
        } else {
          _mentors.addAll(pageData.items);
        }
        _currentPage = pageData.currentPage;
        _totalPages = pageData.totalPages;
        _totalItems = pageData.totalItems;
      } else {
        _errorMessage =
            res.message ?? 'Không thể tải danh sách người hướng dẫn';
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

  Future<void> loadDepartments() async {
    if (_departments.isNotEmpty) return;
    _isDepartmentsLoading = true;
    notifyListeners();
    try {
      _departments = await _mentorService.getDepartments();
    } catch (_) {
      // Bỏ qua lỗi phụ để không block màn hình chính
    } finally {
      _isDepartmentsLoading = false;
      notifyListeners();
    }
  }

  void setKeyword(String value) {
    final kw = value.trim();
    if (kw == _keyword) return;
    _keyword = kw;
    fetchMentors(refresh: true);
  }

  void setDepartmentFilter(int? departmentId) {
    if (_selectedDepartmentId == departmentId) return;
    _selectedDepartmentId = departmentId;
    fetchMentors(refresh: true);
  }

  void setStatusFilter(bool? isActive) {
    if (_selectedIsActive == isActive) return;
    _selectedIsActive = isActive;
    fetchMentors(refresh: true);
  }

  void setDateRange(String? start, String? end) {
    _startDate = start;
    _endDate = end;
    fetchMentors(refresh: true);
  }

  void clearFilters() {
    _keyword = '';
    _selectedDepartmentId = null;
    _selectedIsActive = null;
    _startDate = null;
    _endDate = null;
    fetchMentors(refresh: true);
  }

  Future<bool> updateMentor(String userId, UserUpdateRequest request) async {
    _isUpdating = true;
    _updateError = null;
    _updateErrorCode = null;
    notifyListeners();
    try {
      final res = await _mentorService.updateMentor(userId, request);
      if (res.success) {
        _isUpdating = false;
        notifyListeners();
        await fetchMentors(refresh: true);
        return true;
      }
      _updateError = res.message ?? 'Cập nhật người hướng dẫn thất bại';
      _updateErrorCode = res.code;
      return false;
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        _updateErrorCode = e.response?.data['code']?.toString();
      }
      _updateError = ApiClient.getErrorMessage(e);
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
