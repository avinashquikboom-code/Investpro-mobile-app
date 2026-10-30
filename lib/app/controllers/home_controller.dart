import 'package:get/get.dart';

import '../models/investment_model.dart';
import '../models/project_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/demo_repository.dart';
import '../services/notification_service.dart';

class HomeController extends GetxController {
  final DemoRepository _repo;
  final NotificationService _notificationService;

  HomeController(this._repo, this._notificationService);

  final RxBool isRefreshing = false.obs;
  final RxBool isHideBalance = false.obs;

  void toggleBalanceVisibility() {
    isHideBalance.value = !isHideBalance.value;
  }

  UserModel get user => _repo.currentUser.value;
  Rx<UserModel> get liveUser => _repo.currentUser;
  RxBool get isSyncing => _repo.isSyncing;
  RxString get syncError => _repo.syncError;

  double get totalPortfolioValue => _repo.totalPortfolioValue;
  double get totalInvested => _repo.totalInvested;
  double get totalReturns => _repo.totalReturns;
  int get totalProjects => _repo.totalInvestedProjects;
  int get totalActiveProjects => _repo.totalActiveProjects;
  double? get growthPercent => _repo.growthPercent;
  int get unreadNotificationCount => _notificationService.unreadCount;

  List<ProjectModel> get featuredProjects => _repo.projects;

  List<InvestmentModel> get myInvestments => _repo.investments
      .where((i) => i.status == 'Active' || i.status == 'Completed')
      .toList();

  List<TransactionModel> get recentActivity => _repo.transactions.take(5).toList();

  Future<void> refreshDashboard() async {
    isRefreshing.value = true;
    try {
      await _repo.loadData();
      if (_repo.isLive) {
        await _notificationService.refreshFromBackend();
      } else {
        _notificationService.loadNotifications();
      }
    } catch (_) {
      // Retain existing state smoothly; syncError will display if necessary
    } finally {
      isRefreshing.value = false;
    }
  }
}
