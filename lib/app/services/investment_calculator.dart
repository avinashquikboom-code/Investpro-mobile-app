enum DayCountConvention {
  thirty360, // 30-day month / 360-day year (InvestPro backend standard)
  actual365, // Actual / 365 convention
}

class ReturnScheduleItem {
  final int index;
  final String label;
  final DateTime? date;
  final String? dateLabel;
  final double returnAmount;
  final double cumulativeReturn;

  const ReturnScheduleItem({
    required this.index,
    required this.label,
    this.date,
    this.dateLabel,
    required this.returnAmount,
    required this.cumulativeReturn,
  });
}

class MonthlyScheduleItem {
  final int month;
  final double monthlyReturn;
  final double cumulativeReturn;
  final DateTime? date;
  final String? dateLabel;

  const MonthlyScheduleItem({
    required this.month,
    required this.monthlyReturn,
    required this.cumulativeReturn,
    this.date,
    this.dateLabel,
  });
}

class InvestmentCalculationResult {
  final String? projectEndDate, finalEligibleDate;
  final String durationUnit;
  final int? investmentDuration;
  final List<Map<String, dynamic>> payoutSchedule;
  final double previousMonthlyInterestPayouts, finalMonthInterest, principalRepaymentAtMaturity, finalMonthPayment, totalReceivedOverInvestmentPeriod;
  final double principal;
  final double returnRatePercent;
  final int durationMonths;
  final int durationDays;
  final double expectedTotalReturn;
  final double projectedMaturityAmount;
  final double monthlyProjectedReturn;
  final double dailyProjectedReturn;
  final double hourlyProjectedReturn;
  final double minuteProjectedReturn;
  final List<MonthlyScheduleItem> monthlySchedule;
  final List<ReturnScheduleItem> dailySchedule;
  final List<ReturnScheduleItem> hourlySchedule;
  final List<ReturnScheduleItem> totalSchedule;
  final DayCountConvention dayCountConvention;

  const InvestmentCalculationResult({
    this.projectEndDate, this.finalEligibleDate, this.durationUnit = 'MONTHS', this.investmentDuration,
    this.payoutSchedule = const [], this.previousMonthlyInterestPayouts = 0, this.finalMonthInterest = 0,
    this.principalRepaymentAtMaturity = 0, this.finalMonthPayment = 0, this.totalReceivedOverInvestmentPeriod = 0,
    required this.principal,
    required this.returnRatePercent,
    required this.durationMonths,
    this.durationDays = 0,
    required this.expectedTotalReturn,
    required this.projectedMaturityAmount,
    required this.monthlyProjectedReturn,
    this.dailyProjectedReturn = 0.0,
    this.hourlyProjectedReturn = 0.0,
    this.minuteProjectedReturn = 0.0,
    this.monthlySchedule = const [],
    this.dailySchedule = const [],
    this.hourlySchedule = const [],
    this.totalSchedule = const [],
    this.dayCountConvention = DayCountConvention.thirty360,
  });
  factory InvestmentCalculationResult.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    final schedules = json['schedules'] as Map? ?? {};
    List<ReturnScheduleItem> rows(String key) => (schedules[key] as List? ?? []).map((e) => ReturnScheduleItem(
      index: (e['index'] as num).toInt(), label: e['label'].toString(), date: DateTime.tryParse('${e['date']}'),
      dateLabel: e['dateLabel']?.toString(), returnAmount: (e['returnAmount'] as num).toDouble(), cumulativeReturn: (e['cumulativeReturn'] as num).toDouble(),
    )).toList();
    return InvestmentCalculationResult(
      principal: number('principal'), returnRatePercent: number('monthlyReturnRate'), durationMonths: (json['durationMonths'] as num).toInt(), durationDays: (json['durationDays'] as num).toInt(),
      expectedTotalReturn: number('totalProjectedReturn'), projectedMaturityAmount: number('totalReceivedOverInvestmentPeriod'), monthlyProjectedReturn: number('monthlyProjectedReturn'), dailyProjectedReturn: number('dailyProjectedReturn'), hourlyProjectedReturn: number('hourlyProjectedReturn'), minuteProjectedReturn: number('minuteProjectedReturn'),
      projectEndDate: json['projectEndDate']?.toString(), finalEligibleDate: json['interestAccrualEndDate']?.toString(), durationUnit: json['durationUnit']?.toString() ?? 'MONTHS', investmentDuration: (json['investmentDuration'] as num?)?.toInt(),
      previousMonthlyInterestPayouts: number('previousMonthlyInterestPayouts'), finalMonthInterest: number('finalMonthInterest'), principalRepaymentAtMaturity: number('principalRepaymentAtMaturity'), finalMonthPayment: number('finalMonthPayment'), totalReceivedOverInvestmentPeriod: number('totalReceivedOverInvestmentPeriod'),
      payoutSchedule: (json['payoutSchedule'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      dailySchedule: rows('daily'), hourlySchedule: rows('hourly'), totalSchedule: rows('total'),
      monthlySchedule: (schedules['monthly'] as List? ?? []).map((e) => MonthlyScheduleItem(month: (e['month'] as num).toInt(), monthlyReturn: (e['monthlyReturn'] as num).toDouble(), cumulativeReturn: (e['cumulativeReturn'] as num).toDouble(),date: DateTime.tryParse('${e['date']}'),dateLabel: e['dateLabel']?.toString())).toList(),
    );
  }

}

class InvestmentCalculator {
  InvestmentCalculator._();

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_monthNames[dt.month - 1]} ${dt.year}';

