import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:manage_intern/modles/intern_model.dart';
import 'package:manage_intern/providers/intern_provider.dart';
import 'package:provider/provider.dart';

class InternListScreen extends StatefulWidget {
  const InternListScreen({super.key});
  @override
  State<InternListScreen> createState() => _InternListScreenState();
}

class _InternListScreenState extends State<InternListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String?>> _statusOptions = [
    {'label': 'Tất cả', 'value': null},
    {'label': 'Đang thực tập', 'value': 'ACTIVE'},
    {'label': 'Hoàn thành', 'value': 'COMPLETED'},
    {'label': 'Cảnh báo', 'value': 'WARNING'},
    {'label': 'Không đạt', 'value': 'DROPPED'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternProvider>().fetchInterns(refresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<InternProvider>().fetchInterns(refresh: false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.blue;
      case 'WARNING':
        return Colors.teal;
      case 'COMPLETED':
        return Colors.green;
      case 'DROPPED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InternProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Thực Tập Sinh (${provider.totalItems})'),
        actions: [
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: TextField(
              controller: _searchController,
              onSubmitted: (val) => provider.setKeyword(val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo họ tên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setKeyword("");
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Bộ lọc trạng thái (Filter Chips)
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _statusOptions[index];
                final isSelected = provider.selectedStatus == option['value'];
                return ChoiceChip(
                  label: Text(option['label']!),
                  selected: isSelected,
                  onSelected: (_) => provider.setStatusFilter(option['value']),
                );
              },
            ),
          ),
          const Divider(height: 16),
          // Thanh hiển thị thông tin phân trang
          if (!provider.isLoading && provider.totalItems > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hiển thị ${provider.interns.length} / ${provider.totalItems} thực tập sinh',
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
          // Danh sách thực tập sinh
          Expanded(
            child: _buildBody(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(InternProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.interns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => provider.fetchInterns(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (provider.interns.isEmpty) {
      return const Center(child: Text('Không tìm thấy thực tập sinh nào.'));
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchInterns(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: provider.interns.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.interns.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final InternModel intern = provider.interns[index];
          final statusColor = _getStatusColor(intern.internStatus);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withAlpha(38),
                child: Text(
                  intern.fullName.isNotEmpty
                      ? intern.fullName[0].toUpperCase()
                      : "I",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              title: Text(
                intern.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Vị trí: ${intern.position?.title ?? "Chưa gán"}'),
                  Text('Mentor: ${intern.mentor?.fullName ?? "Chưa gán"}'),
                  if (intern.startDate != null || intern.endDate != null)
                    Text(
                      'Thời gian: ${intern.startDate ?? "?"} → ${intern.endDate ?? "?"}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  intern.internStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
