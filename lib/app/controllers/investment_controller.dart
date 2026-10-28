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
  final TextEditingController amountTextController = TextEditingController(text: '5000');
  final RxString selectedPaymentMethod = 'UPI (Google Pay / PhonePe)'.obs;
  final RxBool agreeToTerms = true.obs;
  final RxBool isProcessingPayment = false.obs;

  // Selected Records
  final Rxn<ProjectModel> currentProject = Rxn<ProjectModel>();
  final Rxn<InvestmentModel> lastSuccessfulInvestment = Rxn<InvestmentModel>();
  final Rxn<InvestmentModel> selectedInvestment = Rxn<InvestmentModel>();

  // My Investments List Filters
  final RxString myInvestmentsFilter = 'Active'.obs; // 'Active', 'Completed', 'Withdrawn'

  @override
  void onInit() {
    super.onInit();
    amountTextController.addListener(() {
      final parsed = double.tryParse(
            amountTextController.text.replaceAll('₹', '').replaceAll(',', '').trim(),
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
    currentProject.value = project;
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
        .where((inv) => inv.status.toLowerCase() == myInvestmentsFilter.value.toLowerCase())
        .toList();
  }

  Future<void> proceedToPaymentConfirmation() async {
    final error = Validators.validateInvestmentAmount(amountTextController.text);
    if (error != null) {
      Get.snackbar('Invalid Amount', error, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (currentProject.value == null) {
      Get.snackbar('Error', 'Please select a project to invest in.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.toNamed(AppRoutes.paymentConfirmation);
  }

  Future<bool> confirmAndPay() async {
    if (!agreeToTerms.value) {
      Get.snackbar('Terms Required', 'Please accept the investment terms to proceed.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isProcessingPayment.value = true;
    await Future.delayed(const Duration(milliseconds: 1400)); // Simulate gateway
    isProcessingPayment.value = false;

    final proj = currentProject.value;
    if (proj == null) return false;

    // Create investment record in repository
    final newInv = _repo.createInvestment(
      project: proj,
      amount: investmentAmount.value,
      paymentMethod: selectedPaymentMethod.value,
    );

    lastSuccessfulInvestment.value = newInv;
    Get.offNamed(AppRoutes.investmentSuccess);
    return true;
  }
}
