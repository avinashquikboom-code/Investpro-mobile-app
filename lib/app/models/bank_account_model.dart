class BankAccountModel {
  final String id;
  final String accountHolderName;
  final String accountNumber;
  final String bankName;
  final String ifscCode;
  final String accountType;
  final bool isPrimary;
  final bool isVerified;
  final String? branchName;

  const BankAccountModel({
    required this.id,
    required this.accountHolderName,
    required this.accountNumber,
    required this.bankName,
    required this.ifscCode,
    this.accountType = 'SAVINGS',
    this.isPrimary = false,
    this.isVerified = false,
    this.branchName,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? 'SAVINGS',
      isPrimary: json['isPrimary'] == true,
      isVerified: json['isVerified'] == true,
      branchName: json['branchName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountHolderName': accountHolderName,
    'accountNumber': accountNumber,
    'bankName': bankName,
    'ifscCode': ifscCode,
    'accountType': accountType,
    'isPrimary': isPrimary,
    'isVerified': isVerified,
    'branchName': branchName,
  };

  String get maskedAccountNumber {
    final clean = accountNumber.trim();
    if (clean.length < 4) return clean;
    final lastFour = clean.substring(clean.length - 4);
    return '•••• •••• $lastFour';
  }

  String get initials {
    final words = bankName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'BK';
  }
}

