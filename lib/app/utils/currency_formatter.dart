import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 0,
  );

  static final NumberFormat _indianFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  /// Formats amount in standard Indian Currency notation (e.g. ₹ 50,000, ₹ 1,00,000)
  static String format(num amount, {bool showDecimals = false}) {
    if (showDecimals && (amount % 1 != 0)) {
      return _indianFormatWithDecimals.format(amount);
    }
    return _indianFormat.format(amount.round());
  }

  /// Compact Indian notation: ₹ 10K, ₹ 25K, ₹ 50K, ₹ 1L, ₹ 1.5Cr
  static String formatCompact(num amount) {
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      return '₹ ${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 1)}Cr';
    } else if (amount >= 100000) {
      final lakh = amount / 100000;
      return '₹ ${lakh.toStringAsFixed(lakh.truncateToDouble() == lakh ? 0 : 1)}L';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '₹ ${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 0)}K';
    }
    return format(amount);
  }

  /// Parses string to double removing ₹ and commas
  static double parse(String input) {
    final cleaned = input.replaceAll('₹', '').replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
