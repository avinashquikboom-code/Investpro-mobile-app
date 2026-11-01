import '../utils/currency_formatter.dart';
import 'package:dio/dio.dart';
import '../services/backend_snapshot.dart';
import '../routes/app_routes.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/demo_repository.dart';
import '../utils/validators.dart';

class WithdrawalController extends GetxController with WidgetsBindingObserver {
  final DemoRepository _repo;

  WithdrawalController(this._repo);

  final RxString selectedFilter = 'All'.obs; // 'All', 'Withdrawals', 'Deposits'
  final TextEditingController amountController = TextEditingController();
  final RxBool bankSelected = true.obs;
  final RxString selectedBankId = ''.obs;
  String? _requestId;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingWallet = false.obs;
  final isLoadingHistory = false.obs;
  final historyError = ''.obs, walletError = ''.obs;
  final hasWalletData = false.obs;
  int _historyRequest = 0, _walletRequest = 0;
  Worker? _syncWorker, _resetWorker, _userWorker;
  String? _historyUser;

  Future<void> refreshData() async {
    await Future.wait([loadWalletData(), loadHistory()]);
  }

  Future<void> loadHistory() async {
    if (!isLive) return;
    if (!Get.isRegistered<ApiService>()) { historyError.value='Sign in again to load withdrawal requests.'; isLoadingHistory.value=false; return; }
    final api = Get.find<ApiService>(), request = ++_historyRequest;
    final session = api.sessionVersion, revision = _repo.applicationDataGeneration.value;
    final userId = _repo.currentUser.value.id;
    bool current() => !isClosed && request == _historyRequest && session == api.sessionVersion && revision == _repo.applicationDataGeneration.value && userId == _repo.currentUser.value.id;
    isLoadingHistory.value = true; historyError.value = '';
    final failures = <String>[];
    Future<void> withdrawals() async {
      try {
        final rows = await api.getWithdrawals();
        if (rows == null) throw StateError('Withdrawal history unavailable');
        final parsed = rows.map((row) {
          if (row is! Map || row['id'] is! String || (row['id'] as String).isEmpty) throw StateError('Invalid withdrawal response');
          return BackendSnapshot.withdrawal(Map<String,dynamic>.from(row));
        }).toList();
        if (current()) _repo.withdrawals.assignAll(parsed);
      } catch (error) { failures.add(_historyMessage(error, 'withdrawal requests')); }
    }
    Future<void> transactions() async {
      try {
        final rows = await api.getTransactions();
        if (rows == null) throw StateError('Transaction history unavailable');
        final parsed = rows.map((row) => BackendSnapshot.transaction(Map<String,dynamic>.from(row as Map))).toList();
        if (current()) _repo.transactions.assignAll(parsed);
      } catch (error) { failures.add(_historyMessage(error, 'transaction history')); }
    }
    try { await Future.wait([withdrawals(), transactions()]); }
    finally { if (current()) { historyError.value = failures.toSet().join(' '); isLoadingHistory.value = false; } }
  }

  String _historyMessage(Object error, String resource) {
    if (error is DioException && error.response?.statusCode == 401) return 'Your session expired. Sign in again.';
    if (error is DioException && error.response?.statusCode == 403) return 'This account cannot access $resource.';
    return 'Unable to load $resource. Please retry.';
  }


  // Authoritative limits & balance from backend
  final RxDouble backendAvailableBalance = 0.0.obs;
  final RxDouble backendReservedBalance = 0.0.obs;
  final RxDouble minimumWithdrawal = 100.0.obs;
  final Rx<double?> maximumWithdrawal = Rx<double?>(null);
  final RxDouble withdrawalFee = 0.0.obs;
  final RxList<Map<String, dynamic>> verifiedBanks = <Map<String, dynamic>>[].obs;
  final RxDouble netPayoutAmount = 0.0.obs;
  final RxString lastSubmittedReference = ''.obs;

  // Real-time Earnings & Live Accruals
  final RxDouble totalInvested = 0.0.obs;
  final RxDouble totalReturns = 0.0.obs;
  final RxDouble todayEarnings = 0.0.obs;
  final RxDouble totalWithdrawn = 0.0.obs;
  final RxDouble hourlyEarningRate = 0.0.obs;
  final RxDouble perMinuteEarningRate = 0.0.obs;
  final RxDouble perSecondEarningRate = 0.0.obs;
  final RxList<Map<String, dynamic>> activeInvestments = <Map<String, dynamic>>[].obs;
  final Rxn<DateTime> asOf = Rxn<DateTime>();
  final RxDouble liveAnimatedBalance = 0.0.obs;
  Timer? _tickerTimer;

