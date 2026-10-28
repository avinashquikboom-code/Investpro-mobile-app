import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/services/investment_calculator.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/project_controller.dart';
import 'package:investpro/app/controllers/transaction_controller.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/controllers/theme_controller.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/utils/validators.dart';

class MemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  bool fail = false;
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    if (fail) throw StateError('Simulated disk full');
    values[key] = jsonDecode(jsonEncode(value));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryStore memory;
  late LocalStorageService storage;
  late NotificationService notifications;
  late DemoRepository repo;
  setUp(() async {
    Get.testMode = true;
    memory = MemoryStore();
    storage = await LocalStorageService(backend: memory).init();
    notifications = await NotificationService(storage).init();
    repo = await DemoRepository(storage, notifications).init();
  });
  tearDown(() => Get.reset());
  test('initial totals reconcile with active investments and wallet', () {
    expect(repo.totalInvested, 70000);
    expect(repo.totalReturns, 15000);
    expect(repo.availableBalance.value, 15000);
    expect(repo.totalPortfolioValue, 85000);
    expect(repo.totalActiveProjects, 3);
  });
  test(
    'investment commits funding, ledger and the entire exact schedule',
    () async {
      final p = repo.projects.first;
      final raised = p.raisedAmount;
      final i = await repo.createInvestment(
        project: p,
        amount: 10000.01,
        paymentMethod: 'Demo UPI',
        requestId: 'test-1',
      );
      expect(repo.totalInvested, 80000.01);
      expect(repo.totalPortfolioValue, 95000.01);
      expect(repo.liveProject(p).raisedAmount, raised + 10000.01);
      final schedule = repo.returns.where((r) => r.investmentId == i.id);
      expect(schedule.length, p.durationMonths);
      expect(
        schedule.fold<int>(0, (s, r) => s + (r.amount * 100).round()),
        (i.expectedReturn * 100).round(),
      );
      expect(schedule.every((r) => r.status == 'Pending'), isTrue);
      expect(repo.transactions.where((t) => t.referenceId == i.id).length, 1);
      expect(notifications.notifications.first.relatedId, i.id);
      final restored = await DemoRepository(storage, notifications).init();
      expect(restored.totalInvested, repo.totalInvested);
      expect(
        restored.projects.first.raisedAmount,
        repo.projects.first.raisedAmount,
      );
    },
  );
  test('same payment reference is idempotent', () async {
    final p = repo.projects.first;
    await repo.createInvestment(
      project: p,
      amount: 10000,
      paymentMethod: 'Demo UPI',
      requestId: 'repeat',
    );
    await repo.createInvestment(
      project: p,
      amount: 10000,
      paymentMethod: 'Demo UPI',
      requestId: 'repeat',
    );
    expect(repo.investments.where((i) => i.id == 'repeat').length, 1);
    expect(repo.totalInvested, 80000);
  });
  test(
    'failed persistence leaves all in-memory financial data unchanged',
    () async {
      memory.fail = true;
      await expectLater(
        repo.createInvestment(
          project: repo.projects.first,
          amount: 10000,
          paymentMethod: 'Demo UPI',
        ),
        throwsStateError,
      );
      expect(repo.totalInvested, 70000);
      expect(repo.investments.length, 4);
    },
  );
  test('funding and project status enforced by repository', () async {
    final p = repo.projects.first;
    repo.projects[0] = p.copyWith(raisedAmount: p.targetAmount - 1000);
    expect(repo.investmentError(p, 5000), isNotNull);
    repo.projects[0] = p.copyWith(status: 'Completed');
    expect(repo.investmentError(p, 5000), isNotNull);
  });
  test('withdrawals require bank and reserve only available funds', () async {
    expect(await repo.requestWithdrawal(amount: 5000), isFalse);
    expect(
      await repo.requestWithdrawal(amount: 16000, bankSelected: true),
      isFalse,
    );
    expect(
      await repo.requestWithdrawal(amount: 5000, bankSelected: true),
      isTrue,
    );
    expect(repo.availableBalance.value, 10000);
    expect(repo.totalPortfolioValue, 80000);
    expect(repo.withdrawals.single.status, 'Processing');
    expect(repo.transactions.first.type, TransactionType.withdrawal);
    final restored = await DemoRepository(storage, notifications).init();
    expect(restored.availableBalance.value, 10000);
  });
  test('quick amount selection and project selection reset checkout', () {
    final c = Get.put(InvestmentController(repo));
    c.setProject(repo.projects.first);
    c.selectQuickAmount(25000);
    expect(c.investmentAmount.value, 25000);
    expect(c.amountTextController.text, '25000');
    c.agreeToTerms.value = true;
    c.setProject(repo.projects.last);
    expect(c.agreeToTerms.value, isFalse);
    c.amountTextController.text = 'NaN';
    expect(c.amountError, isNotNull);
  });
  test('project search and filters use actual status', () {
    final c = ProjectController(repo);
    c.setFilter('Completed');
    expect(c.filteredProjects, isEmpty);
    c.setFilter('Active');
    c.setSearchQuery('automation');
    expect(c.filteredProjects.single.id, 'proj_03');
  });
  test('transactions filter and sort newest first', () async {
    await repo.requestWithdrawal(amount: 5000, bankSelected: true);
    final c = TransactionController(repo)..setFilter('Withdrawal');
    expect(c.filteredTransactions.single.status, 'Processing');
    c.setFilter('All');
    expect(c.filteredTransactions.first.type, TransactionType.withdrawal);
  });
  test(
    'period aggregation preserves sums; no date promotes pending returns',
    () {
      final c = ReturnsController(repo);
      for (final period in ['Monthly', 'Quarterly', 'Yearly']) {
        c.setPeriod(period);
        expect(
          c.filteredReturns.fold<int>(
            0,
            (s, r) => s + (r.amount * 100).round(),
          ),
          repo.returns.fold<int>(0, (s, r) => s + (r.amount * 100).round()),
        );
      }
      expect(
        repo.returns
            .where((r) => r.investmentId != 'DEMO-HISTORY')
            .every((r) => r.status == 'Pending'),
        isTrue,
      );
    },
  );
  test(
    'notification reads persist; disabled notifications suppress additions',
    () async {
      final id = notifications.notifications.first.id;
      notifications.markAsRead(id);
      await Future<void>.delayed(Duration.zero);
      final restored = await NotificationService(storage).init();
      expect(
        restored.notifications.firstWhere((n) => n.id == id).isRead,
        isTrue,
      );
      restored.markAllAsRead();
      expect(restored.unreadCount, 0);
      await storage.setNotificationsEnabled(false);
      final count = notifications.notifications.length;
      await repo.createInvestment(
        project: repo.projects.first,
        amount: 5000,
        paymentMethod: 'Demo UPI',
      );
      expect(notifications.notifications.length, count);
    },
  );
  test('manual theme selection survives controller recreation', () async {
    final c = Get.put(ThemeController(storage));
    c.setThemeMode('dark');
    await Future<void>.delayed(Duration.zero);
    Get.delete<ThemeController>();
    final restored = Get.put(ThemeController(storage));
    expect(restored.currentThemeMode, ThemeMode.dark);
  });
  test('validators reject malformed phones, weak passwords and sub-paise', () {
    expect(Validators.validateMobile('abcdefghij'), isNotNull);
    expect(Validators.validatePassword('abcdefgh'), isNotNull);
    expect(Validators.validateEmail('a@b.technology'), isNull);
    for (final value in ['NaN', 'Infinity', '1e5', '10000.001', '-10000']) {
      expect(Validators.validateInvestmentAmount(value), isNotNull);
    }
  });
  test('month end dates clamp without overflow', () {
    expect(
      InvestmentCalculator.addMonths(DateTime(2026, 1, 31), 1),
      DateTime(2026, 2, 28),
    );
    expect(
      InvestmentCalculator.calculate(
        principal: 50000.01,
        returnRatePercent: 18,
        durationMonths: 12,
      ).expectedTotalReturn,
      9000,
    );
  });
}
