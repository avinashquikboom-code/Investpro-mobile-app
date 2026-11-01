import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';

class Store implements LocalStore {
  final data = <String,dynamic>{};
  @override dynamic read(String key) => data[key];
  @override Future<void> write(String key,dynamic value) async { data[key] = value; }
}
class ProjectionApi extends ApiService {
  final requests = <Completer<Map<String,dynamic>?>>[];
  @override Future<Map<String,dynamic>?> getInvestmentProjection({required String projectId,required double amount}) {
    final pending = Completer<Map<String,dynamic>?>(); requests.add(pending); return pending.future;
  }
}
ProjectModel project(String id) => ProjectModel(id:id,name:id,category:'Energy',iconType:'folder',targetAmount:100000,raisedAmount:0,minInvestment:10000,returnRatePercent:10,durationMonths:12,description:'',createdAt:DateTime(2026));
Map<String,dynamic> response(double principal,double rate) => {
  'principal':principal,'monthlyReturnRate':rate,'durationMonths':12,'durationDays':365,
  'isAmountValid':true,'totalProjectedReturn':12000,'monthlyProjectedReturn':1000,
  'finalMonthInterest':1000,'finalMonthPayment':11000,'principalRepaymentAtMaturity':10000,
  'previousMonthlyInterestPayouts':11000,'totalReceivedOverInvestmentPeriod':22000,
  'interestAccrualEndDate':'2026-12-31','schedules':{},'payoutSchedule':[],
};
void main() {
  tearDown(Get.reset);
  testWidgets('live projections reject stale project and amount responses and accept updated admin rates', (tester) async {
    Get.testMode = true;
    final api = ProjectionApi(); Get.put<ApiService>(api);
    final storage = LocalStorageService(backend:Store());
    final controller = Get.put(InvestmentController(DemoRepository(storage,NotificationService(storage),api)));
    controller.setProject(project('A')); await tester.pump(const Duration(milliseconds:250));
    controller.setProject(project('B')); await tester.pump(const Duration(milliseconds:250));
    api.requests[1].complete(response(10000,20)); await tester.pump();
    expect(controller.calculationResult.returnRatePercent,20);
    api.requests[0].complete(response(10000,10)); await tester.pump();
    expect(controller.calculationResult.returnRatePercent,20);
    controller.amountTextController.text = '20000';
    expect(controller.backendProjection.value,isNull);
    expect(controller.calculationResult.expectedTotalReturn,0);
    await tester.pump(const Duration(milliseconds:250));
    api.requests.last.complete(response(20000,7)); await tester.pump();
    expect(controller.calculationResult.principal,20000);
    expect(controller.calculationResult.returnRatePercent,7);
    expect(controller.calculationResult.finalMonthPayment,11000);
    expect(controller.calculationResult.totalReceivedOverInvestmentPeriod,22000);
    controller.onClose();
  });
}
