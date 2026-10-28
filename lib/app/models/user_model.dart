class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String role;
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
    this.avatarUrl,
    this.bankName = 'HDFC Bank',
    this.accountNumber = '•••• 4829',
    this.ifscCode = 'HDFC0001234',
    this.isBankVerified = true,
  });

  String get name => fullName;
  String get phone => mobileNumber;
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? mobileNumber,
    String? role,
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
      'avatarUrl': avatarUrl,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'isBankVerified': isBankVerified,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? 'INV001',
      fullName: json['fullName'] as String? ?? 'Rohit Sharma',
      email: json['email'] as String? ?? 'rohit.sharma@example.com',
      mobileNumber: json['mobileNumber'] as String? ?? '+91 98765 43210',
      role: json['role'] as String? ?? 'Investor',
      avatarUrl: json['avatarUrl'] as String?,
      bankName: json['bankName'] as String? ?? 'HDFC Bank',
      accountNumber: json['accountNumber'] as String? ?? '•••• 4829',
      ifscCode: json['ifscCode'] as String? ?? 'HDFC0001234',
      isBankVerified: json['isBankVerified'] as bool? ?? true,
    );
  }
}
