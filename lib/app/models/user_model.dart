class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String role;
  final String accountStatus;
  final String kycStatus;
  final String? bankAccountId;
  final String? avatarUrl;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final bool isBankVerified;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    this.role = 'Investor',
    this.accountStatus = '',
    this.kycStatus = '',
    this.bankAccountId,
    this.avatarUrl,
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.isBankVerified = false,
  });

  String get name => fullName;
  String get phone => mobileNumber;
  bool get isKycVerified =>
      kycStatus.toUpperCase() == 'APPROVED' ||
      kycStatus.toUpperCase() == 'VERIFIED';
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? mobileNumber,
    String? role,
    String? accountStatus,
    String? kycStatus,
    String? bankAccountId,
    String? avatarUrl,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    bool? isBankVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      kycStatus: kycStatus ?? this.kycStatus,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      isBankVerified: isBankVerified ?? this.isBankVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'role': role,
      'accountStatus': accountStatus,
      'kycStatus': kycStatus,
      'bankAccountId': bankAccountId,
      'avatarUrl': avatarUrl,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'isBankVerified': isBankVerified,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'Investor',
      accountStatus: json['accountStatus'] as String? ?? '',
      kycStatus: json['kycStatus'] as String? ?? '',
      bankAccountId: json['bankAccountId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bankName: json['bankName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? '',
      isBankVerified: json['isBankVerified'] as bool? ?? false,
    );
  }
}
