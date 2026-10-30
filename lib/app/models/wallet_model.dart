/// Financial values arrive as decimal strings and are held in integer paise.
int moneyPaise(dynamic value) {
  final text = '$value';
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
    throw const FormatException('Invalid money value');
  }
  final parts = text.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
}

String maskedBank(dynamic value) {
  final text = '${value ?? ''}'.trim();
  return text.length >= 4 ? '•••• ${text.substring(text.length - 4)}' : '';
}

class WalletBank {
  final String id, name, maskedAccount;
  final bool verified, primary;
  WalletBank.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['bankName'] as String? ?? '',
      maskedAccount = maskedBank(json['accountNumber']),
      verified = json['isVerified'] == true,
      primary = json['isPrimary'] == true;
}

class WalletSnapshot {
  final int available, reserved, minimum, fee;
  final int? maximum;
  final String accountStatus;
  final List<WalletBank> banks;
  WalletSnapshot.fromJson(Map<String, dynamic> json)
    : available = moneyPaise(json['availableBalance']),
      reserved = moneyPaise(json['reservedBalance']),
      minimum = moneyPaise(json['minimumWithdrawal']),
      maximum = json['maximumWithdrawal'] == null
          ? null
          : moneyPaise(json['maximumWithdrawal']),
      fee = moneyPaise(json['withdrawalFee']),
      accountStatus = json['accountStatus'] as String? ?? '',
      banks = (json['banks'] as List)
          .map((v) => WalletBank.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList() {
    if (json['currency'] != 'INR') {
      throw const FormatException('Unsupported wallet currency');
    }
  }
}

class WalletTransaction {
  final String id, type, status, direction, reference, description;
  final String? projectName, investmentReference;
  final int amount;
  final DateTime created, updated;
  final Map<String, dynamic>? withdrawal;
  WalletTransaction.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      status = json['status'] as String,
      direction = json['direction'] as String,
      reference = json['transactionReference'] as String,
      description = json['description'] as String? ?? '',
      amount = moneyPaise(json['amount']),
      created = DateTime.parse(json['createdAt'] as String).toLocal(),
      updated = DateTime.parse(json['updatedAt'] as String).toLocal(),
      projectName = json['projectName'] as String?,
      investmentReference = json['investmentReference'] as String?,
      withdrawal = json['withdrawal'] == null
          ? null
          : Map<String, dynamic>.from(json['withdrawal'] as Map);

  String get label => switch (type) {
    'WITHDRAWAL_REQUEST' => 'Withdrawal',
    'WALLET_DEPOSIT' => 'Deposit',
    'RETURN_PAYOUT' => 'Return credit',
    'REFUND' => 'Refund',
    'FEE' => 'Fee',
    _ => type.replaceAll('_', ' ').toLowerCase(),
  };
}
