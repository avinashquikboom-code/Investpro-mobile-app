import 'dart:async';
import 'package:get/get.dart';
import '../services/api_service.dart';

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
  final nextHourlyPayout = Rxn<Map<String, dynamic>>();
  final hourlyPayoutError = false.obs;
  final hourlyPayoutLoading = false.obs;
  bool get isLive => _repo.isLive;
  Worker? _payoutUserWorker, _payoutSyncWorker;
  Timer? _payoutTimer;
  int _payoutRequest = 0;
  Future<void>? _payoutInFlight;

  @override
  void onInit() {
    super.onInit();
    _payoutUserWorker = ever(_repo.currentUser, (_) {
      _payoutRequest++;
      _payoutInFlight = null;
      nextHourlyPayout.value = null;
      hourlyPayoutError.value = false;
      hourlyPayoutLoading.value = false;
      unawaited(loadNextHourlyPayout());
    });
    _payoutSyncWorker = ever(_repo.isSyncing, (syncing) {
      if (!syncing) unawaited(loadNextHourlyPayout());
    });
    if (isLive) {
      unawaited(loadNextHourlyPayout());
      _payoutTimer = Timer.periodic(const Duration(minutes: 1), (_) => loadNextHourlyPayout());
    }
  }

  Future<void> loadNextHourlyPayout() {
    if (!isLive || _repo.currentUser.value.id.isEmpty || !Get.isRegistered<ApiService>()) return Future.value();
    return _payoutInFlight ??= _loadNextHourlyPayout();
  }

  Future<void> _loadNextHourlyPayout() async {
    final request = ++_payoutRequest;
    hourlyPayoutLoading.value = true;
    try {
      final snapshot = await Get.find<ApiService>().getHourlyReturnsWorkspace(DateTime.now());
      if (isClosed || request != _payoutRequest) return;
      final upcoming = (snapshot['upcoming'] as List? ?? []).whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) => (DateTime.tryParse('${row['dueDate']}')?.isAfter(DateTime.now()) ?? false) && row['status'] == 'SCHEDULED')
          .toList()
        ..sort((a,b) => DateTime.parse('${a['dueDate']}').compareTo(DateTime.parse('${b['dueDate']}')));
      nextHourlyPayout.value = upcoming.isEmpty ? null : upcoming.first;
      hourlyPayoutError.value = false;
    } catch (_) {
      if (!isClosed && request == _payoutRequest) {
        nextHourlyPayout.value = null;
        hourlyPayoutError.value = true;
      }
    } finally {
      if (request == _payoutRequest) {
        _payoutInFlight = null;
        hourlyPayoutLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    _payoutRequest++;
    _payoutTimer?.cancel();
    _payoutUserWorker?.dispose();
    _payoutSyncWorker?.dispose();
    super.onClose();
  }

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
      await loadNextHourlyPayout();
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
