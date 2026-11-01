class MonthlyScheduleItem {
  final int month;
  final double monthlyReturn;
  final double cumulativeReturn;

  const MonthlyScheduleItem({
    required this.month,
    required this.monthlyReturn,
    required this.cumulativeReturn,
  });
}

class InvestmentCalculationResult {
  final double principal;
  final double returnRatePercent;
  final int durationMonths;
  final double expectedTotalReturn;
  final double projectedMaturityAmount;
  final double monthlyProjectedReturn;
  final double dailyProjectedReturn;
  final double hourlyProjectedReturn;
  final double minuteProjectedReturn;
  final List<MonthlyScheduleItem> monthlySchedule;

  const InvestmentCalculationResult({
    required this.principal,
    required this.returnRatePercent,
    required this.durationMonths,
    required this.expectedTotalReturn,
    required this.projectedMaturityAmount,
    required this.monthlyProjectedReturn,
    this.dailyProjectedReturn = 0.0,
    this.hourlyProjectedReturn = 0.0,
    this.minuteProjectedReturn = 0.0,
    this.monthlySchedule = const [],
  });
}

class InvestmentCalculator {
  InvestmentCalculator._();

  // All financial values are integer paise; rates are full-term percentages.
  static int totalReturn(int principal, int rate) =>
      (principal * rate + 50) ~/ 100;
  static int maturity(int principal, int rate) =>
      principal + totalReturn(principal, rate);
  static int monthly(int principal, int rate, int months) =>
      totalReturn(principal, rate) ~/ months;
  static DateTime addMonths(DateTime date, int months) {
    final first = DateTime(date.year, date.month + months);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(
      first.year,
      first.month,
      date.day > lastDay ? lastDay : date.day,
    );
  }

  static double progress(DateTime start, int months, DateTime now) {
    final end = addMonths(start, months);
    return (now.difference(start).inSeconds / end.difference(start).inSeconds)
        .clamp(0.0, 1.0);
  }

  /// Calculates returns based on full-term projected return rate convention
  /// For instance: ₹50,000 at 18% for 12 months:
  /// - Expected Total Return: ₹9,000
  /// - Projected Maturity: ₹59,000
  /// - Monthly Return: ₹750
  /// - Daily Return: ₹25.00
  /// - Hourly Return: ₹1.0417
  /// - Minute Return: ₹0.01736
  static InvestmentCalculationResult calculate({
    required double principal,
    required double returnRatePercent,
    required int durationMonths,
  }) {
    if (principal <= 0 || returnRatePercent < 0 || durationMonths <= 0) {
      return InvestmentCalculationResult(
        principal: principal,
        returnRatePercent: returnRatePercent,
        durationMonths: durationMonths,
        expectedTotalReturn: 0,
        projectedMaturityAmount: principal,
        monthlyProjectedReturn: 0,
        dailyProjectedReturn: 0,
        hourlyProjectedReturn: 0,
        minuteProjectedReturn: 0,
        monthlySchedule: const [],
      );
    }

    // Decimal-safe rounded to 2 places
    final principalMinor = (principal * 100).round();
    final rateBasisPoints = (returnRatePercent * 100).round();
    final totalMinor = (principalMinor * rateBasisPoints + 5000) ~/ 10000;
    final totalReturn = totalMinor / 100.0;
    final maturityAmount = (principalMinor + totalMinor) / 100.0;
    final monthlyReturn = totalReturn / durationMonths;
    final dailyReturn = monthlyReturn / 30.0;
    final hourlyReturn = dailyReturn / 24.0;
    final minuteReturn = hourlyReturn / 60.0;

    // Build monthly amortization schedule
    final schedule = <MonthlyScheduleItem>[];
    for (int m = 1; m <= durationMonths; m++) {
      final isLast = m == durationMonths;
      final cumulative = isLast
          ? totalReturn
          : ((monthlyReturn * m * 100).round() / 100.0);
      schedule.add(
        MonthlyScheduleItem(
          month: m,
          monthlyReturn: (monthlyReturn * 100).round() / 100.0,
          cumulativeReturn: cumulative,
        ),
      );
    }

    return InvestmentCalculationResult(
      principal: (principal * 100).round() / 100.0,
      returnRatePercent: returnRatePercent,
      durationMonths: durationMonths,
      expectedTotalReturn: (totalReturn * 100).round() / 100.0,
      projectedMaturityAmount: (maturityAmount * 100).round() / 100.0,
      monthlyProjectedReturn: (monthlyReturn * 100).round() / 100.0,
      dailyProjectedReturn: (dailyReturn * 100).round() / 100.0,
      hourlyProjectedReturn: (hourlyReturn * 10000).round() / 10000.0,
      minuteProjectedReturn: (minuteReturn * 100000).round() / 100000.0,
      monthlySchedule: schedule,
    );
  }
}
