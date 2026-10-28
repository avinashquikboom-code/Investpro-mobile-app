import 'package:get/get.dart';

import '../models/transaction_model.dart';
import '../services/demo_repository.dart';

class TransactionController extends GetxController {
  final DemoRepository _repo;

  TransactionController(this._repo);

  final RxString selectedFilter =
      'All'.obs; // 'All', 'Investment', 'Return', 'Withdrawal'
  final Rxn<TransactionModel> selectedTransaction = Rxn<TransactionModel>();

  List<TransactionModel> get filteredTransactions {
    final list = _repo.transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    switch (selectedFilter.value) {
      case 'Investment':
        return list.where((t) => t.type == TransactionType.investment).toList();
      case 'Return':
        return list
            .where((t) => t.type == TransactionType.returnReceived)
            .toList();
      case 'Withdrawal':
        return list.where((t) => t.type == TransactionType.withdrawal).toList();
      default:
        return list;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void selectTransaction(TransactionModel txn) {
    selectedTransaction.value = txn;
  }
}
