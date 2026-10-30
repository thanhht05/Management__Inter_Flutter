import 'package:flutter/material.dart';
import 'package:manage_intern/core/utils/validators.dart';
import 'package:manage_intern/providers/auth_provider.dart';
import 'package:manage_intern/widgets/change_password_dialog.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Tin Cá Nhân'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more),
            tooltip: 'Tùy chọn',
            onSelected: (value) {
              if (value == 'change_password') {
                showChangePasswordDialog(context);
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Đổi mật khẩu'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Vai trò (Role)'),
                    subtitle: Text(user.role?.roleName ?? 'Chưa xác định'),
                  ),
                  if (user.department != null)
                    ListTile(
                      leading: const Icon(Icons.business_outlined),
                      title: const Text('Phòng ban'),
                      subtitle: Text(user.department!.title),
                    ),
                  if (user.internCount != null)
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('Số thực tập sinh phụ trách'),
                      subtitle: Text('${user.internCount} bạn'),
                    ),
                  if (user.role?.roleName == 'ADMIN') ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.supervisor_account_outlined,
                          color: Colors.blue),
                      title: const Text(
                        'Quản lý người hướng dẫn (Mentors)',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.blue),
                      onTap: () => Navigator.pushNamed(context, '/mentors'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
