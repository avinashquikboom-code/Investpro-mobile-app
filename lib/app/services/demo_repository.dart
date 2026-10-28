import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/investment_model.dart';
import '../models/notification_model.dart';
import '../models/project_model.dart';
import '../models/return_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'investment_calculator.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

class DemoRepository extends GetxService {
  final LocalStorageService _storage;
  final NotificationService _notificationService;

  DemoRepository(this._storage, this._notificationService);

  // Reactive State
  final Rx<UserModel> currentUser = const UserModel(
    id: 'INV001',
    fullName: 'Rohit Sharma',
    email: 'rohit.sharma@example.com',
    mobileNumber: '+91 98765 43210',
    role: 'Investor',
    bankName: 'HDFC Bank',
    accountNumber: '•••• 4829',
    ifscCode: 'HDFC0001234',
    isBankVerified: true,
  ).obs;

  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxList<InvestmentModel> investments = <InvestmentModel>[].obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<ReturnPayoutModel> returns = <ReturnPayoutModel>[].obs;
  final RxDouble availableBalance = 12480.0.obs;

  // Computed Portfolio Values
  double get totalInvested => investments
      .where((inv) => inv.status == 'Active')
      .fold(0.0, (sum, inv) => sum + inv.investedAmount);

  double get totalReturns => returns
      .where((r) => r.status == 'Received')
      .fold(0.0, (sum, r) => sum + r.amount);

  double get totalPortfolioValue => totalInvested + totalReturns;

  int get totalActiveProjects => investments
      .where((inv) => inv.status == 'Active')
      .map((inv) => inv.projectId)
      .toSet()
      .length;

  Future<DemoRepository> init() async {
    loadData();
    return this;
  }