  // All financial values are integer paise; rate is monthly percentage.
  static int monthly(int principal, int rate) =>
      (principal * rate + 50) ~/ 100;
  static int totalReturn(int principal, int rate, [int months = 1]) =>
      monthly(principal, rate) * months;
  static int maturity(int principal, int rate, [int months = 1]) =>
      principal + totalReturn(principal, rate, months);

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

  /// Calculates dynamic returns and complete amortization schedules across
  /// all 4 view modes (Monthly, Daily, Hourly, Total milestones).
  ///
  /// Conforms to the configured day-count convention:
  /// - thirty360 (InvestPro backend standard: 30-day month / 360-day year)
  /// - actual365 (Standard 365-day annual basis)
  static InvestmentCalculationResult calculate({
    required double principal,
    required double returnRatePercent,
    required int durationMonths,
    DateTime? startDate,
    DayCountConvention convention = DayCountConvention.thirty360,
  }) {
    if (principal <= 0 || returnRatePercent < 0 || durationMonths <= 0) {
      return InvestmentCalculationResult(
        principal: principal,
        returnRatePercent: returnRatePercent,
        durationMonths: durationMonths,
        durationDays: 0,
        expectedTotalReturn: 0,
        projectedMaturityAmount: principal,
        monthlyProjectedReturn: 0,
        dailyProjectedReturn: 0,
        hourlyProjectedReturn: 0,
        minuteProjectedReturn: 0,
        monthlySchedule: const [],
        dailySchedule: const [],
        hourlySchedule: const [],
        totalSchedule: const [],
        dayCountConvention: convention,
      );
    }

    final start = startDate ?? DateTime.now();
    final cleanStart = DateTime(start.year, start.month, start.day);
    final end = addMonths(cleanStart, durationMonths);
    final actualDaysInTerm = end.difference(cleanStart).inDays;
    final durationDays = convention == DayCountConvention.thirty360
        ? durationMonths * 30
        : (actualDaysInTerm > 0
            ? actualDaysInTerm
            : (durationMonths * 365.0 / 12.0).round());

    // Confirmed business rule: The return percentage represents MONTHLY INTEREST, not annual interest.
    // monthlyInterest = principal * monthlyReturnRate / 100
    // totalInterest = monthlyInterest * durationMonths
    // maturityAmount = principal + totalInterest
    final monthlyReturn = ((principal * (returnRatePercent / 100.0)) * 100).round() / 100.0;
    final totalReturn = ((monthlyReturn * durationMonths) * 100).round() / 100.0;
    final maturityAmount = ((principal + totalReturn) * 100).round() / 100.0;

    // Daily & hourly return:
    // In 30/360: exactly 30 days per month. In calendar: days in current calendar month.
    final now = start;
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysInMonth = convention == DayCountConvention.thirty360 ? 30 : daysInCurrentMonth;
    final dailyReturn = monthlyReturn / daysInMonth;
    final hourlyReturn = dailyReturn / 24.0;
    final minuteReturn = hourlyReturn / 60.0;

    final finalMonthInterest = monthlyReturn;
    final previousMonthlyInterestPayouts = durationMonths > 1
        ? ((monthlyReturn * (durationMonths - 1)) * 100).round() / 100.0
        : 0.0;
    final principalRepaymentAtMaturity = principal;
    final finalMonthPayment = ((principal + finalMonthInterest) * 100).round() / 100.0;
    final totalReceivedOverInvestmentPeriod = maturityAmount;

    // Monthly payout schedule
    final payoutSchedule = <Map<String, dynamic>>[];
    for (int m = 1; m <= durationMonths; m++) {
      final isLast = m == durationMonths;
      final payoutDate = addMonths(start, m);
      payoutSchedule.add({
        'payoutNumber': m,
        'payoutDate': payoutDate.toIso8601String(),
        'interestAmount': monthlyReturn,
        'principalAmount': isLast ? principal : 0.0,
        'totalPayoutAmount': isLast ? (principal + monthlyReturn) : monthlyReturn,
        'payoutType': isLast ? 'MATURITY' : 'MONTHLY_INTEREST',
        'payoutStatus': 'UPCOMING',
      });
    }

    // 1. Monthly amortization schedule (Month 1..M)
    final monthlySchedule = <MonthlyScheduleItem>[];
    for (int m = 1; m <= durationMonths; m++) {
      final isLast = m == durationMonths;
      final cumulative = isLast
          ? totalReturn
          : ((monthlyReturn * m * 100).round() / 100.0);
      final itemDate = addMonths(start, m);
      monthlySchedule.add(
        MonthlyScheduleItem(
          month: m,
          monthlyReturn: (monthlyReturn * 100).round() / 100.0,
          cumulativeReturn: cumulative,
          date: itemDate,
          dateLabel: formatDate(itemDate),
        ),
      );
    }

    // 2. Daily schedule (First 30 days cycle or term days)
    final dailySchedule = <ReturnScheduleItem>[];
    final daysToGenerate = durationDays < 30 ? durationDays : 30;
    for (int d = 1; d <= daysToGenerate; d++) {
      final itemDate = start.add(Duration(days: d));
      final cumulative = (dailyReturn * d * 100).round() / 100.0;
      dailySchedule.add(
        ReturnScheduleItem(
          index: d,
          label: 'Day $d',
          date: itemDate,
          dateLabel: formatDate(itemDate),
          returnAmount: (dailyReturn * 100).round() / 100.0,
          cumulativeReturn: cumulative,
        ),
      );
    }

    // 3. Hourly schedule (24 Hours cycle)
    final hourlySchedule = <ReturnScheduleItem>[];
    for (int h = 1; h <= 24; h++) {
      final isLastHour = h == 24;
      final cumulative = isLastHour
          ? (dailyReturn * 100).round() / 100.0
          : ((hourlyReturn * h * 100).round() / 100.0);
      final hourStr = '${h.toString().padLeft(2, '0')}:00';
      hourlySchedule.add(
        ReturnScheduleItem(
          index: h,
          label: hourStr,
          dateLabel: hourStr,
          returnAmount: (hourlyReturn * 10000).round() / 10000.0,
          cumulativeReturn: cumulative,
        ),
      );
    }

    // 4. Total milestone schedule
    final totalSchedule = <ReturnScheduleItem>[];
    if (durationMonths <= 4) {
      for (int m = 1; m <= durationMonths; m++) {
        final isLast = m == durationMonths;
        final cumulative = isLast ? totalReturn : ((monthlyReturn * m * 100).round() / 100.0);
        final itemDate = addMonths(start, m);
        totalSchedule.add(
          ReturnScheduleItem(
            index: m,
            label: 'Month $m',
            date: itemDate,
            dateLabel: formatDate(itemDate),
            returnAmount: (monthlyReturn * 100).round() / 100.0,
            cumulativeReturn: cumulative,
          ),
        );
      }
    } else {
      final quarterStep = (durationMonths / 4).round().clamp(1, durationMonths);
      final milestones = {
        quarterStep,
        (quarterStep * 2).clamp(1, durationMonths),
        (quarterStep * 3).clamp(1, durationMonths),
        durationMonths,
      }.toList()..sort();

      for (int i = 0; i < milestones.length; i++) {
        final m = milestones[i];
        final isLast = m == durationMonths;
        final cumulative = isLast
            ? totalReturn
            : ((monthlyReturn * m * 100).round() / 100.0);
        final prevM = i == 0 ? 0 : milestones[i - 1];
        final periodReturn = ((monthlyReturn * (m - prevM) * 100).round() / 100.0);
        final itemDate = addMonths(start, m);
        final label = isLast
            ? 'Maturity (Month $m)'
            : 'Milestone ${i + 1} (Month $m)';

        totalSchedule.add(
          ReturnScheduleItem(
            index: i + 1,
            label: label,
            date: itemDate,
            dateLabel: formatDate(itemDate),
            returnAmount: periodReturn,
            cumulativeReturn: cumulative,
          ),
        );
      }
    }

    return InvestmentCalculationResult(
      principal: (principal * 100).round() / 100.0,
      returnRatePercent: returnRatePercent,
      durationMonths: durationMonths,
      durationDays: durationDays,
      expectedTotalReturn: (totalReturn * 100).round() / 100.0,
      projectedMaturityAmount: (maturityAmount * 100).round() / 100.0,
      monthlyProjectedReturn: (monthlyReturn * 100).round() / 100.0,
      dailyProjectedReturn: (dailyReturn * 100).round() / 100.0,
      hourlyProjectedReturn: (hourlyReturn * 10000).round() / 10000.0,
      minuteProjectedReturn: (minuteReturn * 100000).round() / 100000.0,
      previousMonthlyInterestPayouts: previousMonthlyInterestPayouts,
      finalMonthInterest: finalMonthInterest,
      principalRepaymentAtMaturity: principalRepaymentAtMaturity,
      finalMonthPayment: finalMonthPayment,
      totalReceivedOverInvestmentPeriod: totalReceivedOverInvestmentPeriod,
      payoutSchedule: payoutSchedule,
      monthlySchedule: monthlySchedule,
      dailySchedule: dailySchedule,
      hourlySchedule: hourlySchedule,
      totalSchedule: totalSchedule,
      dayCountConvention: convention,
    );
  }
}
