import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/demo_repository.dart';
import '../utils/validators.dart';

class WithdrawalController extends GetxController {
  final DemoRepository _repo;

  WithdrawalController(this._repo);

  final RxString selectedFilter = 'All'.obs; // 'All', 'Withdrawals', 'Deposits'
  final TextEditingController amountController = TextEditingController();
  final RxBool bankSelected = true.obs;
  final RxString selectedBankId = ''.obs;
  String? _requestId;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingWallet = false.obs;

  // Authoritative limits & balance from backend
  final RxDouble backendAvailableBalance = 0.0.obs;
  final RxDouble backendReservedBalance = 0.0.obs;
  final RxDouble minimumWithdrawal = 100.0.obs;
  final Rx<double?> maximumWithdrawal = Rx<double?>(null);
  final RxDouble withdrawalFee = 0.0.obs;
  final RxList<Map<String, dynamic>> verifiedBanks = <Map<String, dynamic>>[].obs;
  final RxDouble netPayoutAmount = 0.0.obs;
  final RxString lastSubmittedReference = ''.obs;

  double get availableBalance =>
      _repo.isLive ? backendAvailableBalance.value : _repo.availableBalance.value;

  double get reservedBalance =>
      _repo.isLive ? backendReservedBalance.value : 0.0;

  bool get hasBankAccount =>
      verifiedBanks.isNotEmpty || _repo.currentUser.value.bankAccountId != null;

  bool get hasVerifiedBank =>
      verifiedBanks.any((b) => b['isVerified'] == true) ||
      (_repo.currentUser.value.bankAccountId != null &&
          _repo.currentUser.value.bankName.isNotEmpty);

  Map<String, dynamic>? get selectedBank {
    if (verifiedBanks.isEmpty) return null;
    if (selectedBankId.value.isNotEmpty) {
      final found = verifiedBanks.firstWhereOrNull((b) => b['id'] == selectedBankId.value);
      if (found != null) return found;
    }
    return verifiedBanks.firstWhereOrNull((b) => b['isPrimary'] == true && b['isVerified'] == true) ??
        verifiedBanks.firstWhereOrNull((b) => b['isVerified'] == true) ??
        verifiedBanks.first;
  }

  String get linkedBankName {
    final b = selectedBank;
    if (b != null && b['bankName'] != null && b['bankName'].toString().isNotEmpty) {
      return b['bankName'].toString();
    }
    return _repo.currentUser.value.bankName;
  }

  String get linkedAccountNumber {
    final b = selectedBank;
    if (b != null && b['accountNumber'] != null && b['accountNumber'].toString().isNotEmpty) {
      return b['accountNumber'].toString();
    }
    return _repo.currentUser.value.accountNumber;
  }

  bool get isLive => _repo.isLive;

