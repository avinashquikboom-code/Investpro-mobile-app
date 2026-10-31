import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/subscription_plan_model.dart';
import '../services/api_service.dart';
import '../services/payment_error.dart';
import 'project_controller.dart';

class SubscriptionController extends GetxController with WidgetsBindingObserver {
  final ApiService api;
  final Razorpay Function() checkoutFactory;
  final Future<String?> Function(String) readIntent;
  final Future<void> Function(String, String) writeIntent;
  SubscriptionController(this.api, {Razorpay Function()? checkoutFactory, Future<String?> Function(String)? readIntent, Future<void> Function(String, String)? writeIntent})
    : checkoutFactory = checkoutFactory ?? Razorpay.new,
      readIntent = readIntent ?? ((key) => const FlutterSecureStorage().read(key: key)),
      writeIntent = writeIntent ?? ((key, value) => const FlutterSecureStorage().write(key: key, value: value));
  final plans = <SubscriptionPlanModel>[].obs;
  final current = Rxn<Map<String, dynamic>>();
  final loading = false.obs, purchasing = false.obs;
  final error = ''.obs;
  Razorpay? _checkout;
  Completer<bool>? _completion;
  String? _pendingId;
  int _request = 0;
  bool get hasActivePlan => current.value?['status'] == 'ACTIVE' && DateTime.tryParse('${current.value?['endDate']}')?.isAfter(DateTime.now()) == true;
  @override
  void onInit() { super.onInit(); WidgetsBinding.instance.addObserver(this); }
  @override
  void onClose() { WidgetsBinding.instance.removeObserver(this); _checkout?.clear(); if (_completion?.isCompleted == false) _completion!.complete(false); super.onClose(); }
  Future<void> load() async {
    if (purchasing.value) return;
    final request = ++_request, session = api.sessionVersion;
    loading.value = true; error.value = '';
    try {
      final result = await Future.wait([api.getSubscriptionPlans(), api.getCurrentSubscription()]);
      if (isClosed || request != _request || session != api.sessionVersion) return;
      plans.assignAll((result[0] as List<Map<String, dynamic>>).map(SubscriptionPlanModel.fromJson).where((p) => p.isActive && p.price >= 1 && p.durationMonths > 0));
      current.value = result[1] as Map<String, dynamic>?;
    } catch (e) { if (!isClosed && request == _request) { plans.clear(); error.value = PaymentError.message(e, fallback: 'Unable to load subscription plans. You can retry or skip.'); } }
    finally { if (!isClosed && request == _request) loading.value = false; }
  }
  void clearForSession() { _request++; plans.clear(); current.value = null; error.value = ''; _pendingId = null; if (_completion?.isCompleted == false) _completion!.complete(false); _completion = null; _checkout?.clear(); purchasing.value = false; }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed && purchasing.value) unawaited(_recover()); }
  Future<bool> _recover() async {
    if (_pendingId == null) return false;
    final expected = _pendingId, session = api.sessionVersion;
    try { final active = await api.getCurrentSubscription(); if (session == api.sessionVersion && expected == _pendingId && active?['id'] == expected && active?['status'] == 'ACTIVE') { current.value = active; if (_completion?.isCompleted == false) _completion!.complete(true); return true; } } catch (_) {}
    return false;
  }
  Future<bool> purchase(SubscriptionPlanModel plan) async {
    if (purchasing.value || !plan.isActive) return false;
    _request++; loading.value = false; purchasing.value = true; error.value = '';
    final session = api.sessionVersion;
    final completion = Completer<bool>(); _completion = completion;
    try {
      final me = await api.getMe();
      if (me?['role'] != 'INVESTOR') throw const PaymentFailure('An authenticated investor account is required');
      final slot = 'subscription_intent_${me!['id']}_${plan.id}_${plan.price}_${current.value?['id'] ?? 'none'}';
      var intent = await readIntent(slot); intent ??= base64Url.encode(List.generate(24, (_) => Random.secure().nextInt(256))); await writeIntent(slot, intent);
      final response = await api.purchaseSubscription(planId: plan.id, idempotencyKey: intent);
      final purchase = response['subscription'] as Map?;
      final gateway = response['gateway'] as Map?;
      if (purchase?['id'] is! String || gateway?['orderId'] is! String || !(gateway!['orderId'] as String).startsWith('order_') || gateway['keyId'] is! String || !RegExp(r'^rzp_(test|live)_').hasMatch(gateway['keyId']) || gateway['currency'] != 'INR' || gateway['amount'] is! int || gateway['amount'] != (plan.price * 100).round()) throw const PaymentFailure('Invalid subscription payment order. Refresh plans before retrying.');
      _pendingId = purchase!['id'].toString();
      if (session != api.sessionVersion || isClosed) return false;
      _checkout?.clear(); final checkout = checkoutFactory(); _checkout = checkout;
      bool stale() => completion.isCompleted || session != api.sessionVersion || isClosed;
      checkout.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse result) async {
        if (stale()) return;
        try {
          if (result.orderId != gateway['orderId'] || result.paymentId == null || result.signature == null) throw const PaymentFailure('Checkout returned incomplete payment details. Refresh My Plan.');
          final verified = await api.verifySubscriptionPayment({'subscriptionId': _pendingId, 'gatewayOrderId': result.orderId, 'gatewayPaymentId': result.paymentId, 'gatewaySignature': result.signature});
          final active = verified['subscription'];
          if (active is! Map || active['id'] != _pendingId || active['status'] != 'ACTIVE') throw const PaymentFailure('Subscription verification is pending. Refresh My Plan before retrying.');
          current.value = Map<String, dynamic>.from(active);
          if (!stale()) completion.complete(true);
        } catch (e) { if (!await _recover() && !stale()) { error.value = PaymentError.message(e); completion.complete(false); } }
      });
      checkout.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse _) async { if (!stale() && !await _recover()) { error.value = 'Payment was cancelled or unsuccessful. You can choose a plan again or skip.'; if (!stale()) completion.complete(false); } });
      checkout.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) { if (!stale()) { error.value = 'Return to My Plan to check payment before retrying. You can also skip for now.'; completion.complete(false); } });
      checkout.open({'key': gateway['keyId'], 'order_id': gateway['orderId'], 'amount': gateway['amount'], 'currency': 'INR', 'name': 'InvestPro', 'description': '${plan.name} Subscription'});
      final success = await completion.future;
      if (success && session == api.sessionVersion) {
        if (Get.isRegistered<ProjectController>()) {
          try { final projects = Get.find<ProjectController>(); await projects.loadSubscriptionEligibility(); await projects.refreshProjects(); } catch (_) {}
        }
      }
      return success;
    } catch (e) { if (!isClosed && session == api.sessionVersion) error.value = PaymentError.message(e); return false; }
    finally { if (_completion == completion) { _checkout?.clear(); _completion = null; purchasing.value = false; } }
  }
}
