import 'package:get/get.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/demo_repository.dart';
import '../services/notification_service.dart';

class HomeController extends GetxController {
  final DemoRepository _repo;
  final NotificationService _notificationService;

  HomeController(this._repo, this._notificationService);

  final RxBool isRefreshing = false.obs;

  UserModel get user => _repo.currentUser.value;
  double get totalPortfolioValue => _repo.totalPortfolioValue;
  double get totalInvested => _repo.totalInvested;
  double get growthPercent => _repo.growthPercent;
  double get totalReturns => _repo.totalReturns;
  int get totalActiveProjects => _repo.totalActiveProjects;
  int get unreadNotificationCount => _notificationService.unreadCount;

  List<ProjectModel> get featuredProjects => _repo.projects;

  Future<void> refreshDashboard() async {
    isRefreshing.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    await _repo.loadData();
    _notificationService.loadNotifications();
    isRefreshing.value = false;
  }
}