  double get availableBalance =>
      _repo.isLive ? backendAvailableBalance.value : _repo.availableBalance.value;

  double get reservedBalance =>
      _repo.isLive ? backendReservedBalance.value : 0.0;

  bool get hasBankAccount =>
      verifiedBanks.isNotEmpty || _repo.currentUser.value.bankAccountId != null;

  bool get hasVerifiedBank =>
      verifiedBanks.any((b) => b['isVerified'] == true) ||
      (_repo.currentUser.value.bankAccountId != null &&
          _repo.currentUser.value.bankName.isNotEmpty);

  Map<String, dynamic>? get selectedBank {
    if (verifiedBanks.isEmpty) return null;
    if (selectedBankId.value.isNotEmpty) {
      final found = verifiedBanks.firstWhereOrNull((b) => b['id'] == selectedBankId.value);
      if (found != null) return found;
    }
    return verifiedBanks.firstWhereOrNull((b) => b['isPrimary'] == true && b['isVerified'] == true) ??
        verifiedBanks.firstWhereOrNull((b) => b['isVerified'] == true) ??
        verifiedBanks.first;
  }

  String get linkedBankName {
    final b = selectedBank;
    if (b != null && b['bankName'] != null && b['bankName'].toString().isNotEmpty) {
      return b['bankName'].toString();
    }
    return _repo.currentUser.value.bankName;
  }

  String get linkedAccountNumber {
    final b = selectedBank;
    if (b != null && b['accountNumber'] != null && b['accountNumber'].toString().isNotEmpty) {
      return b['accountNumber'].toString();
    }
    return _repo.currentUser.value.accountNumber;
  }

  bool get isLive => _repo.isLive;

