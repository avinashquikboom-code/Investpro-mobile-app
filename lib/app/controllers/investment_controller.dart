import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/backend_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/investment_model.dart';
import '../models/project_model.dart';
import '../routes/app_routes.dart';
import '../services/demo_repository.dart';
import '../services/investment_calculator.dart';
import '../utils/validators.dart';

class InvestmentController extends GetxController {
  final DemoRepository _repo;
  bool get isLive => _repo.isLive;

  InvestmentController(this._repo);

  // Form & Calculations State
  final RxDouble investmentAmount = 5000.0.obs;
  final TextEditingController amountTextController = TextEditingController(
    text: '5000',
  );
  final RxString selectedPaymentMethod = 'Demo UPI'.obs;
  final RxBool agreeToTerms = false.obs;
  final simulateFailure = false.obs;
  final paymentError = ''.obs;
  String _requestId = '';
  String? _pendingId;
  Razorpay? _checkout;
  Completer<bool>? _payment;
  String? get amountError {
    final format = _repo.isLive
        ? (Validators.amount(amountTextController.text.trim()) == null ? 'Enter an amount with at most two decimal places' : null)
        : Validators.validateInvestmentAmount(amountTextController.text);
    if (format != null) return format;
    final project = currentProject.value;
    return project == null
        ? 'Select a project'
        : _repo.investmentError(project, investmentAmount.value);
  }

  final RxBool isProcessingPayment = false.obs;

  // Selected Records
  final Rxn<ProjectModel> currentProject = Rxn<ProjectModel>();
  final Rxn<InvestmentModel> lastSuccessfulInvestment = Rxn<InvestmentModel>();
  final Rxn<InvestmentModel> selectedInvestment = Rxn<InvestmentModel>();

  // My Investments List Filters
  final RxString myInvestmentsFilter =
      'Active'.obs; // 'Active', 'Completed', 'Withdrawn'

  @override
  void onInit() {
    super.onInit();
    amountTextController.addListener(() {
      final parsed =
          double.tryParse(
            amountTextController.text
                .replaceAll('₹', '')
                .replaceAll(',', '')
                .trim(),
          ) ??
          0.0;
      if (parsed != investmentAmount.value) {
        investmentAmount.value = parsed;
      }
    });
  }

  @override
  void onClose() {
    _checkout?.clear();
    if (_payment?.isCompleted == false) _payment!.complete(false);
    amountTextController.dispose();
    super.onClose();
  }

  void setProject(ProjectModel project) {
    if (isProcessingPayment.value) return;
    currentProject.value = project;
    lastSuccessfulInvestment.value = null;
    agreeToTerms.value = false;
    paymentError.value = '';
    _requestId = _repo.newReference('INV');
    _pendingId = null;
    selectQuickAmount(10000);
  }

  void selectQuickAmount(double amount) {
    investmentAmount.value = amount;
    amountTextController.text = amount.toInt().toString();
  }

  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  void toggleTerms(bool? val) {
    agreeToTerms.value = val ?? false;
  }

  void setMyInvestmentsFilter(String filter) {
    myInvestmentsFilter.value = filter;
  }

  void selectInvestment(InvestmentModel investment) {
    selectedInvestment.value = investment;
  }

  InvestmentCalculationResult get calculationResult {
    final proj = currentProject.value;
    if (proj == null) {
      return const InvestmentCalculationResult(
        principal: 0,
        returnRatePercent: 0,
        durationMonths: 0,
        expectedTotalReturn: 0,
        projectedMaturityAmount: 0,
        monthlyProjectedReturn: 0,
      );
    }
    return InvestmentCalculator.calculate(
      principal: investmentAmount.value,
      returnRatePercent: _repo.isLive ? proj.returnRatePercent * proj.durationMonths / 12 : proj.returnRatePercent,
      durationMonths: proj.durationMonths,
    );
  }

  List<InvestmentModel> get filteredInvestments {
    return _repo.investments
        .where(
          (inv) =>
              inv.status.toLowerCase() ==
              myInvestmentsFilter.value.toLowerCase(),
        )
        .toList();
  }

  Future<void> proceedToPaymentConfirmation() async {
    final error = amountError;
    if (error != null) {
      Get.snackbar(
        'Invalid Amount',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (currentProject.value == null) {
      Get.snackbar(
        'Error',
        'Please select a project to invest in.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.toNamed(AppRoutes.paymentConfirmation);
  }

  Future<bool> confirmAndPay() async {
    if (isProcessingPayment.value || lastSuccessfulInvestment.value != null) {
      return false;
    }
    if (!agreeToTerms.value || amountError != null) {
      paymentError.value =
          amountError ?? 'Accept the investment terms to continue.';
      return false;
    }
    isProcessingPayment.value = true;
    paymentError.value = '';
    try {
      if (_repo.isLive) return await _payVerified();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (simulateFailure.value) {
        throw StateError(
          'Simulated payment declined. Disable failure simulation and retry.',
        );
      }
      final i = await _repo.createInvestment(
        project: currentProject.value!,
        amount: investmentAmount.value,
        paymentMethod: selectedPaymentMethod.value,
        requestId: _requestId,
      );
      lastSuccessfulInvestment.value = i;
      Get.offNamedUntil(
        AppRoutes.investmentSuccess,
        (route) => route.settings.name == AppRoutes.home,
      );
      return true;
    } catch (e) {
      paymentError.value = e.toString();
      return false;
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<bool> _payVerified() async {
    final api = Get.find<ApiService>();
    if (_pendingId == null) {
      final pending = await _repo.createInvestment(project: currentProject.value!,
        amount: investmentAmount.value, paymentMethod: 'UPI', requestId: _requestId);
      _pendingId = pending.id;
    }
    final order = await api.paymentOrder(_pendingId!);
    _payment = Completer<bool>();
    _checkout?.clear();
    _checkout = Razorpay();
    _checkout!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
      try {
        final verified = await api.verifyPayment({'investmentId': _pendingId,
          'orderId': response.orderId, 'paymentId': response.paymentId, 'signature': response.signature});
        if (verified['status'] != 'ACTIVE' || verified['paymentVerified'] != true) {
          throw StateError('Payment requires backend reconciliation. Check your investment history.');
        }
        lastSuccessfulInvestment.value = BackendSnapshot.investment(verified);
        await _repo.syncFromBackend();
        if (_payment?.isCompleted == false) _payment!.complete(true);
        Get.offNamedUntil(AppRoutes.investmentSuccess, (route) => route.settings.name == AppRoutes.home);
      } catch (_) {
        paymentError.value = 'Payment verification is pending. Refresh your investments before retrying.';
        if (_payment?.isCompleted == false) _payment!.complete(false);
      }
    });
    _checkout!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      paymentError.value = response.message ?? 'Checkout cancelled or unsuccessful. Your request remains pending.';
      if (_payment?.isCompleted == false) _payment!.complete(false);
    });
    _checkout!.open({'key': order['keyId'], 'order_id': order['orderId'],
      'amount': order['amount'], 'currency': order['currency'], 'name': 'InvestPro'});
    return _payment!.future;
  }
}
