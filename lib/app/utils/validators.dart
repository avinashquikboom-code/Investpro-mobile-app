import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? name(String? v) =>
      (v ?? '').trim().length < 2 ? 'Enter your full name' : null;
  static String? email(String? v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
      ? null
      : 'Enter a valid email';
  static String? phone(String? v) =>
      RegExp(r'^\+?[0-9]{10,13}$').hasMatch((v ?? '').trim())
      ? null
      : 'Enter a valid mobile number';
  static String? identity(String? v) => email(v) == null || phone(v) == null
      ? null
      : 'Enter a valid email or mobile number';
  static String? password(String? v) =>
      (v ?? '').length >= 8 &&
          RegExp(r'[A-Za-z]').hasMatch(v!) &&
          RegExp(r'[0-9]').hasMatch(v)
      ? null
      : 'Use 8+ characters with letters and numbers';
  static int? amount(String value) {
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) return null;
    final parts = value.trim().split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0);
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateMobile(String? value) =>
      phone(value?.replaceAll(RegExp(r'[\s-]'), ''));

  static String? validateEmailOrMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or mobile number is required';
    }
    final trimmed = value.trim();
    final isEmail = trimmed.contains('@');
    if (isEmail) {
      return validateEmail(trimmed);
    } else {
      return validateMobile(trimmed);
    }
  }

  static String? validatePassword(String? value) => password(value);

  static String? validateInvestmentAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an investment amount';
    }
    final minor = Validators.amount(
      value.replaceAll('₹', '').replaceAll(',', '').trim(),
    );
    final amount = minor == null ? null : minor / 100;
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }
    if (amount < AppConstants.minInvestmentAmount) {
      return 'Minimum investment is ₹ ${AppConstants.minInvestmentAmount.toInt()}';
    }
    if (amount > AppConstants.maxInvestmentAmount) {
      return 'Maximum investment is ₹ ${AppConstants.maxInvestmentAmount.toInt()}';
    }
    return null;
  }

  static String? validateWithdrawalAmount(
    String? value,
    double availableBalance, {
    double? minAmount,
    double? maxAmount,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a withdrawal amount';
    }
    final minor = Validators.amount(
      value.replaceAll('₹', '').replaceAll(',', '').trim(),
    );
    final amount = minor == null ? null : minor / 100;
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }
    final minLimit = minAmount ?? AppConstants.minWithdrawalAmount;
    if (amount < minLimit) {
      return 'Minimum withdrawal is ₹ ${minLimit.toStringAsFixed(minLimit.truncateToDouble() == minLimit ? 0 : 2)}';
    }
    if (maxAmount != null && maxAmount > 0 && amount > maxAmount) {
      return 'Maximum withdrawal is ₹ ${maxAmount.toStringAsFixed(maxAmount.truncateToDouble() == maxAmount ? 0 : 2)}';
    }
    if (amount > availableBalance) {
      return 'Amount exceeds available balance';
    }
    return null;
  }
}
