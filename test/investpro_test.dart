import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/investment_calculator.dart';
import 'package:investpro/app/utils/currency_formatter.dart';
import 'package:investpro/app/utils/validators.dart';

void main() {
  group('InvestmentCalculator Tests', () {
    test('Calculates 18% return for 12 months correctly', () {
      final res = InvestmentCalculator.calculate(
        principal: 50000.0,
        returnRatePercent: 18.0,
        durationMonths: 12,
      );

      expect(res.principal, 50000.0);
      expect(res.expectedTotalReturn, 9000.0);
      expect(res.projectedMaturityAmount, 59000.0);
      expect(res.monthlyProjectedReturn, 750.0);
    });

    test('Calculates 15% return for 10 months correctly', () {
      final res = InvestmentCalculator.calculate(
        principal: 30000.0,
        returnRatePercent: 15.0,
        durationMonths: 10,
      );

      expect(res.principal, 30000.0);
      expect(res.expectedTotalReturn, 4500.0);
      expect(res.projectedMaturityAmount, 34500.0);
      expect(res.monthlyProjectedReturn, 450.0);
    });

    test('Calculates 12% return for 8 months correctly', () {
      final res = InvestmentCalculator.calculate(
        principal: 20000.0,
        returnRatePercent: 12.0,
        durationMonths: 8,
      );

      expect(res.principal, 20000.0);
      expect(res.expectedTotalReturn, 2400.0);
      expect(res.projectedMaturityAmount, 22400.0);
      expect(res.monthlyProjectedReturn, 300.0);
    });

    test('Handles zero and negative amounts safely', () {
      final res = InvestmentCalculator.calculate(
        principal: 0,
        returnRatePercent: 18,
        durationMonths: 12,
      );

      expect(res.expectedTotalReturn, 0.0);
      expect(res.projectedMaturityAmount, 0.0);
      expect(res.monthlyProjectedReturn, 0.0);
    });
  });

  group('CurrencyFormatter Tests', () {
    test('Formats Indian Rupee values with commas', () {
      expect(CurrencyFormatter.format(50000), '₹ 50,000');
      expect(CurrencyFormatter.format(85000), '₹ 85,000');
      expect(CurrencyFormatter.format(100000), '₹ 1,00,000');
      expect(CurrencyFormatter.format(12480), '₹ 12,480');
    });

    test('Formats compact chips notation', () {
      expect(CurrencyFormatter.formatCompact(10000), '₹ 10K');
      expect(CurrencyFormatter.formatCompact(25000), '₹ 25K');
      expect(CurrencyFormatter.formatCompact(50000), '₹ 50K');
      expect(CurrencyFormatter.formatCompact(100000), '₹ 1L');
    });

    test('Parses strings to double correctly', () {
      expect(CurrencyFormatter.parse('₹ 50,000'), 50000.0);
      expect(CurrencyFormatter.parse('₹ 1,00,000'), 100000.0);
    });
  });

  group('Validators Tests', () {
    test('Validates email or mobile input', () {
      expect(Validators.validateEmailOrMobile(''), isNotNull);
      expect(Validators.validateEmailOrMobile('rohit@example.com'), isNull);
      expect(Validators.validateEmailOrMobile('9876543210'), isNull);
      expect(Validators.validateEmailOrMobile('123'), isNotNull);
    });

    test('Validates name format', () {
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('Al'), isNotNull);
      expect(Validators.validateName('Rohit Sharma'), isNull);
    });

    test('Validates password length', () {
      expect(Validators.validatePassword('123'), isNotNull);
      expect(Validators.validatePassword('invest123'), isNull);
    });

    test('Validates investment amount limits', () {
      expect(Validators.validateInvestmentAmount('0'), isNotNull);
      expect(Validators.validateInvestmentAmount('500'), isNotNull); // < 1000
      expect(Validators.validateInvestmentAmount('5000'), isNull);
      expect(Validators.validateInvestmentAmount('50000'), isNull);
      expect(Validators.validateInvestmentAmount('20000000'), isNotNull); // > 10L
    });

    test('Validates withdrawal amount against available balance', () {
      expect(Validators.validateWithdrawalAmount('200', 12480.0), isNotNull); // < 500
      expect(Validators.validateWithdrawalAmount('5000', 12480.0), isNull);
      expect(Validators.validateWithdrawalAmount('15000', 12480.0), isNotNull); // exceeds balance
    });
  });

  group('ProjectModel Tests', () {
    test('Calculates progress percentage accurately', () {
      final project = ProjectModel(
        id: 'p1',
        name: 'Test Project',
        category: 'Tech',
        iconType: 'code',
        targetAmount: 50000,
        raisedAmount: 25000,
        returnRatePercent: 18,
        durationMonths: 12,
        description: 'Test',
        createdAt: DateTime(2026),
      );

      expect(project.progressPercentage, 50.0);
      expect(project.calculateExpectedReturn(50000), 9000.0);
      expect(project.calculateMonthlyReturn(50000), 750.0);
    });
  });
}
