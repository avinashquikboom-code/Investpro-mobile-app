import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/utils/currency_formatter.dart';
import 'package:investpro/app/models/wallet_model.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/models/subscription_plan_model.dart';
import 'package:investpro/app/widgets/recent_activity_item.dart';

void main() {
  test('hourly rate has four decimals while posted wallet amounts keep two', () {
    const raw = '0.69444444444444444444';
    expect(CurrencyFormatter.formatHourlyRate(raw), '₹0.6944');
    expect(CurrencyFormatter.formatHourlyRate('0.7'), '₹0.7000');
    expect(CurrencyFormatter.formatHourlyRate(0), '₹0.0000');
    expect(CurrencyFormatter.format('0.69'), '₹0.69');
    expect(CurrencyFormatter.format('0.70'), '₹0.70');
    expect(raw, '0.69444444444444444444');
  });
  test('currency always shows two decimals with Indian grouping and safe nulls', () {
    for (final entry in <Object?, String>{null: '₹0.00', 0: '₹0.00', 250: '₹250.00', 2000: '₹2,000.00', 125.5: '₹125.50', '1234567.89': '₹12,34,567.89', 'invalid': '₹0.00', double.nan: '₹0.00'}.entries) {
      expect(CurrencyFormatter.format(entry.key), entry.value);
      expect(CurrencyFormatter.format(entry.key, showDecimals: false), entry.value);
      expect(CurrencyFormatter.formatCompact(entry.key), entry.value);
      expect(CurrencyFormatter.formatPrecise(entry.key, decimalDigits: 4), entry.value);
    }
  });
  test('formatting does not change the original calculation input', () {
    const original = 125.56789;
    expect(CurrencyFormatter.format(original), '₹125.57');
    expect(original, 125.56789);
    expect(CurrencyFormatter.number('125.56789'), original);
    expect(CurrencyFormatter.parse('₹2,000.75'), 2000.75);
  });
  test('exact wallet paise retain cents including whole amounts and large values', () {
    expect(formatWalletMoney(moneyPaise('250')), '₹250.00');
    expect(formatWalletMoney(moneyPaise('125.50')), '₹125.50');
    expect(formatWalletMoney(moneyPaise('90071992547409.93')), '₹9,00,71,99,25,47,409.93');
  });
  test('project and subscription decimal-string API fields keep fractional values', () {
    final project = ProjectModel.fromBackend({'id': 'project', 'minInvestment': '2000.75', 'expectedRoi': '5.25', 'fundingProgress': '92.00'});
    expect(project.minInvestment, 2000.75);
    expect(project.returnRatePercent, 5.25);
    expect(project.progressPercentage, 92);
    final plan = SubscriptionPlanModel.fromJson({'price': '125.50', 'minInvestment': '2000.75', 'maxInvestment': '100000.99'});
    expect(plan.price, 125.5);
    expect(plan.formattedPrice, '₹125.50');
    final eligibility = SubscriptionEligibilityModel.fromJson({'plan': {'minInvestment': '2000.75', 'maxInvestment': '100000.99'}});
    expect(eligibility.minInvestment, 2000.75);
    expect(eligibility.maxInvestment, 100000.99);
  });
  for (final amount in [0.0, 125.5, 2000.0]) {
    testWidgets('recent activity renders exact two-decimal credit $amount', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final transaction = TransactionModel(id: 'transaction', type: TransactionType.returnReceived, title: 'Interest payout', subtitle: 'Project', amount: amount, date: DateTime(2026, 11, 1), referenceId: 'REF', direction: 'CREDIT');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RecentActivityItem(transaction: transaction))));
      expect(find.text('+ ${CurrencyFormatter.format(amount)}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
