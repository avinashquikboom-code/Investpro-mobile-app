import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/transaction_model.dart';
import '../services/demo_repository.dart';
import '../utils/validators.dart';

class WithdrawalController extends GetxController {
  final DemoRepository _repo;

  WithdrawalController(this._repo);

  final RxString selectedFilter = 'All'.obs; // 'All', 'Withdrawals', 'Deposits'
  final TextEditingController amountController = TextEditingController();
  final bankSelected = false.obs;
  String? _requestId;
  final RxBool isSubmitting = false.obs;

  double get availableBalance => _repo.availableBalance.value;

  List<TransactionModel> get filteredTransactions {
    final txns = _repo.isLive ? [
      ..._repo.withdrawals.map((request) => TransactionModel(id: request.id, type: TransactionType.withdrawal, title: 'Withdrawal request', subtitle: '${request.bankName} ${request.accountNumber}', amount: request.amount, date: request.requestDate, status: request.status, direction: 'DEBIT', referenceId: request.referenceId)),
      ..._repo.transactions.where((record) => record.type == TransactionType.deposit),
    ] : _repo.transactions;
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

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  Future<bool> submitWithdrawal() async {
    if (isSubmitting.value) return false;
    if (!bankSelected.value) {
      Get.snackbar('Bank account required', 'Select your saved bank account.');
      return false;
    }
    final error = Validators.validateWithdrawalAmount(
      amountController.text,
      availableBalance,
    );
    if (error != null) {
      Get.snackbar(
        'Invalid Amount',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final amount =
        double.tryParse(
          amountController.text.replaceAll('₹', '').replaceAll(',', '').trim(),
        ) ??
        0.0;

    isSubmitting.value = true;
    try {
      _requestId ??= _repo.newReference('withdrawal');

      final success = await _repo.requestWithdrawal(
        amount: amount,
        bankSelected: bankSelected.value,
        requestId: _requestId,
      );
      if (success) {
        amountController.clear();
        _requestId = null;
        Get.back(); // Close dialog/bottom sheet
        Get.snackbar(
          'Request Submitted',
          'Your withdrawal request of ₹ ${amount.toInt()} has been initiated.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE8F8F0),
          colorText: const Color(0xFF006B3C),
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Unable to process withdrawal request.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar('Request failed', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }
}
