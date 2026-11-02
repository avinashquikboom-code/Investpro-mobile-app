import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/investment_calculator.dart';
import 'package:investpro/app/services/backend_snapshot.dart';
import 'package:investpro/app/models/investment_model.dart';
void main() {
  test('lifetime maturity never uses the final-month payment, including decimal-string responses', () {
    final result=InvestmentCalculationResult.fromJson({'principal':'10000','durationMonths':3,'durationDays':90,'monthlyReturnRate':'18','totalProjectedReturn':'5400','projectedMaturityAmount':'15400','finalMonthPayment':'11800','monthlyProjectedReturn':'1800','dailyProjectedReturn':'60','hourlyProjectedReturn':'2.5'});
    expect(result.projectedMaturityAmount,15400);expect(result.totalReceivedOverInvestmentPeriod,15400);expect(result.finalMonthPayment,11800);
    expect(result.monthlyProjectedReturn,1800);expect(result.dailyProjectedReturn,60);expect(result.hourlyProjectedReturn,2.5);
    final compatibility=InvestmentCalculationResult.fromJson({'principal':10000,'durationMonths':3,'durationDays':90,'totalProjectedReturn':5400,'finalMonthPayment':11800});
    expect(compatibility.projectedMaturityAmount,15400);
  });
  for (final values in [[10000,18,3,5400,15400],[10000,10,12,12000,22000],[25000,5,6,7500,32500],[50000,12,12,72000,122000]]) {
    test('dynamic demonstration projection ${values.take(3).toList()}', () {
      final result=InvestmentCalculator.calculate(principal:values[0].toDouble(),returnRatePercent:values[1].toDouble(),durationMonths:values[2]);
      expect(result.expectedTotalReturn,values[3]);expect(result.projectedMaturityAmount,values[4]);
      expect(result.payoutSchedule.fold<double>(0,(sum,p)=>sum+(p['totalPayoutAmount'] as num).toDouble()),values[4]);
    });
  }
  test('fractional monthly interest is retained until cumulative currency rounding', () {
    final result=InvestmentCalculator.calculate(principal:1,returnRatePercent:0.5,durationMonths:12);
    expect(result.expectedTotalReturn,0.06);
    expect(result.projectedMaturityAmount,1.06);
    expect(result.payoutSchedule.fold<double>(0,(sum,p)=>sum+(p['totalPayoutAmount'] as num).toDouble()),closeTo(1.06,1e-10));
    expect(result.monthlySchedule.fold<double>(0,(sum,p)=>sum+p.monthlyReturn),closeTo(0.06,1e-10));
  });
  test('stored backend calendar projection survives model copies and cache serialization', () {
    final model=BackendSnapshot.investment({'id':'i','amount':'10000','tenureMonths':1,'agreedRoi':10,'totalExpectedReturns':'500','projectedMaturityAmount':'10500','monthlyProjectedReturn':'1000','dailyProjectedReturn':'33.33333333','hourlyProjectedReturn':'1.38888889'});
    for (final row in [model,model.copyWith(),InvestmentModel.fromJson(model.toJson())]) {
      expect(row.maturityAmount,10500);expect(row.monthlyProjectedReturn,1000);expect(row.dailyProjectedReturn,closeTo(1000/30,1e-8));expect(row.hourlyProjectedReturn,closeTo(1000/720,1e-8));
    }
  });
}