  List<TransactionModel> get filteredTransactions {
    final txns = _repo.isLive
        ? [
            ..._repo.withdrawals.map(
              (request) => TransactionModel(
                id: request.id,
                type: TransactionType.withdrawal,
                title: 'Withdrawal request',
                subtitle: '${request.bankName} ${request.accountNumber}',
                amount: request.amount,
                date: request.requestDate,
                status: request.status,
                direction: 'DEBIT',
                referenceId: request.referenceId,
              ),
            ),
            ..._repo.transactions.where((record) => record.type == TransactionType.deposit),
          ]
        : _repo.transactions;

    switch (selectedFilter.value) {
      case 'Withdrawals':
        return txns.where((t) => t.type == TransactionType.withdrawal).toList();
      case 'Deposits':
        return txns.where((t) => t.type == TransactionType.deposit).toList();
      default:
        return txns
            .where(
              (t) =>
                  t.type == TransactionType.withdrawal ||
                  t.type == TransactionType.deposit,
            )
            .toList();
    }
  }

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(_onAmountChanged);
    loadWalletData();
  }

  void _onAmountChanged() {
    final raw = amountController.text.replaceAll('₹', '').replaceAll(',', '').trim();
    final amt = double.tryParse(raw) ?? 0.0;
    final fee = withdrawalFee.value;
    if (amt <= 0) {
      netPayoutAmount.value = 0.0;
    } else {
      netPayoutAmount.value = (amt - fee).clamp(0.0, double.infinity);
    }
  }

  Future<void> loadWalletData() async {
    if (!_repo.isLive) {
      backendAvailableBalance.value = _repo.availableBalance.value;
      return;
    }
    try {
      isLoadingWallet.value = true;
      if (Get.isRegistered<ApiService>()) {
        final api = Get.find<ApiService>();
        final wallet = await api.getWallet();
        backendAvailableBalance.value =
            double.tryParse(wallet['availableBalance']?.toString() ?? '0') ?? 0.0;
        backendReservedBalance.value =
            double.tryParse(wallet['reservedBalance']?.toString() ?? '0') ?? 0.0;
        minimumWithdrawal.value =
            double.tryParse(wallet['minimumWithdrawal']?.toString() ?? '100') ?? 100.0;

        if (wallet['maximumWithdrawal'] != null && wallet['maximumWithdrawal'].toString().isNotEmpty) {
          maximumWithdrawal.value =
              double.tryParse(wallet['maximumWithdrawal']?.toString() ?? '');
        } else {
          maximumWithdrawal.value = null;
        }

        withdrawalFee.value =
            double.tryParse(wallet['withdrawalFee']?.toString() ?? '0') ?? 0.0;

        if (wallet['banks'] is List) {
          final list = (wallet['banks'] as List)
              .map((b) => Map<String, dynamic>.from(b as Map))
              .toList();
          verifiedBanks.assignAll(list);

          final primary = list.firstWhereOrNull(
                (b) => b['isPrimary'] == true && b['isVerified'] == true,
              ) ??
              list.firstWhereOrNull((b) => b['isVerified'] == true) ??
              list.firstOrNull;

          if (primary != null) {
            selectedBankId.value = primary['id']?.toString() ?? '';
            bankSelected.value = true;
          }
        }
      }
    } catch (_) {
      backendAvailableBalance.value = _repo.availableBalance.value;
    } finally {
      isLoadingWallet.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void selectBank(String bankId) {
    selectedBankId.value = bankId;
    bankSelected.value = true;
  }

  Future<bool> submitWithdrawal() async {
    if (isSubmitting.value) return false;

    if (availableBalance <= 0) {
      Get.snackbar(
        'Zero Balance',
        'Available balance is ₹ 0.00. Capital returns or wallet deposits must be credited before requesting a withdrawal.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!hasVerifiedBank) {
      Get.snackbar(
        'Verified Bank Account Required',
        'Please link and verify a bank account from your Profile before withdrawing funds.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final error = Validators.validateWithdrawalAmount(
      amountController.text,
      availableBalance,
      minAmount: minimumWithdrawal.value,
      maxAmount: maximumWithdrawal.value,
    );
    if (error != null) {
      Get.snackbar(
        'Invalid Amount',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final amount = double.tryParse(
          amountController.text.replaceAll('₹', '').replaceAll(',', '').trim(),
        ) ??
        0.0;

    isSubmitting.value = true;
    try {
      _requestId ??= _repo.newReference('withdrawal');
      final targetBankId = selectedBankId.value.isNotEmpty
          ? selectedBankId.value
          : (_repo.currentUser.value.bankAccountId ?? '');

      if (_repo.isLive && Get.isRegistered<ApiService>()) {
        final api = Get.find<ApiService>();
        final result = await api.createWithdrawal(
          amount: amount,
          bankAccountId: targetBankId.isNotEmpty ? targetBankId : null,
          idempotencyKey: _requestId,
        );

        if (result != null) {
          final ref = result['withdrawalReference']?.toString() ??
              result['id']?.toString() ??
              _requestId!;
          lastSubmittedReference.value = ref;

          amountController.clear();
          _requestId = null;

          // Await fresh authoritative data from server
          await Future.wait([
            loadWalletData(),
            _repo.syncFromBackend().catchError((_) {}),
          ]);

          Get.snackbar(
            'Withdrawal request submitted successfully',
            'Reference: $ref\nStatus: Pending Admin Approval',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F8F0),
            colorText: const Color(0xFF006B3C),
            duration: const Duration(seconds: 5),
          );
          return true;
        } else {
          throw Exception('The server did not accept this withdrawal request');
        }
      } else {
        // Fallback local commit
        final success = await _repo.requestWithdrawal(
          amount: amount,
          bankSelected: true,
          requestId: _requestId,
        );
        if (success) {
          amountController.clear();
          _requestId = null;
          Get.snackbar(
            'Withdrawal request submitted successfully',
            'Your request of ₹ ${amount.toInt()} has been initiated.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F8F0),
            colorText: const Color(0xFF006B3C),
          );
          return true;
        } else {
          throw Exception('Unable to process withdrawal request');
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
      Get.snackbar(
        'Request Failed',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    amountController.removeListener(_onAmountChanged);
    amountController.dispose();
    super.onClose();
  }
}
