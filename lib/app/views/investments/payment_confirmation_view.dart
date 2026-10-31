import 'offline_payment_form.dart';
import '../../services/api_service.dart';
import 'package:remixicon/remixicon.dart';
import '../../widgets/unsaved_changes_guard.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/investment_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class PaymentConfirmationView extends StatefulWidget {
  const PaymentConfirmationView({super.key});

  @override
  State<PaymentConfirmationView> createState() => _PaymentConfirmationViewState();
}
class _PaymentConfirmationViewState extends State<PaymentConfirmationView> {
  Map<String, dynamic>? settings;
  @override
  void initState() {
    super.initState();
    if (Get.find<InvestmentController>().isLive) {
      Get.find<ApiService>().object('/mobile/investments/offline-payment/settings').then((value) { if (mounted) setState(() => settings = value); }).catchError((Object _) {});
    }
  }
  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InvestmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paymentMethods = invCtrl.isLive ? [{'name': 'Razorpay Checkout', 'icon': Remix.lock_2_line}, if (settings?['enabled'] == true) {'name': 'Offline Payment', 'icon': Remix.bank_line}] : [
      {'name': 'Demo UPI', 'icon': Remix.qr_code_line},
      {'name': 'Demo Net Banking', 'icon': Remix.bank_line},
      {'name': 'Demo Card', 'icon': Remix.bank_card_line},
      {'name': 'Demo Wallet', 'icon': Remix.wallet_3_line},
    ];

    return UnsavedChangesGuard(
      controllers: [],
      changes: [
        invCtrl.selectedPaymentMethod.stream,
        invCtrl.agreeToTerms.stream,
      ],
      snapshot: () =>
          '${invCtrl.selectedPaymentMethod.value}|${invCtrl.agreeToTerms.value}',
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        appBar: CustomAppBar(title: 'confirmPayment'.tr),
        body: SafeArea(
          child: ResponsiveHelper.responsiveContainer(
            context: context,
            maxWidth: 600,
            child: Obx(() {
              final project = invCtrl.currentProject.value;
              if (project == null) {
                return const Center(child: Text('No project selected'));
              }

              final calc = invCtrl.calculationResult;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Investment Order Overview Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRow(
                            'amountInvested'.tr,
                            CurrencyFormatter.format(calc.principal),
                          ),
                          const SizedBox(height: 10),
                          _buildRow(
                            'expectedReturnTotal'.tr,
                            CurrencyFormatter.format(calc.expectedTotalReturn),
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 10),
                          _buildRow(
                            'maturityAmount'.tr,
                            CurrencyFormatter.format(
                              calc.projectedMaturityAmount,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildRow(
                            'investmentPeriod'.tr,
                            '${project.durationMonths} Months',
                          ),
                          const Divider(height: 24, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(
                                'Total Payable',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              )),
                              Flexible(child: Text(
                                CurrencyFormatter.format(calc.principal),
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Selection
                    Text(
                      'paymentMethod'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...paymentMethods.map((method) {
                      final name = method['name'] as String;
                      final icon = method['icon'] as IconData;
                      final isSelected =
                          invCtrl.selectedPaymentMethod.value == name;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.border),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                          leading: Icon(
                            icon,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          onTap: invCtrl.isProcessingPayment.value ? null : () => invCtrl.setPaymentMethod(name),
                        ),
                      ),
                    );
                  }),
                    const SizedBox(height: 16),

                    if (!invCtrl.isLive) const Text(
                      'DEMO PAYMENT • No real money is charged or card details collected.',
                    ),
                    if (!invCtrl.isLive) SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Simulate payment failure'),
                      value: invCtrl.simulateFailure.value,
                      onChanged: invCtrl.isProcessingPayment.value
                          ? null
                          : (v) => invCtrl.simulateFailure.value = v,
                    ),
                    if (invCtrl.paymentError.isNotEmpty)
                      Text(
                        invCtrl.paymentError.value,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    if (invCtrl.selectedPaymentMethod.value == 'Offline Payment' && settings != null)
                      OfflinePaymentForm(settings: settings!, controller: invCtrl),
                    if (invCtrl.selectedPaymentMethod.value != 'Offline Payment') ...[
                    // Terms & Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: invCtrl.agreeToTerms.value,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: invCtrl.isProcessingPayment.value
                                ? null
                                : invCtrl.toggleTerms,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'agreeTerms'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Confirm Payment Button
                    CustomButton(
                      text:
                          '${'confirmAndPay'.tr}  ${CurrencyFormatter.format(calc.principal)}',
                      isLoading: invCtrl.isProcessingPayment.value,
                      onPressed:
                          invCtrl.agreeToTerms.value &&
                              invCtrl.amountError == null
                          ? invCtrl.confirmAndPay
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        )),
        Flexible(child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        )),
      ],
    );
  }
}
