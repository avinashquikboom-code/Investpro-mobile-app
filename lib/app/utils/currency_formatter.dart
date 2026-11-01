import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _indianFormat = NumberFormat.currency(
    locale: 'en_IN', symbol: '₹', decimalDigits: 2,
  );

  /// Parses API numbers/decimal strings without rounding the calculation value.
  static double number(Object? value) {
    final parsed = value is num ? value : num.tryParse('${value ?? ''}');
    return parsed != null && parsed.isFinite ? parsed.toDouble() : 0;
  }

  /// Presentation only: Indian grouping and exactly two decimal places.
  /// [showDecimals] remains source-compatible; decimals are now always shown.
  static String format(Object? amount, {bool showDecimals = true}) =>
      _indianFormat.format(number(amount));

  /// Compatibility entry point; all rupee displays now use two decimal places.
  static String formatPrecise(Object? amount, {int decimalDigits = 2}) =>
      format(amount);

  /// Full values prevent K/L/Cr abbreviations from hiding financial precision.
  static String formatCompact(Object? amount) => format(amount);

  /// Formats the existing exact paise representation without a double conversion.
  static String formatPaise(int paise) {
    final value = paise.abs();
    final whole = '${value ~/ 100}';
    final groups = <String>[];
    var end = whole.length;
    while (end > 0) {
      final width = groups.isEmpty ? 3 : 2;
      final start = end > width ? end - width : 0;
      groups.insert(0, whole.substring(start, end));
      end = start;
    }
    return '${paise < 0 ? '-' : ''}₹${groups.join(',')}.${(value % 100).toString().padLeft(2, '0')}';
  }

  /// Parses editable currency text without rounding or truncating its value.
  static double parse(String input) => number(input
      .replaceAll('₹', '').replaceAll(',', '').replaceAll(' ', '').trim());
}
