import 'api_diagnostics.dart';
import 'dart:convert';

import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../models/investment_model.dart';
import '../models/notification_model.dart';
import '../models/project_model.dart';
import '../models/return_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/withdrawal_model.dart';
import 'api_service.dart';
import 'backend_snapshot.dart';
import 'investment_calculator.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Local demo ledger & backend synchronized repository.
/// Money is converted to integer paise for all arithmetic.
/// Operates seamlessly offline or connected to the Express + PostgreSQL backend.
class DemoRepository extends GetxService {
  final LocalStorageService _storage;
  final NotificationService _notificationService;
  final ApiService? _api;

  DemoRepository(this._storage, this._notificationService, [this._api]);

  final currentUser = const UserModel(
    id: '',
    fullName: '',
    email: '',
    mobileNumber: '',
  ).obs;

  final projects = <ProjectModel>[].obs;
  final investments = <InvestmentModel>[].obs;
  final transactions = <TransactionModel>[].obs;
  final returns = <ReturnPayoutModel>[].obs;
  final withdrawals = <WithdrawalModel>[].obs;
  final availableBalance = 0.0.obs;
  int _generation = 0;
  bool get isLive => _api != null;
  final syncError = ''.obs;
  final isSyncing = false.obs;
  final serverTotalInvested = 0.0.obs;
  final serverTotalReturns = 0.0.obs;
  Future<void>? _sync;
  void clearLiveData() {
    if (!isLive) return;
    _generation++;
    _sync = null;
    projects.clear(); investments.clear(); withdrawals.clear(); transactions.clear(); returns.clear();
    availableBalance.value = 0; serverTotalInvested.value = 0; serverTotalReturns.value = 0;
    currentUser.value = const UserModel(id: '', fullName: '', email: '', mobileNumber: '');
    syncError.value = '';
    isSyncing.value=false;
  }
  bool _writing = false;
  int _sequence = 0;

