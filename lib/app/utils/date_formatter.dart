import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dayMonthYear = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy · hh:mm a');
  static final DateFormat _timeOnly = DateFormat('hh:mm a');

  static String formatDate(DateTime dateTime) {
    return _dayMonthYear.format(dateTime);
  }

  static String formatMonthYear(DateTime dateTime) {
    return _monthYear.format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTime.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return _timeOnly.format(dateTime);
  }
}

String dateLabel(DateTime date) => DateFormatter.formatDate(date);
