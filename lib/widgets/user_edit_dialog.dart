import 'package:flutter/material.dart';
import 'package:manage_intern/core/utils/validators.dart';
import 'package:manage_intern/modles/user_model.dart';
import 'package:manage_intern/providers/mentor_provider.dart';
import 'package:provider/provider.dart';

class UserEditDialog extends StatefulWidget {
  final UserModel user;

  const UserEditDialog({super.key, required this.user});

  static Future<bool?> show(BuildContext context, UserModel user) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserEditDialog(user: user),
    );
  }

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  DateTime? _dateOfBirth;
  int? _departmentId;
  late bool _isActive;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _fullNameController = TextEditingController(text: u.fullName);
    _emailController = TextEditingController(text: u.email);
    _departmentId = u.department?.id;
    _isActive = u.isActive;

    if (u.dateOfBirth != null && u.dateOfBirth!.isNotEmpty) {
      _dateOfBirth = DateTime.tryParse(u.dateOfBirth!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MentorProvider>().loadDepartments();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _toApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _toDisplayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(1995, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  bool get _hasChanges {
    final u = widget.user;
    final currentFullName = _fullNameController.text.trim();
    final currentEmail = _emailController.text.trim();
    final currentPassword = _passwordController.text.trim();
    final currentDateOfBirth =
        _dateOfBirth != null ? _toApiDate(_dateOfBirth!) : null;
    final originalDateOfBirth =
        (u.dateOfBirth != null && u.dateOfBirth!.isNotEmpty)
            ? u.dateOfBirth
            : null;

    if (currentPassword.isNotEmpty) return true;
    if (currentFullName != u.fullName.trim()) return true;
    if (currentEmail != u.email.trim()) return true;
    if (_departmentId != u.department?.id) return true;
    if (currentDateOfBirth != originalDateOfBirth) return true;
    if (_isActive != u.isActive) return true;

    return false;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phòng ban'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Nếu không có thay đổi nào, đóng dialog và không gọi API
    if (!_hasChanges) {
      Navigator.pop(context, false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có thông tin nào thay đổi'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final provider = context.read<MentorProvider>();
    final ok = await provider.updateMentor(
      widget.user.id,
      UserUpdateRequest(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        dateOfBirth: _dateOfBirth != null ? _toApiDate(_dateOfBirth!) : null,
        departmentId: _departmentId!,
        isActive: _isActive,
      ),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật người hướng dẫn thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.updateError ?? 'Cập nhật thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MentorProvider>();
    final updating = provider.isUpdating;
    final departments = provider.departments;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note_outlined, color: Colors.blue),
          SizedBox(width: 8),
          Text('Chỉnh Sửa Mentor', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      Validators.validateRequired(v, fieldName: 'họ và tên'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới (tùy chọn)',
                    helperText: 'Để trống nếu không đổi mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: Validators.validateOptionalPassword,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _departmentId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Phòng ban *',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: departments
                      .map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.title)))
                      .toList(),
                  onChanged: (v) => setState(() => _departmentId = v),
                  validator: (v) =>
                      v == null ? 'Vui lòng chọn phòng ban' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: updating ? null : _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh',
                      prefixIcon: Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_dateOfBirth == null
                        ? 'Chưa cập nhật'
                        : _toDisplayDate(_dateOfBirth!)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Trạng thái hoạt động'),
                  subtitle: Text(_isActive ? 'Đang hoạt động' : 'Vô hiệu hóa'),
                  value: _isActive,
                  onChanged:
                      updating ? null : (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: updating ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          onPressed: updating ? null : _submit,
          icon: updating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(updating ? 'Đang lưu...' : 'Lưu thay đổi'),
        ),
      ],
    );
  }
}
