import 'package:flutter/material.dart';
import 'package:manage_intern/core/utils/debouncer.dart';
import 'package:manage_intern/modles/user_model.dart';
import 'package:manage_intern/providers/mentor_provider.dart';
import 'package:manage_intern/widgets/user_edit_dialog.dart';
import 'package:provider/provider.dart';

class MentorListScreen extends StatefulWidget {
  const MentorListScreen({super.key});

  @override
  State<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends State<MentorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Debouncer _searchDebouncer = Debouncer();

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'Tất cả', 'value': null},
    {'label': 'Đang hoạt động', 'value': true},
    {'label': 'Vô hiệu hóa', 'value': false},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<MentorProvider>();
      p.fetchMentors(refresh: true);
      p.loadDepartments();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<MentorProvider>().fetchMentors(refresh: false);
      }
    });
  }

  @override
  void dispose() {
    _searchDebouncer.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Người Hướng Dẫn (${provider.totalItems})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => provider.fetchMentors(refresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Tài khoản',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {});
                _searchDebouncer.run(() => provider.setKeyword(val));
              },
              onSubmitted: (val) {
                _searchDebouncer.cancel();
                provider.setKeyword(val);
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo họ tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchDebouncer.cancel();
                          _searchController.clear();
                          provider.setKeyword('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Bộ lọc Trạng thái (Filter Chips)
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _statusOptions[index];
                final isSelected = provider.selectedIsActive == option['value'];
                return ChoiceChip(
                  label: Text(option['label'] as String),
                  selected: isSelected,
                  onSelected: (_) =>
                      provider.setStatusFilter(option['value'] as bool?),
                );
              },
            ),
          ),

          // Bộ lọc Phòng ban
          if (provider.departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: provider.selectedDepartmentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Phòng ban',
                        prefixIcon: const Icon(Icons.business_outlined),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tất cả phòng ban'),
                        ),
                        ...provider.departments.map(
                          (d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(d.title),
                          ),
                        ),
                      ],
                      onChanged: (id) => provider.setDepartmentFilter(id),
                    ),
                  ),
                  if (provider.selectedDepartmentId != null ||
                      provider.selectedIsActive != null ||
                      _searchController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Xóa bộ lọc',
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearFilters();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),

          const Divider(height: 16),

          // Thông tin phân trang
          if (!provider.isLoading && provider.totalItems > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hiển thị ${provider.mentors.length} / ${provider.totalItems} người hướng dẫn',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Trang ${provider.currentPage + 1} / ${provider.totalPages}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

          // Danh sách Mentors
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(MentorProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.mentors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.fetchMentors(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.mentors.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy người hướng dẫn nào.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchMentors(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: provider.mentors.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.mentors.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final UserModel mentor = provider.mentors[index];
          final activeColor = mentor.isActive ? Colors.green : Colors.grey;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    mentor.fullName.isNotEmpty
                        ? mentor.fullName[0].toUpperCase()
                        : 'M',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ),
                title: Text(
                  mentor.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            mentor.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Phòng ban: ${mentor.department?.title ?? "Chưa gán"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Thực tập sinh: ${mentor.internCount ?? 0} bạn',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: activeColor),
                      ),
                      child: Text(
                        mentor.isActive ? 'Hoạt động' : 'Vô hiệu hóa',
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: Colors.blue),
                      tooltip: 'Chỉnh sửa Mentor',
                      onPressed: () => UserEditDialog.show(context, mentor),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
