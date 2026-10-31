import '../utils/display_value.dart';

import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/investment_model.dart';
import '../models/return_model.dart';
import '../models/withdrawal_model.dart';
import '../models/transaction_model.dart';

/// Maps persisted backend states without inferring payment/approval success.
class BackendSnapshot {
  static double number(dynamic value) =>
      num.tryParse('$value')?.toDouble() ?? 0;
  static DateTime date(dynamic value) =>
      DateTime.tryParse('$value')?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
  static String label(dynamic value) {
    final text = '${value ?? ''}'.replaceAll('_', ' ').toLowerCase();
    return text.isEmpty ? '' : '${text[0].toUpperCase()}${text.substring(1)}';
  }

  static Map<String, dynamic>? primaryBank(Map<String, dynamic> profile) {
    final banks = (profile['bankAccounts'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return banks.where((b) => b['isPrimary'] == true).firstOrNull ??
        banks.firstOrNull;
  }

  static UserModel user(Map<String, dynamic> profile) {
    final bank = primaryBank(profile);
    final account = '${bank?['accountNumber'] ?? ''}';
    final owner = profile['user'] as Map? ?? {};
    return UserModel(
      recordIds: DisplayValue.ids(profile),
      id: '${profile['id'] ?? ''}',
      fullName: '${profile['fullName'] ?? ''}',
      email: '${owner['email'] ?? profile['email'] ?? ''}',
      mobileNumber: '${owner['mobileNumber'] ?? profile['mobileNumber'] ?? ''}',
      role: 'Investor',
      accountStatus: '${owner['status'] ?? ''}',
      kycStatus: '${profile['kycStatus'] ?? ''}',
      bankAccountId: bank?['id'] as String?,
      bankName: '${bank?['bankName'] ?? ''}',
      accountNumber: account.length >= 4
          ? '•••• ${account.substring(account.length - 4)}'
          : '',
      ifscCode: '${bank?['ifscCode'] ?? ''}',
      isBankVerified: profile['isBankVerified'] == true,
    );
  }

  static InvestmentModel investment(Map<String, dynamic> row) {
    final project = row['project'] as Map? ?? {};
    final status = '${row['status']}';
    final verified = row['paymentVerified'] == true;
    final ref = DisplayValue.reference(
      row['invoiceNumber'] ?? row['investmentReference'] ?? row['reference'],
      internalId: row['id'],
    );
    final projectName =
        '${project['title'] ?? row['projectName'] ?? ''}';
    return InvestmentModel(
      recordIds: DisplayValue.ids(row),
      id: row['id'] as String? ?? '',
      reference: ref,
      projectId: '${row['projectId'] ?? project['id'] ?? ''}',
      projectName: DisplayValue.text(projectName),
      iconType: 'folder',
      investedAmount: number(row['amount']),
      returnRatePercent: number(row['agreedRoi']),
      durationMonths: (row['tenureMonths'] as num?)?.toInt() ?? 0,
      expectedReturn: number(row['totalExpectedReturns']),
      maturityAmount:
          number(row['amount']) + number(row['totalExpectedReturns']),
      startDate: date(row['startDate']),
      maturityDate: date(row['maturityDate']),
      progressPercent: 0,
      status: (status == 'ACTIVE' || status == 'MATURED') && !verified
          ? 'Payment unverified'
          : status == 'MATURED'
          ? 'Completed'
          : label(status),
      paymentMethod:
          (row['payments'] as List?)?.firstOrNull?['paymentMethod']
              ?.toString() ??
          '',
    );
  }

  static WithdrawalModel withdrawal(Map<String, dynamic> row) {
    final bank = row['bankAccount'] as Map? ?? {};
    final account = '${bank['accountNumber'] ?? ''}';
    final ref = DisplayValue.reference(
      row['withdrawalReference'] ?? row['reference'],
      internalId: row['id'],
    );
    return WithdrawalModel(
      recordIds: DisplayValue.ids(row),
      id: row['id'] as String? ?? '',
      amount: number(row['amount']),
      bankName: '${bank['bankName'] ?? ''}',
      accountNumber: account.length >= 4
          ? '•••• ${account.substring(account.length - 4)}'
          : '',
      requestDate: date(row['requestedAt']),
      status: label(row['status']),
      referenceId: ref.isNotEmpty ? ref : 'N/A',
    );
  }

  static ReturnPayoutModel payout(Map<String, dynamic> row) {
    final due = date(
      row['status'] == 'PAID'
          ? (row['returnPayment']?['payoutDate'] ??
                row['paidAt'] ??
                row['dueDate'])
          : row['dueDate'],
    );
    return ReturnPayoutModel(
      id: row['id'] as String? ?? '',
      investmentId: row['investmentId'] as String? ?? '',
      projectName:
          '${row['investment']?['project']?['title'] ?? row['projectTitle'] ?? ''}',
      monthYear: DateFormat.yMMM().format(due),
      payoutDate: due,
      amount: number(row['profitAmount']),
      status: row['status'] == 'PAID' ? 'Received' : label(row['status']),
    );
  }

  static TransactionModel transaction(Map<String, dynamic> row) {
    final type = '${row['type']}';
    final kind = type == 'REFUND'
        ? TransactionType.refund
        : type == 'FEE'
        ? TransactionType.fee
        : type.contains('RETURN')
        ? TransactionType.returnReceived
        : type.contains('WITHDRAWAL')
        ? TransactionType.withdrawal
        : type.contains('DEPOSIT')
        ? TransactionType.deposit
        : TransactionType.investment;
    final pName =
        row['investment']?['project']?['title'] as String? ??
        row['projectName'] as String?;
    final txRef = DisplayValue.reference(
      row['transactionNumber'] ??
          row['transactionReference'] ??
          row['reference'],
      internalId: row['id'],
    );
    return TransactionModel(
      recordIds: DisplayValue.ids(row),
      id: row['id'] as String? ?? '',
      type: kind,
      title: label(type),
      subtitle: DisplayValue.text(pName ?? row['description']),
      amount: number(row['amount']),
      date: date(row['createdAt']),
      status: label(row['status']),
      direction: '${row['direction'] ?? ''}',
      projectId:
          row['investment']?['projectId'] as String? ??
          row['projectId'] as String?,
      projectName: DisplayValue.text(pName),
      referenceId: txRef.isNotEmpty ? txRef : 'N/A',
    );
  }
}
