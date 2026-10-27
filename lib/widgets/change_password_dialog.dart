import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:manage_intern/core/utils/validators.dart';
import 'package:manage_intern/providers/auth_provider.dart';
import 'package:provider/provider.dart';

Future<void> showChangePasswordDialog(BuildContext context,
    {bool isForceChange = false, VoidCallback? onSuccess}) {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangePasswordDialog(
            isForceChange: false,
            onSuccess: onSuccess,
          ));
}

class ChangePasswordDialog extends StatefulWidget {
  final bool isForceChange; // True nếu là luồng bắt buộc đổi mật khẩu lần đầu
  final VoidCallback? onSuccess;
  const ChangePasswordDialog({
    super.key,
    this.isForceChange = false,
    this.onSuccess,
  });
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Xóa lỗi cũ từ server
    setState(() {
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context); // Đóng dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        // Mặc định chuyển về màn hình đăng nhập
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } else {
      final code = authProvider.errorCode;
      final msg = authProvider.errorMessage ?? 'Đổi mật khẩu thất bại';
      setState(() {
        if (code == 'PASSWORD_NOT_CORRECT') {
          _oldPasswordError = msg;
        } else if (code == 'PASSWORD_SAME_AS_OLD') {
          _newPasswordError = msg;
        } else if (code == 'PASSWORD_WEAK' || code == 'PASSWORD_TOO_LONG') {
          _newPasswordError = msg;
        } else if (code == 'PASSWORD_CONFIRM_NOT_MATCH') {
          _confirmPasswordError = msg;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_reset, color: Colors.blue),
          const SizedBox(width: 8),
          Text(widget.isForceChange ? 'Bắt Buộc Đổi Mật Khẩu' : 'Đổi Mật Khẩu'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isForceChange) ...[
                const Text(
                  'Đây là lần đăng nhập đầu tiên, vui lòng đổi mật khẩu để bảo vệ tài khoản.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                onChanged: (_) {
                  if (_oldPasswordError != null)
                    setState(() => _oldPasswordError = null);
                },
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _oldPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: (val) => Validators.validateRequired(val,
                    fieldName: 'mật khẩu hiện tại'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onChanged: (_) {
                  if (_newPasswordError != null)
                    setState(() => _newPasswordError = null);
                },
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  errorText: _newPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) => Validators.validatePassword(
                  val,
                  oldPassword: _oldPasswordController.text,
                  emptyMessage: 'Vui lòng nhập mật khẩu mới',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onChanged: (_) {
                  if (_confirmPasswordError != null)
                    setState(() => _confirmPasswordError = null);
                },
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  errorText: _confirmPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) => Validators.validateConfirmPassword(
                  val,
                  _newPasswordController.text,
                  emptyMessage: 'Vui lòng xác nhận mật khẩu mới',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!widget.isForceChange)
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cập nhật'),
        ),
      ],
    );
  }
}
