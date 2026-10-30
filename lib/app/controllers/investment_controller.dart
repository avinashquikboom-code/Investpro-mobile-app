import '../services/payment_error.dart';
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

class InvestmentController extends GetxController with WidgetsBindingObserver {
  final Razorpay Function() _checkoutFactory;
  final DemoRepository _repo;
  bool get isLive => _repo.isLive;

  InvestmentController(this._repo,{Razorpay Function()? checkoutFactory}) : _checkoutFactory=checkoutFactory??Razorpay.new { if (_repo.isLive) myInvestmentsFilter.value = 'All'; }

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
    if(isLive)WidgetsBinding.instance.addObserver(this);
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
        if (_pendingId != null && !isProcessingPayment.value) { _pendingId = null; _requestId = _repo.newReference('INV'); }
        investmentAmount.value = parsed;
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
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

  InvestmentModel? get currentInvestment {
    final selected = selectedInvestment.value;
    final arguments = Get.arguments;
    final id = arguments is Map ? arguments['investmentId']?.toString() ?? selected?.id : selected?.id;
    return _repo.investments.where((record) => record.id == id).firstOrNull ?? (isLive ? null : selected);
  }
  List<InvestmentModel> get filteredInvestments {
    return _repo.investments
        .where(
          (inv) =>
              myInvestmentsFilter.value == 'All' || inv.status.toLowerCase() ==
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
      paymentError.value = PaymentError.message(e);
      return false;
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<bool> _acceptVerified(Map<String,dynamic> verified) async {
    if(!['ACTIVE','MATURED'].contains(verified['status'])||verified['paymentVerified']!=true) return false;
    if(lastSuccessfulInvestment.value?.id==verified['id'])return true;
    final record=BackendSnapshot.investment(verified);
    lastSuccessfulInvestment.value=record;
    _repo.investments.removeWhere((item)=>item.id==record.id);
    _repo.investments.insert(0,record);
    // A refresh failure must not turn a confirmed captured payment into a failed payment.
    try {await _repo.syncFromBackend();} catch(_) {}
    try {await _repo.clearPaymentRequest(currentProject.value!,record.investedAmount);}catch(_) {}
    if(!isClosed)Get.offNamedUntil(AppRoutes.investmentSuccess,(route)=>route.settings.name==AppRoutes.home);
    return true;
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state==AppLifecycleState.resumed&&_pendingId!=null&&_payment?.isCompleted==false){unawaited(_recoverCaptured());}
  }
  Future<void> _recoverCaptured() async {
    final completion=_payment;
    try {
      final result=await Get.find<ApiService>().object('/mobile/investments/$_pendingId');
      if(isClosed||completion!=_payment||completion?.isCompleted!=false)return;
      if(await _acceptVerified(result)){if(completion?.isCompleted==false)completion!.complete(true);}
    } catch(_) { /* Checkout callback or the next safe retry can reconcile later. */ }
  }
  Future<bool> _payVerified() async {
    final api=Get.find<ApiService>();
    if(_pendingId==null){
      _requestId=await _repo.paymentRequestId(currentProject.value!,investmentAmount.value);
      final pending=await _repo.createInvestment(project:currentProject.value!,amount:investmentAmount.value,paymentMethod:'UPI',requestId:_requestId);
      _pendingId=pending.id;
    }
    final investmentId=_pendingId!;
    final current=await api.object('/mobile/investments/$investmentId');
    if(await _acceptVerified(current))return true;
    if(current['status']!='PENDING_PAYMENT')throw const PaymentFailure('This investment is not awaiting payment. Refresh your investment history.');
    final order=await api.paymentOrder(investmentId);
    final amount=order['amount'];
    if(order['investmentId']!=investmentId||order['orderId'] is! String||!(order['orderId'] as String).startsWith('order_')||order['keyId'] is! String||!RegExp(r'^rzp_(test|live)_').hasMatch(order['keyId'] as String)||amount is! int||amount<=0||amount!=DemoRepository.minor((current['amount'] as num).toDouble())||order['currency']!='INR')throw const PaymentFailure('The payment order is invalid. Please retry or contact support.');
    final completion=Completer<bool>();_payment=completion;
    _checkout?.clear();_checkout=_checkoutFactory();
    var verifying=false;
    bool inactive()=>isClosed||completion.isCompleted||_payment!=completion;
    _checkout!.on(Razorpay.EVENT_PAYMENT_SUCCESS,(PaymentSuccessResponse response)async{
      if(inactive()||verifying)return;verifying=true;
      try {
        if(response.orderId!=order['orderId']||response.paymentId==null||response.paymentId!.isEmpty||response.signature==null||!RegExp(r'^[a-f0-9]{64}$',caseSensitive:false).hasMatch(response.signature!))throw const PaymentFailure('Checkout returned incomplete payment details. Refresh your investment history.');
        final verified=await api.verifyPayment({'investmentId':investmentId,'orderId':response.orderId,'paymentId':response.paymentId,'signature':response.signature});
        if(inactive())return;
        if(!await _acceptVerified(verified))throw const PaymentFailure('Payment verification is pending. Refresh your investments before retrying.');
        if(!completion.isCompleted)completion.complete(true);
      } catch(error) {
        if(!inactive()){paymentError.value=PaymentError.message(error,fallback:'Payment verification is pending. Refresh your investments before retrying.');completion.complete(false);}
      }
    });
    _checkout!.on(Razorpay.EVENT_PAYMENT_ERROR,(PaymentFailureResponse response){
      if(inactive()||verifying)return;
      paymentError.value='Checkout was cancelled or unsuccessful. Your investment remains pending; you can retry safely.';
      completion.complete(false);
    });
    _checkout!.on(Razorpay.EVENT_EXTERNAL_WALLET,(ExternalWalletResponse response){
      if(inactive()||verifying)return;
      paymentError.value='External wallet selected. Return to the app and refresh your investment before retrying.';
      completion.complete(false);
    });
    try {_checkout!.open({'key':order['keyId'],'order_id':order['orderId'],'amount':amount,'currency':'INR','name':'InvestPro'});}
    catch(_){if(!completion.isCompleted)completion.complete(false);throw const PaymentFailure('Unable to open secure checkout. Please retry.');}
    try{return await completion.future;}finally{_checkout?.clear();}
  }
}
