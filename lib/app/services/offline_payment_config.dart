/// Strict payment configuration parsing. Missing/invalid flags never enable payments.
class OfflinePaymentConfig {
  static Map<String, dynamic> parse(Map<String, dynamic> input) {
    final raw = input.containsKey('enabled')
        ? input['enabled']
        : input['offlinePaymentEnabled'];
    final bool enabled;
    if (raw == true || raw == 'true') {
      enabled = true;
    } else if (raw == false || raw == 'false') {
      enabled = false;
    } else {
      throw const FormatException(
        'Payment settings did not include a valid offline availability flag. Please refresh.',
      );
    }
    final bank = [
      'accountHolderName',
      'bankName',
      'accountNumber',
      'ifscCode',
    ].every((key) => '${input[key] ?? ''}'.trim().isNotEmpty);
    final upi = '${input['upiId'] ?? ''}'.trim().isNotEmpty;
    final declared = input['acceptedMethods'];
    final methods = [
      if (bank && (declared is! List || declared.contains('BANK_TRANSFER')))
        'BANK_TRANSFER',
      if (upi && (declared is! List || declared.contains('UPI'))) 'UPI',
    ];
    final max = input['maxBytes'];
    return {
      ...input,
      'enabled': enabled,
      'configured': methods.isNotEmpty && input['configured'] != false,
      'acceptedMethods': methods,
      'proofRequired': true,
      'maxBytes': max is num && max > 0
          ? max.toInt().clamp(1, 5 * 1024 * 1024)
          : 5 * 1024 * 1024,
    };
  }

  static String normalizedReference(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'[-/]'), '');
  static bool validReference(String value) =>
      value.trim().length <= 64 &&
      RegExp(r'^[A-Z0-9]{6,64}$').hasMatch(normalizedReference(value)) &&
      RegExp(r'^[A-Za-z0-9/-]+$').hasMatch(value.trim());
}
