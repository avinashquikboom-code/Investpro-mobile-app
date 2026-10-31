import 'dart:async';
import 'package:dio/dio.dart';

import '../routes/app_routes.dart';

import 'package:get/get.dart';

import '../models/project_model.dart';
import '../models/subscription_plan_model.dart';
import '../services/demo_repository.dart';
import '../services/api_service.dart';

class ProjectController extends GetxController {
  final DemoRepository _repo;
  final ApiService? _api;
  ProjectController(this._repo, [this._api]);
  final selectedFilter = 'All Projects'.obs;
  final selectedCategory = 'All Categories'.obs;
  final searchQuery = ''.obs;
  final selectedProject = Rxn<ProjectModel>();
  final categories = <Map<String, dynamic>>[].obs;
  final remoteProjects = <ProjectModel>[].obs;
  final isLoading = false.obs;
  final isDetailLoading = false.obs;
  final errorMessage = ''.obs;
  final detailError = ''.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final pageError = ''.obs;
  final subscriptionRequired = false.obs;
  final eligibility = Rxn<SubscriptionEligibilityModel>();
  final activePlan = Rxn<SubscriptionPlanModel>();
  final availablePlans = <SubscriptionPlanModel>[].obs;
  final isLoadingPlans = false.obs;
  final isPurchasingPlan = false.obs;
  final purchaseError = ''.obs;
  bool hasLoaded=false;
  bool hasAttempted=false;
  int _page = 0;
  int _request = 0;
  int _detailRequest=0;
  Timer? _searchTimer;

  void clearForSession(){
    _request++;_detailRequest++;_searchTimer?.cancel();
    remoteProjects.clear();categories.clear();selectedProject.value=null;
    selectedCategory.value='All Categories';searchQuery.value='';selectedFilter.value='All Projects';
    subscriptionRequired.value=false;eligibility.value=null;activePlan.value=null;
    availablePlans.clear();isLoadingPlans.value=false;isPurchasingPlan.value=false;purchaseError.value='';
    hasLoaded=false;hasAttempted=false;_page=0;hasMore.value=false;
    isLoading.value=false;isLoadingMore.value=false;errorMessage.value='';pageError.value='';detailError.value='';
  }

  List<String> get statusFilters => const [
    'All Projects',
    'Active',
    'Upcoming',
    'Completed',
  ];

  String? investmentUnavailableReason(
    ProjectModel project, {
    required bool authenticated,
  }) {
    if (!authenticated) return 'Sign in to invest';
    final user = _repo.currentUser.value;
    if (user.accountStatus != 'ACTIVE') {
      return 'An active investor account is required';
    }
    if (user.kycStatus != 'VERIFIED') {
      return 'Complete KYC verification to invest';
    }
    if (subscriptionRequired.value) {
      return 'Active subscription plan required to invest';
    }
    if (eligibility.value != null && !eligibility.value!.hasActiveSubscription) {
      return 'Active subscription plan required to invest';
    }
    if (eligibility.value != null && eligibility.value!.hasActiveSubscription) {
      if (project.minInvestment < eligibility.value!.minInvestment ||
          (eligibility.value!.maxInvestment > 0 &&
              project.minInvestment > eligibility.value!.maxInvestment)) {
        return 'Project requires a higher subscription plan';
      }
    }
    if (project.status.toUpperCase() != 'ACTIVE') {
      return 'This project is not open for investment';
    }
    if (!project.hasFundingData ||
        project.minInvestment <= 0 ||
        project.targetAmount - project.raisedAmount < project.minInvestment ||
        (project.maxInvestment != null &&
            project.maxInvestment! < project.minInvestment)) {
      return 'No eligible investment amount is currently available';
    }
    return null;
  }

  @override
  void onClose() {
    _searchTimer?.cancel();
    _request++;
    _detailRequest++;
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    if (_api != null) refreshProjects();
  }

