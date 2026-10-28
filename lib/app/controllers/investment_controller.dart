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
  String? get amountError {
    final format = Validators.validateInvestmentAmount(
      amountTextController.text,
    );
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
    amountTextController.dispose();
    super.onClose();
  }

  void setProject(ProjectModel project) {
    if (isProcessingPayment.value) return;
    currentProject.value = project;
    lastSuccessfulInvestment.value = null;
    agreeToTerms.value = false;
    paymentError.value = '';
    _requestId = _repo.newReference('DEMO');
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
      returnRatePercent: proj.returnRatePercent,
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
          amountError ?? 'Accept the demo investment terms to continue.';
      return false;
    }
    isProcessingPayment.value = true;
    paymentError.value = '';
    try {
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
}
