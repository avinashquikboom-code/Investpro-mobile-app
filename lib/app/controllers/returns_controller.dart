import 'package:get/get.dart';
import '../models/return_model.dart';
import '../services/demo_repository.dart';

class ReturnsController extends GetxController {
  final DemoRepository _repo;

  ReturnsController(this._repo);

  final RxString selectedPeriod = 'Monthly'.obs; // 'Monthly', 'Quarterly', 'Yearly'

  double get totalReturns => _repo.totalReturns;
  double get totalInvested => _repo.totalInvested;

  String get growthPercentage {
    if (totalInvested <= 0) return '+0%';
    final pct = (totalReturns / totalInvested) * 100;
    return '+${pct.toStringAsFixed(0)}%';
  }

  List<ReturnPayoutModel> get filteredReturns {
    return _repo.returns.where((r) => r.periodType == selectedPeriod.value).toList();
  }

  String get nextReturnDate {
    final pending = _repo.returns.where((r) => r.status == 'Pending').toList();
    if (pending.isNotEmpty) {
      pending.sort((a, b) => a.payoutDate.compareTo(b.payoutDate));
      final next = pending.first.payoutDate;
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${next.day.toString().padLeft(2, '0')} ${months[next.month - 1]} ${next.year}';
    }
    return '05 Aug 2026';
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
  }
}
