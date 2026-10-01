/// Phone number validators for India
class PhoneValidator {
  PhoneValidator._();

  static final _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  /// Validates Indian mobile number (10 digits, starts 6–9)
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'\s+'), '');
    if (clean.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    if (!_phoneRegex.hasMatch(clean)) {
      return 'Phone must start with 6, 7, 8, or 9';
    }
    return null;
  }

  /// Clean a phone number (remove spaces, +91 prefix)
  static String clean(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('+91', '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }
    return cleaned;
  }

  /// Format for display: 93456 78901
  static String format(String phone) {
    final clean = PhoneValidator.clean(phone);
    if (clean.length == 10) {
      return '${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return phone;
  }
}

/// General form field validators
class Validators {
  Validators._();

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.trim().length < min) {
      return '${fieldName ?? 'This field'} must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.trim().length > max) {
      return '${fieldName ?? 'This field'} must be at most $max characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) return 'Enter a valid amount';
    if (amount <= 0) return 'Amount must be greater than 0';
    return null;
  }

  static String? discountPercent(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid percentage';
    if (val < 0 || val > 100) return 'Discount must be between 0 and 100';
    return null;
  }

  static String? name(String? value) {
    final req = required(value, 'Name');
    if (req != null) return req;
    return minLength(value, 2, 'Name');
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'OTP must contain only digits';
    return null;
  }
}