  List<TransactionModel> get filteredTransactions {
    final txns = _repo.isLive
        ? [
            ..._repo.withdrawals.map(
              (request) => TransactionModel(
                id: request.id,
                type: TransactionType.withdrawal,
                title: 'Withdrawal request',
                subtitle: '${request.bankName} ${request.accountNumber}',
                amount: request.amount,
                date: request.requestDate,
                status: request.status,
                direction: 'DEBIT',
                referenceId: request.referenceId,
              ),
            ),
            ..._repo.transactions.where((record) => record.type != TransactionType.withdrawal),
          ]
        : _repo.transactions;

    switch (selectedFilter.value) {
      case 'Withdrawals':
        return txns.where((t) => t.type == TransactionType.withdrawal).toList();
      case 'Deposits':
        return txns.where((t) => t.type == TransactionType.deposit).toList();
      case 'Returns':
        return txns.where((t) => t.type == TransactionType.returnReceived).toList();
      case 'Investments':
        return txns.where((t) => t.type == TransactionType.investment).toList();
      case 'Refunds':
        return txns.where((t) => t.type == TransactionType.refund).toList();
      default:
        return txns;
    }
  }

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(_onAmountChanged);
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateLiveCounter());
    WidgetsBinding.instance.addObserver(this);
    _syncWorker = ever(_repo.isSyncing, (syncing) {
      if (!syncing && Get.currentRoute == AppRoutes.withdrawals) unawaited(refreshData());
    });
    _resetWorker = ever(_repo.applicationDataGeneration, (_) => clearForSession());
    _historyUser = _repo.currentUser.value.id;
    _userWorker = ever(_repo.currentUser, (user) {
      if (user.id == _historyUser) return;
      _historyUser = user.id; clearForSession();
    });
    loadWalletData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Get.currentRoute == AppRoutes.withdrawals) unawaited(refreshData());
  }

  void clearForSession() {
    _historyRequest++; _walletRequest++;
    isLoadingHistory.value = false; isLoadingWallet.value = false;
    historyError.value = ''; walletError.value = ''; hasWalletData.value=false;
    backendAvailableBalance.value = 0; backendReservedBalance.value = 0;
    totalInvested.value=0; totalReturns.value=0; todayEarnings.value=0; totalWithdrawn.value=0;
    hourlyEarningRate.value=0; perMinuteEarningRate.value=0; perSecondEarningRate.value=0;
    asOf.value=null; liveAnimatedBalance.value=0; activeInvestments.clear(); verifiedBanks.clear(); selectedBankId.value='';
    minimumWithdrawal.value=100; maximumWithdrawal.value=null; withdrawalFee.value=0;
    amountController.clear(); netPayoutAmount.value=0; lastSubmittedReference.value='';
    _requestId=null;
  }

  void _updateLiveCounter() {
    final asOfTime = asOf.value;
    final ratePerSec = perSecondEarningRate.value;
    if (asOfTime == null || ratePerSec <= 0) {
      liveAnimatedBalance.value = availableBalance;
      return;
    }
    final elapsedSec = DateTime.now().difference(asOfTime).inMilliseconds / 1000.0;
    if (elapsedSec > 0) {
      liveAnimatedBalance.value = availableBalance + (elapsedSec * ratePerSec);
    } else {
      liveAnimatedBalance.value = availableBalance;
    }
  }

  void _onAmountChanged() {
    final raw = amountController.text.replaceAll('₹', '').replaceAll(',', '').trim();
    final amt = double.tryParse(raw) ?? 0.0;
    final fee = withdrawalFee.value;
    if (amt <= 0) {
      netPayoutAmount.value = 0.0;
    } else {
      netPayoutAmount.value = (amt - fee).clamp(0.0, double.infinity);
    }
  }

  Future<void> loadWalletData() async {
    if (!_repo.isLive) {
      backendAvailableBalance.value = _repo.availableBalance.value;
      return;
    }
    if (!Get.isRegistered<ApiService>()) { walletError.value='Sign in again to load wallet details.'; isLoadingWallet.value=false; return; }
    final request = ++_walletRequest, revision = _repo.applicationDataGeneration.value;
    final userId = _repo.currentUser.value.id;
    final session = Get.isRegistered<ApiService>() ? Get.find<ApiService>().sessionVersion : -1;
    bool current() => !isClosed && request == _walletRequest && revision == _repo.applicationDataGeneration.value && Get.isRegistered<ApiService>() && session == Get.find<ApiService>().sessionVersion && userId == _repo.currentUser.value.id;
    try {
      isLoadingWallet.value = true; walletError.value = '';
      if (Get.isRegistered<ApiService>()) {
        final api = Get.find<ApiService>();
        final wallet = await api.getWallet();
        if (!current()) return;
        final balance=double.tryParse('${wallet['availableBalance']}'), reserved=double.tryParse('${wallet['reservedBalance']}');
        if (balance==null || !balance.isFinite || reserved==null || !reserved.isFinite) throw StateError('Invalid wallet balances');
        hasWalletData.value=true;
        backendAvailableBalance.value =
            double.tryParse(wallet['availableBalance']?.toString() ?? '0') ?? 0.0;
        backendReservedBalance.value =
            double.tryParse(wallet['reservedBalance']?.toString() ?? '0') ?? 0.0;
        minimumWithdrawal.value =
            double.tryParse(wallet['minimumWithdrawal']?.toString() ?? '100') ?? 100.0;

        if (wallet['maximumWithdrawal'] != null && wallet['maximumWithdrawal'].toString().isNotEmpty) {
          maximumWithdrawal.value =
              double.tryParse(wallet['maximumWithdrawal']?.toString() ?? '');
        } else {
          maximumWithdrawal.value = null;
        }

        withdrawalFee.value =
            double.tryParse(wallet['withdrawalFee']?.toString() ?? '0') ?? 0.0;

        totalInvested.value =
            double.tryParse(wallet['totalInvested']?.toString() ?? '0') ?? 0.0;
        totalReturns.value =
            double.tryParse(wallet['totalReturns']?.toString() ?? '0') ?? 0.0;
        todayEarnings.value =
            double.tryParse(wallet['todayEarnings']?.toString() ?? '0') ?? 0.0;
        totalWithdrawn.value =
            double.tryParse(wallet['totalWithdrawn']?.toString() ?? '0') ?? 0.0;
        hourlyEarningRate.value =
            double.tryParse(wallet['hourlyEarningRate']?.toString() ?? '0') ?? 0.0;
        perMinuteEarningRate.value =
            double.tryParse(wallet['perMinuteEarningRate']?.toString() ?? '0') ?? 0.0;
        perSecondEarningRate.value =
            double.tryParse(wallet['perSecondEarningRate']?.toString() ?? '0') ?? 0.0;

        if (wallet['asOf'] != null) {
          asOf.value = DateTime.tryParse(wallet['asOf'].toString());
        }

        if (wallet['activeInvestments'] is List) {
          final list = (wallet['activeInvestments'] as List)
              .map((i) => Map<String, dynamic>.from(i as Map))
              .toList();
          activeInvestments.assignAll(list);
        }

        _updateLiveCounter();

        if (wallet['banks'] is List) {
          final list = (wallet['banks'] as List)
              .map((b) => Map<String, dynamic>.from(b as Map))
              .toList();
          verifiedBanks.assignAll(list);

          final primary = list.firstWhereOrNull(
                (b) => b['isPrimary'] == true && b['isVerified'] == true,
              ) ??
              list.firstWhereOrNull((b) => b['isVerified'] == true) ??
              list.firstOrNull;

          if (primary != null) {
            selectedBankId.value = primary['id']?.toString() ?? '';
            bankSelected.value = true;
          }
        }
      }
    } catch (error) {
      if (current()) walletError.value = _historyMessage(error, 'wallet details');
    } finally {
      if (current()) isLoadingWallet.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void selectBank(String bankId) {
    selectedBankId.value = bankId;
    bankSelected.value = true;
  }

  Future<bool> submitWithdrawal() async {
    if (isSubmitting.value) return false;

    if (availableBalance <= 0) {
      Get.snackbar(
        'Zero Balance',
        'Available balance is ₹ 0.00. Capital returns or wallet deposits must be credited before requesting a withdrawal.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!hasVerifiedBank) {
      Get.snackbar(
        'Verified Bank Account Required',
        'Please link and verify a bank account from your Profile before withdrawing funds.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final error = Validators.validateWithdrawalAmount(
      amountController.text,
      availableBalance,
      minAmount: minimumWithdrawal.value,
      maxAmount: maximumWithdrawal.value,
    );
    if (error != null) {
      Get.snackbar(
        'Invalid Amount',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final amount = double.tryParse(
          amountController.text.replaceAll('₹', '').replaceAll(',', '').trim(),
        ) ??
        0.0;

    isSubmitting.value = true;
    try {
      _requestId ??= _repo.newReference('withdrawal');
      final targetBankId = selectedBankId.value.isNotEmpty
          ? selectedBankId.value
          : (_repo.currentUser.value.bankAccountId ?? '');

      if (_repo.isLive && Get.isRegistered<ApiService>()) {
        final api = Get.find<ApiService>();
        final result = await api.createWithdrawal(
          amount: amount,
          bankAccountId: targetBankId.isNotEmpty ? targetBankId : null,
          idempotencyKey: _requestId,
        );

        if (result != null) {
          final ref = result['withdrawalReference']?.toString() ??
              result['id']?.toString() ??
              _requestId!;
          lastSubmittedReference.value = ref;

          amountController.clear();
          _requestId = null;

          // Await fresh authoritative data from server
          await Future.wait([
            refreshData(),
            _repo.syncFromBackend().catchError((_) {}),
          ]);

          Get.snackbar(
            'Withdrawal request submitted successfully',
            'Reference: $ref\nStatus: Pending Admin Approval',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F8F0),
            colorText: const Color(0xFF006B3C),
            duration: const Duration(seconds: 5),
          );
          return true;
        } else {
          throw Exception('The server did not accept this withdrawal request');
        }
      } else {
        // Fallback local commit
        final success = await _repo.requestWithdrawal(
          amount: amount,
          bankSelected: true,
          requestId: _requestId,
        );
        if (success) {
          amountController.clear();
          _requestId = null;
          Get.snackbar(
            'Withdrawal request submitted successfully',
            'Your request of ${CurrencyFormatter.format(amount)} has been initiated.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F8F0),
            colorText: const Color(0xFF006B3C),
          );
          return true;
        } else {
          throw Exception('Unable to process withdrawal request');
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
      Get.snackbar(
        'Request Failed',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    _historyRequest++; _walletRequest++;
    _syncWorker?.dispose(); _resetWorker?.dispose(); _userWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    amountController.removeListener(_onAmountChanged);
    amountController.dispose();
    super.onClose();
  }
}
