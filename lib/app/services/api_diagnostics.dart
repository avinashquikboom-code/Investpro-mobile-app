import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ApiDiagnostics {
  static DateTime retryAt(String? value, DateTime now) {
    final seconds = int.tryParse(value ?? '');
    if (seconds != null) {
      return now.add(Duration(seconds: seconds < 1 ? 1 : seconds));
    }
    DateTime? date = DateTime.tryParse(value ?? '');
    if (date == null && value != null) {
      try {
        date = DateFormat(
          'EEE, dd MMM yyyy HH:mm:ss',
          'en_US',
        ).parseUtc(value.replaceFirst(RegExp(r' GMT$'), ''));
      } catch (_) {}
    }
    return date != null && date.isAfter(now)
        ? date
        : now.add(const Duration(seconds: 60));
  }

  static void log(Object error, {String? path}) {
    if (!kDebugMode) return;
    final failure = error is DioException ? error : null;
    final data = failure?.response?.data;
    final raw = data is Map && data['message'] is String
        ? data['message'] as String
        : error is FormatException
        ? 'Invalid response format'
        : 'Request unavailable';
    final message = raw
        .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), '[redacted]')
        .replaceAll(RegExp(r'[A-Za-z0-9_-]{30,}'), '[redacted]')
        .replaceAll(RegExp(r'[^\s@]+@[^\s@]+'), '[redacted]')
        .replaceAll(RegExp(r'\d{10,}'), '[redacted]');
    final endpoint =
        (failure?.requestOptions.path ?? path ?? 'account snapshot')
            .split('?')
            .first
            .replaceAll(RegExp(r'[a-fA-F0-9-]{36}'), '[id]');
    debugPrint(
      'API synchronization method=${failure?.requestOptions.method ?? 'GET'} endpoint=$endpoint status=${failure?.response?.statusCode ?? failure?.type.name ?? 'invalid response'} message=${message.substring(0, message.length.clamp(0, 200))}',
    );
  }
}
