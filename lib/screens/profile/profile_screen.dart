import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:manage_intern/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Thông Tin Cá Nhân'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
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
                            color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ));
  }
}