  List<String> get availableCategories => [
    'All Categories',
    ...categories.map((c) => c['id'] as String),
  ];
  String categoryLabel(String id) {
    if (id == 'All Categories') {
      return id;
    }
    final category = categories.firstWhereOrNull((c) => c['id'] == id);
    return category == null
        ? ''
        : '${category['name']}${category['projectsCount'] is num ? ' (${category['projectsCount']})' : ''}';
  }

  List<ProjectModel> get filteredProjects =>
      (_api == null ? _repo.projects : remoteProjects).where((p) {
        final status =
            selectedFilter.value == 'All Projects' ||
            p.status.toLowerCase() == selectedFilter.value.toLowerCase();
        final category =
            selectedCategory.value == 'All Categories' ||
            p.categoryId == selectedCategory.value;
        final search =
            _api != null ||
            searchQuery.value.isEmpty ||
            p.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            (p.location ?? '').toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            p.category.toLowerCase().contains(searchQuery.value.toLowerCase());
        return status && category && search;
      }).toList();
  Future<void> refreshProjects({bool background=false}) async {
    if (_api == null) {
      return;
    }
    if(background&&(isLoading.value||isLoadingMore.value))return;
    hasAttempted=true;
    _searchTimer?.cancel();
    final request = ++_request;
    final previousHasMore=hasMore.value;
    isLoadingMore.value = false;
    pageError.value = '';
    hasMore.value = false;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final catalog = await _api.getProjectCategories();
      if (request != _request || isClosed) {
        return;
      }
      categories.assignAll(catalog.where((c) => c['isActive'] == true));
      if (selectedCategory.value != 'All Categories' &&
          !categories.any((c) => c['id'] == selectedCategory.value)) {
        selectedCategory.value = 'All Categories';
      }
      final result = await _api.getEligibleProjectPage(
        projectTypeId: selectedCategory.value == 'All Categories'
            ? null
            : selectedCategory.value,
        search: searchQuery.value,
      );
      if (request != _request || isClosed) {
        return;
      }
      subscriptionRequired.value = result.subscriptionRequired;
      if (result.eligibility != null) {
        eligibility.value =
            SubscriptionEligibilityModel.fromJson(result.eligibility!);
      }
      if (result.subscriptionRequired || result.projects.isEmpty) {
        unawaited(loadSubscriptionPlans());
        unawaited(loadSubscriptionEligibility());
      }
      remoteProjects.assignAll(result.projects.map(ProjectModel.fromBackend));
      hasLoaded=true;
      _page = result.page;
      hasMore.value = result.page < result.totalPages;
      final selectedId = selectedProject.value?.id;
      if (selectedId != null && Get.currentRoute == AppRoutes.projectDetails) {
        await loadDetails(selectedId, background: true);
      }
    } catch (error) {
      if (request == _request && !isClosed) {
        if(error is DioException&&[401,403,404].contains(error.response?.statusCode))remoteProjects.clear();
        hasMore.value=previousHasMore;
        errorMessage.value =
            'Unable to load projects and categories. Please retry.';
      }
    } finally {
      if (request == _request && !isClosed) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_api == null ||
        !hasMore.value ||
        isLoading.value ||
        isLoadingMore.value) {
      return;
    }
    final request = _request;
    isLoadingMore.value = true;
    pageError.value = '';
    try {
      final result = await _api.getEligibleProjectPage(
        page: _page + 1,
        projectTypeId: selectedCategory.value == 'All Categories'
            ? null
            : selectedCategory.value,
        search: searchQuery.value,
      );
      if (request != _request || isClosed) return;
      final ids = remoteProjects.map((p) => p.id).toSet();
      remoteProjects.addAll(
        result.projects
            .map(ProjectModel.fromBackend)
            .where((p) => ids.add(p.id)),
      );
      _page = result.page;
      hasMore.value = result.page < result.totalPages;
    } catch (_) {
      if (request == _request && !isClosed) {
        pageError.value = 'Unable to load more projects. Please retry.';
      }
    } finally {
      if (request == _request && !isClosed) isLoadingMore.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setCategory(String id) {
    selectedCategory.value = id;
    refreshProjects();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchTimer?.cancel();
    // Immediately invalidate requests for the previous query.
    _request++;
    isLoading.value = _api != null;
    isLoadingMore.value = false;
    hasMore.value = false;
    remoteProjects.clear();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (!isClosed) refreshProjects();
    });
  }

  void selectProject(ProjectModel project) {
    _detailRequest++;
    selectedProject.value = project;
    detailError.value = '';
  }

  Future<void> loadDetails(String id, {bool background = false}) async {
    if (_api == null) {
      return;
    }
    final request=++_detailRequest;
    if (!background) isDetailLoading.value = true;
    detailError.value = '';
    if (!background) selectedProject.value = null;
    try {
      final data = await _api.getProject(id);
      if(isClosed||request!=_detailRequest)return;
      if (data == null) {
        selectedProject.value=null;
        throw Exception('Unavailable');
      }
      selectedProject.value = ProjectModel.fromBackend(data);
    } catch (error) {
      if(isClosed||request!=_detailRequest)return;
      if(!background || error is DioException&&[401,403,404].contains(error.response?.statusCode))selectedProject.value = null;
      detailError.value = 'This project is unavailable or could not be loaded.';
    } finally {
      if (!isClosed&&request==_detailRequest) isDetailLoading.value = false;
    }
  }

  Future<void> loadSubscriptionPlans() async {
    if (_api == null) return;
    isLoadingPlans.value = true;
    try {
      final list = await _api.getSubscriptionPlans();
      availablePlans.assignAll(
        list.map((json) => SubscriptionPlanModel.fromJson(json)),
      );
    } catch (_) {
      // Retain existing plans if fetch fails
    } finally {
      isLoadingPlans.value = false;
    }
  }

  Future<void> loadSubscriptionEligibility() async {
    if (_api == null) return;
    try {
      final current = await _api.getCurrentSubscription();
      if (current != null && current['plan'] is Map) {
        activePlan.value = SubscriptionPlanModel.fromJson(
          Map<String, dynamic>.from(current['plan'] as Map),
        );
      }
      final eligData = await _api.getSubscriptionEligibility();
      eligibility.value = SubscriptionEligibilityModel.fromJson(eligData);
      if (eligibility.value?.hasActiveSubscription == true) {
        subscriptionRequired.value = false;
      }
    } catch (_) {
      // Inactive or unauthenticated
    }
  }

  Future<bool> purchasePlan(
    SubscriptionPlanModel plan, {
    String paymentMethod = 'UPI',
  }) async {
    if (_api == null) return false;
    isPurchasingPlan.value = true;
    purchaseError.value = '';
    try {
      final purchase = await _api.purchaseSubscription(
        planId: plan.id,
        paymentMethod: paymentMethod,
      );
      final subscriptionId = purchase['subscriptionId']?.toString();
      final orderId = purchase['orderId']?.toString() ??
          'order_${DateTime.now().millisecondsSinceEpoch}';
      if (subscriptionId == null || subscriptionId.isEmpty) {
        throw Exception('Invalid subscription purchase response');
      }

      await _api.verifySubscriptionPayment({
        'subscriptionId': subscriptionId,
        'gatewayOrderId': orderId,
        'gatewayPaymentId':
            'pay_test_bypass_${DateTime.now().millisecondsSinceEpoch}',
        'gatewaySignature':
            'sig_bypass_${DateTime.now().millisecondsSinceEpoch}',
      });

      subscriptionRequired.value = false;
      await loadSubscriptionEligibility();
      await refreshProjects();
      return true;
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        purchaseError.value = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to complete subscription purchase';
      } else {
        purchaseError.value = e.toString().replaceAll('Exception: ', '');
      }
      return false;
    } finally {
      isPurchasingPlan.value = false;
    }
  }
}