  void loadData() {
    // 1. User
    final userMap = _storage.readMap(AppConstants.keyUserData);
    if (userMap != null) {
      currentUser.value = UserModel.fromJson(userMap);
    }

    // 2. Available Balance
    availableBalance.value = _storage.availableBalance;

    // 3. Projects
    final rawProjects = _storage.readList(AppConstants.keyProjectsData);
    if (rawProjects != null && rawProjects.isNotEmpty) {
      projects.value = rawProjects
          .map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      _seedProjects();
    }

    // 4. Investments
    final rawInvestments = _storage.readList(AppConstants.keyInvestmentsData);
    if (rawInvestments != null && rawInvestments.isNotEmpty) {
      investments.value = rawInvestments
          .map((e) => InvestmentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      _seedInvestments();
    }

    // 5. Transactions
    final rawTxns = _storage.readList(AppConstants.keyTransactionsData);
    if (rawTxns != null && rawTxns.isNotEmpty) {
      transactions.value = rawTxns
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      _seedTransactions();
    }

    // 6. Returns
    final rawReturns = _storage.readList(AppConstants.keyReturnsData);
    if (rawReturns != null && rawReturns.isNotEmpty) {
      returns.value = rawReturns
          .map((e) => ReturnPayoutModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      _seedReturns();
    }
  }

  void _seedProjects() {
    projects.value = [
      ProjectModel(
        id: 'proj_01',
        name: 'Software Development Platform',
        category: 'Technology',
        iconType: 'code',
        targetAmount: 50000.0,
        raisedAmount: 25000.0,
        returnRatePercent: 18.0,
        durationMonths: 12,
        status: 'Active',
        riskLevel: 'Moderate',
        description:
            'A cutting-edge developer toolchain powering next-generation cross-platform applications with built-in cloud telemetry.',
        createdAt: DateTime(2025, 10, 1),
      ),
      ProjectModel(
        id: 'proj_02',
        name: 'Mobile App (SaaS Product)',
        category: 'Mobile Software',
        iconType: 'mobile',
        targetAmount: 50000.0,
        raisedAmount: 30000.0,
        returnRatePercent: 15.0,
        durationMonths: 10,
        status: 'Active',
        riskLevel: 'Low',
        description:
            'Enterprise mobile productivity suite with AI workflows, trusted by over 200+ fast-growing startups.',
        createdAt: DateTime(2025, 11, 15),
      ),
      ProjectModel(
        id: 'proj_03',
        name: 'AI Automation Tool',
        category: 'Artificial Intelligence',
        iconType: 'gear',
        targetAmount: 50000.0,
        raisedAmount: 17500.0,
        returnRatePercent: 12.0,
        durationMonths: 8,
        status: 'Active',
        riskLevel: 'Moderate',
        description:
            'Autonomous business process workflow agent cutting manual operations by 70% with intelligent heuristics.',
        createdAt: DateTime(2026, 1, 10),
      ),
    ];
    _saveProjects();
  }

  void _seedInvestments() {
    investments.value = [
      InvestmentModel(
        id: 'INV-2025-1015-01',
        projectId: 'proj_01',
        projectName: 'Software Development Platform',
        iconType: 'code',
        investedAmount: 50000.0,
        returnRatePercent: 18.0,
        durationMonths: 12,
        expectedReturn: 9000.0,
        maturityAmount: 59000.0,
        startDate: DateTime(2025, 10, 15),
        maturityDate: DateTime(2026, 10, 15),
        progressPercent: 50.0,
        status: 'Active',
      ),
      InvestmentModel(
        id: 'INV-2025-1120-02',
        projectId: 'proj_02',
        projectName: 'Mobile App (SaaS Product)',
        iconType: 'mobile',
        investedAmount: 15000.0,
        returnRatePercent: 15.0,
        durationMonths: 10,
        expectedReturn: 4500.0,
        maturityAmount: 19500.0,
        startDate: DateTime(2025, 11, 20),
        maturityDate: DateTime(2026, 9, 20),
        progressPercent: 60.0,
        status: 'Active',
      ),
      InvestmentModel(
        id: 'INV-2026-0110-03',
        projectId: 'proj_03',
        projectName: 'AI Automation Tool',
        iconType: 'gear',
        investedAmount: 5000.0,
        returnRatePercent: 12.0,
        durationMonths: 8,
        expectedReturn: 1500.0,
        maturityAmount: 6500.0,
        startDate: DateTime(2026, 1, 10),
        maturityDate: DateTime(2026, 9, 10),
        progressPercent: 35.0,
        status: 'Active',
      ),
    ];
    _saveInvestments();
  }

  void _seedTransactions() {
    transactions.value = [
      TransactionModel(
        id: 'TXN-101',
        type: TransactionType.investment,
        title: 'Investment',
        subtitle: 'Software Development Platform',
        amount: 50000.0,
        date: DateTime(2026, 4, 12),
        status: 'Completed',
        projectName: 'Software Development Platform',
        referenceId: 'TXN-20260412-01',
      ),
      TransactionModel(
        id: 'TXN-102',
        type: TransactionType.returnReceived,
        title: 'Return Received',
        subtitle: 'Monthly Return',
        amount: 1500.0,
        date: DateTime(2026, 4, 6),
        status: 'Completed',
        referenceId: 'TXN-20260406-02',
      ),
      TransactionModel(
        id: 'TXN-103',
        type: TransactionType.withdrawal,
        title: 'Withdrawal',
        subtitle: 'Bank Account •••• 4829',
        amount: 5000.0,
        date: DateTime(2026, 3, 28),
        status: 'Completed',
        referenceId: 'TXN-20260328-03',
      ),
      TransactionModel(
        id: 'TXN-104',
        type: TransactionType.deposit,
        title: 'Deposit',
        subtitle: 'Wallet Top-up',
        amount: 10000.0,
        date: DateTime(2026, 4, 5),
        status: 'Completed',
        referenceId: 'TXN-20260405-04',
      ),
      TransactionModel(
        id: 'TXN-105',
        type: TransactionType.investment,
        title: 'Investment',
        subtitle: 'Mobile App (SaaS Product)',
        amount: 30000.0,
        date: DateTime(2026, 3, 20),
        status: 'Completed',
        projectName: 'Mobile App (SaaS Product)',
        referenceId: 'TXN-20260320-05',
      ),
      TransactionModel(
        id: 'TXN-106',
        type: TransactionType.withdrawal,
        title: 'Withdrawal',
        subtitle: 'Processing',
        amount: 5000.0,
        date: DateTime(2026, 4, 12),
        status: 'Processing',
        referenceId: 'TXN-20260412-06',
      ),
      TransactionModel(
        id: 'TXN-107',
        type: TransactionType.returnReceived,
        title: 'Return Received',
        subtitle: 'Monthly Return',
        amount: 1500.0,
        date: DateTime(2026, 3, 6),
        status: 'Completed',
        referenceId: 'TXN-20260306-07',
      ),
    ];
    _saveTransactions();
  }

  void _seedReturns() {
    returns.value = [
      ReturnPayoutModel(
        id: 'RET-01',
        investmentId: 'INV-2025-1015-01',
        projectName: 'Software Development Platform',
        monthYear: 'Apr 2026',
        payoutDate: DateTime(2026, 4, 5),
        amount: 1500.0,
        status: 'Received',
        periodType: 'Monthly',
      ),
      ReturnPayoutModel(
        id: 'RET-02',
        investmentId: 'INV-2025-1015-01',
        projectName: 'Software Development Platform',
        monthYear: 'May 2026',
        payoutDate: DateTime(2026, 5, 5),
        amount: 1500.0,
        status: 'Received',
        periodType: 'Monthly',
      ),
      ReturnPayoutModel(
        id: 'RET-03',
        investmentId: 'INV-2025-1015-01',
        projectName: 'Software Development Platform',
        monthYear: 'Jun 2026',
        payoutDate: DateTime(2026, 6, 5),
        amount: 1500.0,
        status: 'Pending',
        periodType: 'Monthly',
      ),
      ReturnPayoutModel(
        id: 'RET-04',
        investmentId: 'INV-2025-1015-01',
        projectName: 'Software Development Platform',
        monthYear: 'Jul 2026',
        payoutDate: DateTime(2026, 7, 5),
        amount: 1500.0,
        status: 'Pending',
        periodType: 'Monthly',
      ),
      ReturnPayoutModel(
        id: 'RET-05',
        investmentId: 'INV-2025-1015-01',
        projectName: 'Software Development Platform',
        monthYear: 'Aug 2026',
        payoutDate: DateTime(2026, 8, 5),
        amount: 1500.0,
        status: 'Pending',
        periodType: 'Monthly',
      ),
    ];
    _saveReturns();
  }

  // --- Actions ---

  /// Places a new investment
  InvestmentModel createInvestment({
    required ProjectModel project,
    required double amount,
    required String paymentMethod,
  }) {
    final calc = InvestmentCalculator.calculate(
      principal: amount,
      returnRatePercent: project.returnRatePercent,
      durationMonths: project.durationMonths,
    );

    final now = DateTime.now();
    final maturity = DateTime(now.year, now.month + project.durationMonths, now.day);
    final refId = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';

    final investment = InvestmentModel(
      id: refId,
      projectId: project.id,
      projectName: project.name,
      iconType: project.iconType,
      investedAmount: amount,
      returnRatePercent: project.returnRatePercent,
      durationMonths: project.durationMonths,
      expectedReturn: calc.expectedTotalReturn,
      maturityAmount: calc.projectedMaturityAmount,
      startDate: now,
      maturityDate: maturity,
      progressPercent: 5.0,
      status: 'Active',
      paymentMethod: paymentMethod,
    );

    // 1. Add to investments
    investments.insert(0, investment);
    _saveInvestments();

    // 2. Update project raised amount
    final pIdx = projects.indexWhere((p) => p.id == project.id);
    if (pIdx != -1) {
      final updatedProject = projects[pIdx].copyWith(
        raisedAmount: projects[pIdx].raisedAmount + amount,
      );
      projects[pIdx] = updatedProject;
      _saveProjects();
    }

    // 3. Create investment transaction
    final txn = TransactionModel(
      id: 'TXN-${now.millisecondsSinceEpoch}',
      type: TransactionType.investment,
      title: 'Investment',
      subtitle: project.name,
      amount: amount,
      date: now,
      status: 'Completed',
      projectId: project.id,
      projectName: project.name,
      referenceId: refId,
    );
    transactions.insert(0, txn);
    _saveTransactions();

    // 4. Create future return schedule
    final monthlyReturn = calc.monthlyProjectedReturn;
    for (int i = 1; i <= (project.durationMonths > 5 ? 5 : project.durationMonths); i++) {
      final payoutDate = DateTime(now.year, now.month + i, 5);
      final monthName = _monthName(payoutDate.month);
      returns.add(
        ReturnPayoutModel(
          id: 'RET-${now.millisecondsSinceEpoch}-$i',
          investmentId: refId,
          projectName: project.name,
          monthYear: '$monthName ${payoutDate.year}',
          payoutDate: payoutDate,
          amount: monthlyReturn,
          status: 'Pending',
          periodType: 'Monthly',
        ),
      );
    }
    _saveReturns();

    // 5. Add notification
    _notificationService.addNotification(
      type: NotificationType.investmentSuccess,
      title: 'Investment Successful',
      description: 'Your investment of ₹ ${amount.toInt()} in ${project.name} has been placed.',
      relatedId: refId,
    );

    return investment;
  }

  /// Submits a demo withdrawal request
  bool requestWithdrawal({required double amount}) {
    if (amount <= 0 || amount > availableBalance.value) return false;

    availableBalance.value -= amount;
    _storage.setAvailableBalance(availableBalance.value);

    final now = DateTime.now();
    final refId = 'WTH-${now.millisecondsSinceEpoch}';

    final txn = TransactionModel(
      id: 'TXN-${now.millisecondsSinceEpoch}',
      type: TransactionType.withdrawal,
      title: 'Withdrawal',
      subtitle: '${currentUser.value.bankName} (${currentUser.value.accountNumber})',
      amount: amount,
      date: now,
      status: 'Processing',
      referenceId: refId,
    );

    transactions.insert(0, txn);
    _saveTransactions();

    _notificationService.addNotification(
      type: NotificationType.withdrawalApproved,
      title: 'Withdrawal Request Submitted',
      description: 'Withdrawal request of ₹ ${amount.toInt()} is under processing.',
      relatedId: refId,
    );

    return true;
  }

  /// Updates user profile
  void updateProfile({
    required String fullName,
    required String email,
    required String mobileNumber,
  }) {
    currentUser.value = currentUser.value.copyWith(
      fullName: fullName,
      email: email,
      mobileNumber: mobileNumber,
    );
    _storage.writeMap(AppConstants.keyUserData, currentUser.value.toJson());
  }

  void _saveProjects() {
    _storage.writeList(AppConstants.keyProjectsData, projects.map((p) => p.toJson()).toList());
  }

  void _saveInvestments() {
    _storage.writeList(AppConstants.keyInvestmentsData, investments.map((i) => i.toJson()).toList());
  }

  void _saveTransactions() {
    _storage.writeList(AppConstants.keyTransactionsData, transactions.map((t) => t.toJson()).toList());
  }

  void _saveReturns() {
    _storage.writeList(AppConstants.keyReturnsData, returns.map((r) => r.toJson()).toList());
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }
}