  String newReference(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  String _paymentIntentKey(ProjectModel project,double amount)=>'payment_intent_${currentUser.value.id}_${project.id}_${minor(amount)}';
  Future<String> paymentRequestId(ProjectModel project,double amount) async {
    final key=_paymentIntentKey(project,amount);
    final previous=_storage.read(key);
    if(previous is String&&previous.isNotEmpty)return previous;
    final request=newReference('INV');
    await _storage.write(key,request);
    return request;
  }
  Future<void> clearPaymentRequest(ProjectModel project,double amount)=>_storage.remove(_paymentIntentKey(project,amount));

  static int minor(double amount) => (amount * 100).round();

  double get totalInvested => isLive ? serverTotalInvested.value :
      investments
          .where((i) => i.status == 'Active')
          .fold<int>(0, (s, i) => s + minor(i.investedAmount)) /
      100;

  double get totalReturns => isLive ? serverTotalReturns.value :
      returns
          .where((r) => r.status == 'Received')
          .fold<int>(0, (s, r) => s + minor(r.amount)) /
      100;

  double get totalPortfolioValue =>
      (minor(totalInvested) + minor(availableBalance.value)) / 100;

  int get totalActiveProjects => investments
      .where((i) => i.status == 'Active')
      .map((i) => i.projectId)
      .toSet()
      .length;

  int get totalInvestedProjects => investments
      .where((i) => i.status == 'Active' || i.status == 'Completed')
      .map((i) => i.projectId)
      .toSet()
      .length;

  double? get growthPercent =>
      (totalInvested <= 0 || totalReturns <= 0) ? null : totalReturns / totalInvested * 100;

  ProjectModel liveProject(ProjectModel project) {
    try {
      return projects.firstWhere((p) => p.id == project.id);
    } catch (_) {
      return project;
    }
  }

  String? investmentError(ProjectModel project, double amount) {
    if (isLive) {
      if (!amount.isFinite || amount <= 0) return 'Enter a positive amount';
      if (amount < project.minInvestment || (project.maxInvestment != null && amount > project.maxInvestment!)) return 'Amount is outside the project investment limits';
      if (project.status != 'Active') return 'Project is not available';
      if (minor(amount) > minor(project.targetAmount)-minor(project.raisedAmount)) return 'Amount exceeds the remaining project funding';
      return null;
    }
    if (!amount.isFinite ||
        amount <= 0 ||
        minor(amount) < minor(AppConstants.minInvestmentAmount) ||
        minor(amount) > minor(AppConstants.maxInvestmentAmount)) {
      return 'Enter an amount between ₹5,000 and ₹1,00,000';
    }
    final p = liveProject(project);
    if (p.status != 'Active') return 'This project is closed for investment';
    if (minor(amount) > minor(p.targetAmount) - minor(p.raisedAmount)) {
      return 'Amount exceeds remaining project funding';
    }
    return null;
  }

  Future<DemoRepository> init() async {
    if (isLive) { clearLiveData(); return this; }
    await loadData();
    return this;
  }

  Future<void> loadData() async {
    if (isLive) { await syncFromBackend(); return; }
    final snapshot = _storage.readMap('ledger_v2');
    if (snapshot != null) {
      _apply(snapshot);
      return;
    }
    _seedProjects();
    final previous = _storage.readList(AppConstants.keyInvestmentsData);
    if (previous != null) {
      investments.assignAll(
        previous.map(
          (v) => InvestmentModel.fromJson(Map<String, dynamic>.from(v)),
        ),
      );
      final savedProjects = _storage.readList(AppConstants.keyProjectsData);
      if (savedProjects != null) {
        projects.assignAll(
          savedProjects.map(
            (v) => ProjectModel.fromJson(Map<String, dynamic>.from(v)),
          ),
        );
      }
      final profile = _storage.readMap(AppConstants.keyUserData);
      if (profile != null) currentUser.value = UserModel.fromJson(profile);
      transactions.assignAll(
        (_storage.readList(AppConstants.keyTransactionsData) ?? []).map(
          (v) => TransactionModel.fromJson(Map<String, dynamic>.from(v)),
        ),
      );
      returns.assignAll(
        (_storage.readList(AppConstants.keyReturnsData) ?? []).map(
          (v) => ReturnPayoutModel.fromJson(Map<String, dynamic>.from(v)),
        ),
      );
      for (final i in investments) {
        final existing = returns.where((r) => r.investmentId == i.id).toList();
        if (existing.isEmpty) returns.addAll(_schedule(i));
      }
    } else {
      _seedLedger();
    }
    _recalculateBalance();
    await _storage.writeMap('ledger_v2', _snapshot());
  }

  Future<void> syncFromBackend() {
    if (!isLive) return Future<void>.value();
    if (_sync != null) return _sync!;
    late final Future<void> pending;
    pending = _loadSnapshot().whenComplete(() { if (identical(_sync, pending)) _sync = null; });
    _sync = pending;
    return pending;
  }
  Future<void> _loadSnapshot() async {
    final generation = _generation;
    final session = _api!.sessionVersion;
    isSyncing.value = true;
    syncError.value = '';
    try {
      final token = await _api.getAccessToken();
      if ((token == null || token.isEmpty) && (await _api.getRefreshToken())?.isNotEmpty != true) { clearLiveData(); return; }
      final account = await _api.object('/mobile/account-status');
      if (generation != _generation || session != _api.sessionVersion) throw StateError('Session changed');
      if (account['status'] != 'ACTIVE') {
        final previous = currentUser.value;
        clearLiveData();
        currentUser.value = previous.copyWith(accountStatus: '${account['status']}');
        throw StateError('Account is not active');
      }
      final data = await Future.wait<dynamic>([
        _api.getProfile(), _api.getDashboard(), _api.getEligibleProjects(),
        _api.getInvestments(), _api.getWithdrawals(), _api.getTransactions(), _api.getReturns(),
      ]);
      if (data.any((v) => v == null)) throw StateError('Account data is unavailable');
      final profile = Map<String, dynamic>.from(data[0] as Map);
      final portfolio = (data[1] as Map)['portfolio'];
      if (portfolio is! Map || !portfolio.containsKey('availableBalance') || !portfolio.containsKey('totalInvested')) throw StateError('Portfolio data is unavailable');
      final user = BackendSnapshot.user(profile);
      if (user.accountStatus != 'ACTIVE') throw StateError('Account is not active');
      if (generation != _generation || session != _api.sessionVersion) throw StateError('Session changed');
      // Commit one coherent server snapshot; successful empty collections clear stale data.
      currentUser.value = user;
      serverTotalInvested.value = BackendSnapshot.number(portfolio['totalInvested']);
      serverTotalReturns.value = BackendSnapshot.number(portfolio['totalReturns']);
      availableBalance.value = BackendSnapshot.number(portfolio['availableBalance']);
      projects.assignAll((data[2] as List).map((v) => ProjectModel.fromBackend(Map<String, dynamic>.from(v as Map))));
      investments.assignAll((data[3] as List).map((v) => BackendSnapshot.investment(Map<String, dynamic>.from(v as Map))));
      withdrawals.assignAll((data[4] as List).map((v) => BackendSnapshot.withdrawal(Map<String, dynamic>.from(v as Map))));
      transactions.assignAll((data[5] as List).map((v) => BackendSnapshot.transaction(Map<String, dynamic>.from(v as Map))));
      returns.assignAll((data[6] as List).map((v) => BackendSnapshot.payout(Map<String, dynamic>.from(v as Map))));
    } catch (error) {
      ApiDiagnostics.log(error);
      if(generation!=_generation||session!=_api.sessionVersion)rethrow;
      syncError.value = 'Unable to synchronize your account. Displayed records may be out of date.';
      rethrow;
    } finally { if(generation==_generation&&session==_api.sessionVersion)isSyncing.value = false; }
  }

  void _recalculateBalance() {
    final credits = transactions
        .where(
          (t) =>
              t.type == TransactionType.deposit ||
              t.type == TransactionType.returnReceived,
        )
        .where((t) => t.status == 'Completed')
        .fold<int>(0, (s, t) => s + minor(t.amount));
    final debits = transactions
        .where(
          (t) =>
              t.type == TransactionType.withdrawal &&
              (t.status == 'Processing' || t.status == 'Completed'),
        )
        .fold<int>(0, (s, t) => s + minor(t.amount));
    availableBalance.value = (credits - debits) / 100;
  }

  Map<String, dynamic> _snapshot() => {
    'user': currentUser.value.toJson(),
    'projects': projects.map((v) => v.toJson()).toList(),
    'investments': investments.map((v) => v.toJson()).toList(),
    'transactions': transactions.map((v) => v.toJson()).toList(),
    'returns': returns.map((v) => v.toJson()).toList(),
    'withdrawals': withdrawals.map((v) => v.toJson()).toList(),
  };

  void _apply(Map<String, dynamic> j) {
    currentUser.value = UserModel.fromJson(
      Map<String, dynamic>.from(j['user']),
    );
    projects.assignAll(
      (j['projects'] as List).map(
        (v) => ProjectModel.fromJson(Map<String, dynamic>.from(v)),
      ),
    );
    investments.assignAll(
      (j['investments'] as List).map(
        (v) => InvestmentModel.fromJson(Map<String, dynamic>.from(v)),
      ),
    );
    transactions.assignAll(
      (j['transactions'] as List).map(
        (v) => TransactionModel.fromJson(Map<String, dynamic>.from(v)),
      ),
    );
    returns.assignAll(
      (j['returns'] as List).map(
        (v) => ReturnPayoutModel.fromJson(Map<String, dynamic>.from(v)),
      ),
    );
    withdrawals.assignAll(
      (j['withdrawals'] as List).map(
        (v) => WithdrawalModel.fromJson(Map<String, dynamic>.from(v)),
      ),
    );
    _recalculateBalance();
  }

  Future<void> _commit(void Function(Map<String, dynamic>) update) async {
    if (_writing) {
      throw StateError('Another update is in progress. Please retry.');
    }
    _writing = true;
    try {
      final next = jsonDecode(jsonEncode(_snapshot())) as Map<String, dynamic>;
      update(next);
      await _storage.writeMap('ledger_v2', next);
      _apply(next);
    } finally {
      _writing = false;
    }
  }

  InvestmentModel _record(
    String id,
    ProjectModel p,
    double amount,
    DateTime date, {
    String status = 'Active',
    String method = 'Demo UPI',
  }) {
    final c = InvestmentCalculator.calculate(
      principal: amount,
      returnRatePercent: p.returnRatePercent,
      durationMonths: p.durationMonths,
    );
    return InvestmentModel(
      id: id,
      projectId: p.id,
      projectName: p.name,
      iconType: p.iconType,
      investedAmount: c.principal,
      returnRatePercent: p.returnRatePercent,
      durationMonths: p.durationMonths,
      expectedReturn: c.expectedTotalReturn,
      maturityAmount: c.projectedMaturityAmount,
      startDate: date,
      maturityDate: InvestmentCalculator.addMonths(date, p.durationMonths),
      progressPercent: 0,
      status: status,
      paymentMethod: method,
    );
  }

  List<ReturnPayoutModel> _schedule(
    InvestmentModel i, {
    bool received = false,
  }) {
    final total = minor(i.expectedReturn), count = i.durationMonths;
    return List.generate(count, (n) {
      final date = InvestmentCalculator.addMonths(i.startDate, n + 1);
      return ReturnPayoutModel(
        id: '${i.id}-R$n',
        investmentId: i.id,
        projectName: i.projectName,
        monthYear: '${date.month}/${date.year}',
        payoutDate: date,
        amount: (total ~/ count + (n < total % count ? 1 : 0)) / 100,
        status: received ? 'Received' : 'Pending',
      );
    });
  }

  void _seedLedger() {
    final now = DateTime.now();
    final initial = [
      _record(
        'DEMO-01',
        projects[0],
        30000,
        InvestmentCalculator.addMonths(now, -4),
      ),
      _record(
        'DEMO-02',
        projects[1],
        25000,
        InvestmentCalculator.addMonths(now, -3),
      ),
      _record(
        'DEMO-03',
        projects[2],
        15000,
        InvestmentCalculator.addMonths(now, -2),
      ),
      _record(
        'DEMO-HISTORY',
        projects[1],
        100000,
        InvestmentCalculator.addMonths(now, -18),
        status: 'Withdrawn',
      ),
    ];
    investments.assignAll(initial);
    returns.assignAll(
      initial.expand((i) => _schedule(i, received: i.status == 'Withdrawn')),
    );
    transactions.assignAll([
      ...initial.map(
        (i) => TransactionModel(
          id: '${i.id}-T',
          type: TransactionType.investment,
          title: 'Investment',
          subtitle: i.projectName,
          amount: i.investedAmount,
          date: i.startDate,
          referenceId: i.id,
          projectId: i.projectId,
          projectName: i.projectName,
        ),
      ),
      ...returns
          .where((r) => r.status == 'Received')
          .map(
            (r) => TransactionModel(
              id: r.id,
              type: TransactionType.returnReceived,
              title: 'Return Received',
              subtitle: r.projectName,
              amount: r.amount,
              date: r.payoutDate,
              referenceId: r.id,
              projectName: r.projectName,
            ),
          ),
    ]);
  }

  Future<InvestmentModel> createInvestment({
    required ProjectModel project,
    required double amount,
    required String paymentMethod,
    String? requestId,
  }) async {
    final reference = requestId ?? newReference('DEMO');
    final existing = investments.where((i) => i.id == reference).firstOrNull;
    if (existing != null) return existing;

    final error = investmentError(project, amount);
    if (error != null) throw ArgumentError(error);

    if (isLive) {
      final result = await _api!.createInvestment(projectId: project.id, amount: amount,
        paymentMethod: paymentMethod.contains('UPI') ? 'UPI' : 'CARD', idempotencyKey: reference);
      if (result == null) throw StateError('The server did not create an investment request');
      final record = BackendSnapshot.investment(result);
      investments.removeWhere((v) => v.id == record.id);
      investments.insert(0, record);
      syncFromBackend().catchError((_) {});
      return record;
    }

    // 2. Local commit fallback
    final p = liveProject(project);
    final i = _record(
      reference,
      p,
      amount,
      DateTime.now(),
      method: paymentMethod,
    );
    await _commit((j) {
      (j['investments'] as List).insert(0, i.toJson());
      final list = j['projects'] as List;
      final index = list.indexWhere((v) => v['id'] == p.id);
      if (index >= 0) {
        list[index] = p
            .copyWith(
              raisedAmount: (minor(p.raisedAmount) + minor(amount)) / 100,
            )
            .toJson();
      }
      (j['returns'] as List).addAll(_schedule(i).map((r) => r.toJson()));
      (j['transactions'] as List).insert(
        0,
        TransactionModel(
          id: '$reference-T',
          type: TransactionType.investment,
          title: 'Investment',
          subtitle: p.name,
          amount: amount,
          date: i.startDate,
          referenceId: reference,
          projectId: p.id,
          projectName: p.name,
        ).toJson(),
      );
    });
    _notificationService.addNotification(
      type: NotificationType.investmentSuccess,
      title: 'Investment Successful',
      description:
          'Demo investment in ${p.name} recorded. Reference: $reference',
      relatedId: reference,
    );
    return i;
  }

  Future<bool> requestWithdrawal({
    required double amount,
    bool bankSelected = false,
    String? requestId,
  }) async {
    if (!bankSelected ||
        !amount.isFinite ||
        minor(amount) < minor(AppConstants.minWithdrawalAmount) ||
        minor(amount) > minor(availableBalance.value)) {
      return false;
    }

    if (isLive) {
      final bankId = currentUser.value.bankAccountId;
      if (bankId == null) throw StateError('Add a bank account before requesting a withdrawal');
      final result = await _api!.createWithdrawal(amount: amount, bankAccountId: bankId, idempotencyKey: requestId);
      if (result == null) throw StateError('The server did not accept the withdrawal request');
      final record = BackendSnapshot.withdrawal(result);
      withdrawals.removeWhere((v) => v.id == record.id);
      withdrawals.insert(0, record);
      syncFromBackend().catchError((_) {});
      return true;
    }

    // 2. Local commit fallback
    final now = DateTime.now(), reference = newReference('DEMO-WD');
    final w = WithdrawalModel(
      id: reference,
      amount: amount,
      bankName: currentUser.value.bankName,
      accountNumber: currentUser.value.accountNumber,
      requestDate: now,
      referenceId: reference,
    );
    await _commit((j) {
      (j['withdrawals'] as List).insert(0, w.toJson());
      (j['transactions'] as List).insert(
        0,
        TransactionModel(
          id: reference,
          type: TransactionType.withdrawal,
          title: 'Withdrawal',
          subtitle:
              '${currentUser.value.bankName} ${currentUser.value.accountNumber}',
          amount: amount,
          date: now,
          status: 'Processing',
          referenceId: reference,
        ).toJson(),
      );
    });
    _notificationService.addNotification(
      type: NotificationType.withdrawalApproved,
      title: 'Withdrawal Request Submitted',
      description:
          'Your withdrawal of ₹${amount.toStringAsFixed(0)} is Processing.',
      relatedId: reference,
    );
    return true;
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String mobileNumber,
  }) async {
    if (isLive) {
      final saved = await _api!.updateProfile(fullName: fullName, mobileNumber: mobileNumber);
      if (saved == null) throw StateError('Your profile could not be saved');
      final owner = saved['user'] as Map?;
      currentUser.value = currentUser.value.copyWith(fullName: saved['fullName'] as String?, mobileNumber: owner?['mobileNumber'] as String?);
      syncFromBackend().catchError((_) {});
      return;
    }
    await saveUser(
      currentUser.value.copyWith(
        fullName: fullName,
        email: email,
        mobileNumber: mobileNumber,
      ),
    );
  }

