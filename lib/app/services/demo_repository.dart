import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    id: 'INV001',
    fullName: 'Rohit Sharma',
    email: 'rohit.sharma@example.com',
    mobileNumber: '9876543210',
    isBankVerified: true,
  ).obs;

  final projects = <ProjectModel>[].obs;
  final investments = <InvestmentModel>[].obs;
  final transactions = <TransactionModel>[].obs;
  final returns = <ReturnPayoutModel>[].obs;
  final withdrawals = <WithdrawalModel>[].obs;
  final availableBalance = 0.0.obs;
  bool _writing = false;
  int _sequence = 0;

  String newReference(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  static int minor(double amount) => (amount * 100).round();

  double get totalInvested =>
      investments
          .where((i) => i.status == 'Active')
          .fold<int>(0, (s, i) => s + minor(i.investedAmount)) /
      100;

  double get totalReturns =>
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

  double get growthPercent =>
      totalInvested == 0 ? 0 : totalReturns / totalInvested * 100;

  ProjectModel liveProject(ProjectModel project) {
    try {
      return projects.firstWhere((p) => p.id == project.id);
    } catch (_) {
      return project;
    }
  }

  String? investmentError(ProjectModel project, double amount) {
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
    await loadData();
    // Attempt background sync if connected
    syncFromBackend().catchError((e) {
      debugPrint('[DemoRepository] initial sync ignored: $e');
    });
    return this;
  }

  Future<void> loadData() async {
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

  Future<void> syncFromBackend() async {
    if (_api == null) return;
    try {
      final token = await _api.getAccessToken();
      if (token == null || token.isEmpty) return;

      // 1. Sync Profile
      final profile = await _api.getProfile();
      if (profile != null) {
        final bankAccs = profile['bankAccounts'] as List<dynamic>?;
        final primaryBank = bankAccs != null && bankAccs.isNotEmpty
            ? bankAccs[0] as Map<String, dynamic>?
            : null;
        final rawAcc = primaryBank?['accountNumber']?.toString();
        final displayAcc = (rawAcc != null && rawAcc.length >= 4)
            ? '•••• ${rawAcc.substring(rawAcc.length - 4)}'
            : currentUser.value.accountNumber;

        currentUser.value = UserModel(
          id: profile['id'] as String? ?? currentUser.value.id,
          fullName:
              profile['fullName'] as String? ?? currentUser.value.fullName,
          email:
              profile['user']?['email'] as String? ?? currentUser.value.email,
          mobileNumber:
              profile['user']?['mobileNumber'] as String? ??
              currentUser.value.mobileNumber,
          role: 'Investor',
          isBankVerified: profile['isBankVerified'] as bool? ?? true,
          bankName:
              primaryBank?['bankName'] as String? ?? currentUser.value.bankName,
          accountNumber: displayAcc,
          ifscCode:
              primaryBank?['ifscCode'] as String? ?? currentUser.value.ifscCode,
        );
      }

      // 2. Sync Dashboard & Wallet
      final dash = await _api.getDashboard();
      if (dash != null && dash['wallet'] != null) {
        final w = dash['wallet'];
        availableBalance.value =
            (w['availableBalance'] as num?)?.toDouble() ?? 0.0;
      }

      // 3. Sync Projects
      final projs = await _api.getProjects();
      if (projs != null && projs.isNotEmpty) {
        final mappedProjs = projs.map((p) {
          final typeName = p['projectType']?['name'] as String? ?? 'Technology';
          String icon = 'code';
          if (typeName.toLowerCase().contains('mobile')) {
            icon = 'mobile';
          } else if (typeName.toLowerCase().contains('ai') ||
              typeName.toLowerCase().contains('auto')) {
            icon = 'gear';
          }

          return ProjectModel(
            id: p['id'] as String,
            name: p['title'] as String? ?? 'Project',
            category: typeName,
            iconType: icon,
            targetAmount: (p['targetAmount'] as num?)?.toDouble() ?? 500000.0,
            raisedAmount: (p['fundedAmount'] as num?)?.toDouble() ?? 0.0,
            returnRatePercent: (p['expectedRoi'] as num?)?.toDouble() ?? 15.0,
            durationMonths: p['tenureMonths'] as int? ?? 12,
            status: p['status'] == 'ACTIVE' ? 'Active' : 'Completed',
            riskLevel: p['riskLevel'] == 'LOW'
                ? 'Low'
                : p['riskLevel'] == 'HIGH'
                ? 'High'
                : 'Moderate',
            description: p['description'] as String? ?? '',
            createdAt: p['createdAt'] != null
                ? DateTime.parse(p['createdAt'])
                : DateTime.now(),
          );
        }).toList();

        projects.assignAll(mappedProjs);
      }

      // 4. Sync Investments
      final invs = await _api.getInvestments();
      if (invs != null && invs.isNotEmpty) {
        final mappedInvs = invs.map((i) {
          final p = i['project'] as Map<String, dynamic>?;
          final amt = (i['amount'] as num?)?.toDouble() ?? 0.0;
          final roi = (i['agreedRoi'] as num?)?.toDouble() ?? 15.0;
          final expReturn =
              (i['totalExpectedReturns'] as num?)?.toDouble() ?? 0.0;
          final start = i['createdAt'] != null
              ? DateTime.parse(i['createdAt'])
              : DateTime.now();
          final months = p?['tenureMonths'] as int? ?? 12;
          final matDate = InvestmentCalculator.addMonths(start, months);

          return InvestmentModel(
            id: i['id'] as String,
            projectId: i['projectId'] as String? ?? '',
            projectName: p?['title'] as String? ?? 'Project Investment',
            iconType: 'code',
            investedAmount: amt,
            returnRatePercent: roi,
            durationMonths: months,
            expectedReturn: expReturn,
            maturityAmount: amt + expReturn,
            startDate: start,
            maturityDate: matDate,
            progressPercent: 0,
            status: i['status'] == 'ACTIVE' ? 'Active' : 'Completed',
            paymentMethod: i['paymentMethod'] as String? ?? 'UPI',
          );
        }).toList();

        investments.assignAll(mappedInvs);
      }

      // 5. Sync Withdrawals
      final wds = await _api.getWithdrawals();
      if (wds != null && wds.isNotEmpty) {
        final mappedWds = wds.map((w) {
          final bank = w['bankAccount'] as Map<String, dynamic>?;
          final bankAccNumber = bank?['accountNumber']?.toString();
          final maskedAcc = (bankAccNumber != null && bankAccNumber.length >= 4)
              ? '•••• ${bankAccNumber.substring(bankAccNumber.length - 4)}'
              : '•••• 4829';

          return WithdrawalModel(
            id: w['id'] as String,
            amount: (w['amount'] as num?)?.toDouble() ?? 0.0,
            bankName: bank?['bankName'] as String? ?? 'Bank Account',
            accountNumber: maskedAcc,
            requestDate: w['requestedAt'] != null
                ? DateTime.parse(w['requestedAt'])
                : DateTime.now(),
            status: w['status'] == 'COMPLETED'
                ? 'Completed'
                : w['status'] == 'REJECTED'
                ? 'Rejected'
                : 'Processing',
            referenceId:
                w['withdrawalReference'] as String? ?? w['id'] as String,
          );
        }).toList();

        withdrawals.assignAll(mappedWds);
      }

      // 6. Sync Transactions
      final txns = await _api.getTransactions();
      if (txns != null && txns.isNotEmpty) {
        final mappedTxns = txns.map((t) {
          final typeStr = t['type'] as String? ?? '';
          TransactionType type = TransactionType.investment;
          if (typeStr.contains('RETURN')) {
            type = TransactionType.returnReceived;
          } else if (typeStr.contains('WITHDRAWAL')) {
            type = TransactionType.withdrawal;
          } else if (typeStr.contains('DEPOSIT')) {
            type = TransactionType.deposit;
          }

          return TransactionModel(
            id: t['id'] as String,
            type: type,
            title: type == TransactionType.investment
                ? 'Investment'
                : type == TransactionType.returnReceived
                ? 'Return Received'
                : 'Withdrawal',
            subtitle: t['description'] as String? ?? 'Transaction',
            amount: (t['amount'] as num?)?.toDouble() ?? 0.0,
            date: t['createdAt'] != null
                ? DateTime.parse(t['createdAt'])
                : DateTime.now(),
            status: t['status'] == 'COMPLETED' ? 'Completed' : 'Processing',
            referenceId:
                t['transactionReference'] as String? ?? t['id'] as String,
          );
        }).toList();

        transactions.assignAll(mappedTxns);
      }
    } catch (e) {
      debugPrint('[DemoRepository] syncFromBackend error: $e');
    }
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
    if (_writing)
      throw StateError('Another update is in progress. Please retry.');
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

    // 1. Try Backend API
    if (_api != null) {
      try {
        final token = await _api.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final res = await _api.createInvestment(
            projectId: project.id,
            amount: amount,
            paymentMethod: paymentMethod.contains('UPI')
                ? 'UPI'
                : 'BANK_TRANSFER',
          );
          if (res != null) {
            await syncFromBackend();
            _notificationService.addNotification(
              type: NotificationType.investmentSuccess,
              title: 'Investment Successful 🎉',
              description:
                  'Investment of ₹${amount.toStringAsFixed(0)} in ${project.name} confirmed.',
              relatedId: res['id'] as String?,
            );
            return investments.firstWhere(
              (inv) => inv.id == res['id'],
              orElse: () => _record(
                res['id'] as String,
                project,
                amount,
                DateTime.now(),
                method: paymentMethod,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint(
          '[DemoRepository] createInvestment backend sync fallback: $e',
        );
      }
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
  }) async {
    if (!bankSelected ||
        !amount.isFinite ||
        minor(amount) < minor(AppConstants.minWithdrawalAmount) ||
        minor(amount) > minor(availableBalance.value)) {
      return false;
    }

    // 1. Try Backend API
    if (_api != null) {
      try {
        final token = await _api.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final res = await _api.createWithdrawal(amount: amount);
          if (res != null) {
            await syncFromBackend();
            _notificationService.addNotification(
              type: NotificationType.withdrawalApproved,
              title: 'Withdrawal Submitted',
              description:
                  'Your withdrawal request of ₹${amount.toStringAsFixed(0)} has been submitted.',
              relatedId: res['id'] as String?,
            );
            return true;
          }
        }
      } catch (e) {
        debugPrint(
          '[DemoRepository] requestWithdrawal backend sync fallback: $e',
        );
      }
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
    if (_api != null) {
      try {
        final token = await _api.getAccessToken();
        if (token != null && token.isNotEmpty) {
          await _api.updateProfile(
            fullName: fullName,
            mobileNumber: mobileNumber,
          );
        }
      } catch (e) {
        debugPrint('[DemoRepository] updateProfile backend error: $e');
      }
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
