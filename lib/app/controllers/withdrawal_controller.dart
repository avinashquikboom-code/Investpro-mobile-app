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
  final RxBool isSubmitting = false.obs;

  double get availableBalance => _repo.availableBalance.value;

  List<TransactionModel> get filteredTransactions {
    final txns = _repo.transactions;
    switch (selectedFilter.value) {
      case 'Withdrawals':
        return txns.where((t) => t.type == TransactionType.withdrawal).toList();
      case 'Deposits':
        return txns.where((t) => t.type == TransactionType.deposit).toList();
      default:
        return txns.where((t) => t.type == TransactionType.withdrawal || t.type == TransactionType.deposit).toList();
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  Future<bool> submitWithdrawal() async {
    if(isSubmitting.value) return false;
    if(!bankSelected.value) { Get.snackbar('Demo bank required','Select the demo bank account.'); return false; }
    final error = Validators.validateWithdrawalAmount(amountController.text, availableBalance);
    if (error != null) {
      Get.snackbar('Invalid Amount', error, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final amount = double.tryParse(
          amountController.text.replaceAll('₹', '').replaceAll(',', '').trim(),
        ) ??
        0.0;

    isSubmitting.value = true;
    try {
    await Future.delayed(const Duration(milliseconds: 900));


    final success = await _repo.requestWithdrawal(amount: amount, bankSelected: bankSelected.value);
    if (success) {
      amountController.clear();
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
      Get.snackbar('Error', 'Unable to process withdrawal request.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    } catch(e) { Get.snackbar('Request failed',e.toString()); return false; }
    finally { isSubmitting.value = false; }
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }
}
