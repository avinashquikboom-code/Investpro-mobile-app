import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/models/investment_model.dart';
import 'package:investpro/app/services/backend_snapshot.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/utils/currency_formatter.dart';
import 'package:investpro/app/views/investments/investment_details_view.dart';
import 'package:investpro/app/views/investments/investment_success_view.dart';
import 'package:investpro/app/views/investments/my_investments_view.dart';
import 'package:investpro/app/theme/app_theme.dart';
class Store implements LocalStore {
 final values=<String,dynamic>{};
 @override dynamic read(String key)=>values[key];
 @override Future<void> write(String key,dynamic value) async {values[key]=value;}
}
void main(){
 setUp(() {Get.testMode=true;GoogleFonts.config.allowRuntimeFetching=false;});
 tearDown(Get.reset);
 for(final values in [[10000,5,1,500,10500],[10000,18,3,5400,15400],[25000,10,12,30000,55000]]) {
  for(final screen in ['details','success','my investments']) {
   testWidgets('$screen uses corrected backend monthly projections $values', (tester) async {
    final storage=LocalStorageService(backend:Store());
    final repo=DemoRepository(storage,NotificationService(storage));
    Get.put<DemoRepository>(repo);
    final controller=Get.put(InvestmentController(repo));Get.put(NavigationController());
    final row=BackendSnapshot.investment({'id':'investment','investmentReference':'INV-001','projectId':'project','project':{'title':'Website Development'},'status':'ACTIVE','paymentVerified':true,'amount':values[0],'agreedRoi':values[1],'tenureMonths':values[2],
      'totalExpectedReturns':499.46,'projectedTotalInterest':values[3],'projectedMaturityAmount':values[4],
      'monthlyProjectedReturn':values[0]*values[1]/100,'dailyProjectedReturn':values[0]*values[1]/3000,'hourlyProjectedReturn':values[0]*values[1]/72000,
      'startDate':'2026-11-02T00:00:00Z','maturityDate':'2027-11-02T00:00:00Z'});
    repo.investments.assignAll([row]);controller.selectInvestment(row);controller.lastSuccessfulInvestment.value=row;
    await tester.binding.setSurfaceSize(const Size(600,1400));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final view=screen=='details'?const InvestmentDetailsView():screen=='success'?const InvestmentSuccessView():const MyInvestmentsView();
    await tester.pumpWidget(GetMaterialApp(translations:AppTranslations(),locale:const Locale('en','US'),theme:AppTheme.lightTheme,home:view));
    await tester.pumpAndSettle();
    expect(find.text(CurrencyFormatter.format(values[4])),findsWidgets);
    if(screen=='details')expect(find.text(CurrencyFormatter.format(values[3])),findsOneWidget);
    expect(find.text('₹499.46'),findsNothing);expect(find.text('₹10,499.46'),findsNothing);
    expect(tester.takeException(),isNull);
   });
  }
 }
 test('refreshed projection supersedes cached stored total without changing a transaction',(){
   final old=BackendSnapshot.investment({'id':'i','amount':10000,'tenureMonths':1,'agreedRoi':5,'totalExpectedReturns':499.46});
   final refreshed=BackendSnapshot.investment({'id':'i','amount':10000,'tenureMonths':1,'agreedRoi':5,'totalExpectedReturns':499.46,'projectedTotalInterest':'500.00','projectedMaturityAmount':'10500.00'});
   expect(old.expectedReturn,499.46);expect(refreshed.expectedReturn,500);expect(refreshed.maturityAmount,10500);
   final cached=InvestmentModel.fromJson(refreshed.toJson());expect(cached.expectedReturn,500);expect(cached.maturityAmount,10500);
 });
}
