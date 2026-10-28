import 'package:flutter/material.dart';
import 'package:manage_intern/modles/intern_model.dart';
import 'package:manage_intern/providers/intern_provider.dart';
import 'package:manage_intern/screens/interns/intern_form_screen.dart';
import 'package:provider/provider.dart';

class InternDetailScreen extends StatefulWidget {
  final int internId;
  final InternModel? initialIntern;

  const InternDetailScreen({
    super.key,
    required this.internId,
    this.initialIntern,
  });

  @override
  State<InternDetailScreen> createState() => _InternDetailScreenState();
}

class _InternDetailScreenState extends State<InternDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternProvider>().fetchInternDetail(
            widget.internId,
            initialData: widget.initialIntern,
          );
    });
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Đang thực tập (ACTIVE)';
      case 'WARNING':
        return 'Cảnh báo (WARNING)';
      case 'COMPLETED':
        return 'Hoàn thành (COMPLETED)';
      case 'DROPPED':
        return 'Ngừng thực tập (DROPPED)';
      default:
        return status;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'Chưa cập nhật';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final twoDigits = (int n) => n.toString().padLeft(2, '0');
      return '${twoDigits(dt.day)}/${twoDigits(dt.month)}/${dt.year} ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InternProvider>();
    final intern = provider.selectedIntern;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Thực Tập Sinh'),
        actions: [
          if (intern != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InternFormScreen(intern: intern),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: provider.isDetailLoading
                ? null
                : () => provider.fetchInternDetail(widget.internId),
          ),
        ],
      ),
      body: _buildBody(provider, intern),
    );
  }

  Widget _buildBody(InternProvider provider, InternModel? intern) {
    if (provider.isDetailLoading && intern == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.detailErrorMessage != null && intern == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                provider.detailErrorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.fetchInternDetail(widget.internId),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (intern == null) {
      return const Center(child: Text('Không tìm thấy thông tin thực tập sinh.'));
    }

    final statusColor = _getStatusColor(intern.internStatus);

    return RefreshIndicator(
      onRefresh: () => provider.fetchInternDetail(widget.internId),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (provider.isDetailLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: LinearProgressIndicator(),
            ),
          if (provider.detailErrorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                provider.detailErrorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Header Card: Avatar, Họ tên, ID & Trạng thái
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: statusColor.withAlpha(38),
                    child: Text(
                      intern.fullName.isNotEmpty
                          ? intern.fullName[0].toUpperCase()
                          : 'I',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    intern.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã TTS: #${intern.id}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusLabel(intern.internStatus),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Thông tin Thực tập (Position, Batch, Start/End Date)
          _buildSectionCard(
            title: 'Thông Tin Thực Tập',
            icon: Icons.work_outline,
            children: [
              _buildInfoRow(
                icon: Icons.badge_outlined,
                label: 'Vị trí (Position)',
                value: intern.position?.title ?? 'Chưa gán',
              ),
              const Divider(height: 20),
              _buildInfoRow(
                icon: Icons.groups_outlined,
                label: 'Đợt thực tập (Batch)',
                value: intern.internshipBatch?.name ?? 'Chưa gán',
              ),
              const Divider(height: 20),
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Ngày bắt đầu',
                value: intern.startDate ?? 'Chưa xác định',
              ),
              const Divider(height: 20),
              _buildInfoRow(
                icon: Icons.event_available_outlined,
                label: 'Ngày kết thúc',
                value: intern.endDate ?? 'Chưa xác định',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thông tin Mentor hướng dẫn
          _buildSectionCard(
            title: 'Người Hướng Dẫn (Mentor)',
            icon: Icons.supervisor_account_outlined,
            children: [
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Họ tên Mentor',
                value: intern.mentor?.fullName ?? 'Chưa phân công',
              ),
              const Divider(height: 20),
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email liên hệ',
                value: intern.mentor?.email ?? 'Chưa có thông tin',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thông tin Hệ thống (CreatedAt, UpdatedAt)
          _buildSectionCard(
            title: 'Thông Tin Hệ Thống',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow(
                icon: Icons.access_time_outlined,
                label: 'Ngày tạo hồ sơ',
                value: _formatDateTime(intern.createdAt),
              ),
              const Divider(height: 20),
              _buildInfoRow(
                icon: Icons.update_outlined,
                label: 'Cập nhật lần cuối',
                value: _formatDateTime(intern.updatedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

