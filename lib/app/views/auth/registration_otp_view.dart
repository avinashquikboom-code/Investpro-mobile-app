import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../services/payment_error.dart';
import '../../theme/app_colors.dart';

class RegistrationOtpView extends StatefulWidget {
  final String fullName, email, mobileNumber, password;
  const RegistrationOtpView({super.key, required this.fullName, required this.email, required this.mobileNumber, required this.password});
  @override
  State<RegistrationOtpView> createState() => _RegistrationOtpViewState();
}
class _RegistrationOtpViewState extends State<RegistrationOtpView> {
  final code = TextEditingController();
  int cooldown = 60;
  bool resending = false;
  String? error;
  Timer? timer;
  @override
  void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted && cooldown > 0) setState(() => cooldown--); }); }
  @override
  void dispose() { timer?.cancel(); code.dispose(); super.dispose(); }
  Future<void> resend() async {
    if (resending || cooldown > 0) return;
    setState(() { resending = true; error = null; });
    try { final result = await Get.find<ApiService>().sendRegistrationOtp(fullName: widget.fullName, email: widget.email, mobileNumber: widget.mobileNumber); if (mounted) setState(() => cooldown = (result['data']?['cooldownSeconds'] as num? ?? 60).toInt()); }
    catch (e) { if (mounted) setState(() => error = PaymentError.message(e)); }
    finally { if (mounted) setState(() => resending = false); }
  }
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() => PopScope(canPop: !auth.isLoading.value, child: Scaffold(appBar: AppBar(title: const Text('Verify Mobile Number')), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Enter the OTP sent to ${widget.mobileNumber}'),
      const SizedBox(height: 20),
      TextField(controller: code, enabled: !auth.isLoading.value, keyboardType: TextInputType.number, autofillHints: const [AutofillHints.oneTimeCode], inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)], decoration: const InputDecoration(labelText: 'Mobile OTP')),
      if (error != null) Text(error!, style: const TextStyle(color: AppColors.error)),
      const SizedBox(height: 20),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary), onPressed: auth.isLoading.value ? null : () { if (!RegExp(r'^\d{6}$').hasMatch(code.text)) { setState(() => error = 'Enter the six-digit OTP.'); return; } auth.verifyRegistration(fullName: widget.fullName, email: widget.email, mobileNumber: widget.mobileNumber, password: widget.password, otp: code.text); }, child: Text(auth.isLoading.value ? 'Verifying…' : 'Verify & Continue')),
      TextButton(onPressed: auth.isLoading.value || resending || cooldown > 0 ? null : resend, child: Text(cooldown > 0 ? 'Resend OTP in ${cooldown}s' : 'Resend OTP')),
    ]))))))));
  }
}