  Future<void> saveUser(UserModel user) =>
      _commit((j) => j['user'] = user.toJson());

  void _seedProjects() {
    projects.value = [
      ProjectModel(
        id: 'proj_01',
        name: 'Software Development Platform',
        category: 'Technology',
        iconType: 'code',
        targetAmount: 500000.0,
        raisedAmount: 250000.0,
        returnRatePercent: 18.0,
        durationMonths: 12,
        status: 'Active',
        riskLevel: 'Moderate',
        description: 'A cutting-edge developer toolchain powering next-generation cross-platform applications with built-in cloud telemetry.',
        createdAt: DateTime(2025, 10, 1),
      ),
      ProjectModel(
        id: 'proj_02',
        name: 'Mobile App (SaaS Product)',
        category: 'Mobile Software',
        iconType: 'mobile',
        targetAmount: 500000.0,
        raisedAmount: 300000.0,
        returnRatePercent: 15.0,
        durationMonths: 10,
        status: 'Active',
        riskLevel: 'Low',
        description: 'Enterprise mobile productivity suite with AI workflows, trusted by over 200+ fast-growing startups.',
        createdAt: DateTime(2025, 11, 15),
      ),
      ProjectModel(
        id: 'proj_03',
        name: 'AI Automation Tool',
        category: 'Artificial Intelligence',
        iconType: 'gear',
        targetAmount: 500000.0,
        raisedAmount: 175000.0,
        returnRatePercent: 12.0,
        durationMonths: 8,
        status: 'Active',
        riskLevel: 'Moderate',
        description: 'Autonomous business process workflow agent cutting manual operations by 70% with intelligent heuristics.',
        createdAt: DateTime(2026, 1, 10),
      ),
    ];
  }
}
