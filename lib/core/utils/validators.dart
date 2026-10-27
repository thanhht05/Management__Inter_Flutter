class Validators {
  Validators._();

  /// Validate độ mạnh mật khẩu:
  /// - Không để trống
  /// - Độ dài từ [minLength] (mặc định 6) đến [maxLength] (mặc định 72)
  /// - Chứa ít nhất: 1 chữ hoa, 1 chữ thường, 1 chữ số
  /// - Tùy chọn: [oldPassword] để kiểm tra không được trùng mật khẩu cũ
  static String? validatePassword(
    String? value, {
    String? oldPassword,
    int minLength = 6,
    int maxLength = 72,
    String emptyMessage = 'Vui lòng nhập mật khẩu',
  }) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }

    if (oldPassword != null && value == oldPassword) {
      return 'Mật khẩu mới không được trùng với mật khẩu cũ';
    }

    if (value.length < minLength || value.length > maxLength) {
      return 'Mật khẩu phải có độ dài từ $minLength đến $maxLength ký tự';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ hoa';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ thường';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số';
    }

    return null;
  }

  /// Validate xác nhận lại mật khẩu
  static String? validateConfirmPassword(
    String? value,
    String originalPassword, {
    String emptyMessage = 'Vui lòng xác nhận mật khẩu',
    String mismatchMessage = 'Mật khẩu xác nhận không trùng khớp',
  }) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }
    if (value != originalPassword) {
      return mismatchMessage;
    }
    return null;
  }

  /// Validate bắt buộc nhập thông thường
  static String? validateRequired(
    String? value, {
    String fieldName = 'thông tin này',
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }
}
