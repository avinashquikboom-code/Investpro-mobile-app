import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/project_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/investment_calculator.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/utils/currency_formatter.dart';
import 'package:investpro/app/views/projects/project_details_view.dart';
class Store implements LocalStore {
 final data=<String,dynamic>{};
 @override dynamic read(String key)=>data[key];
 @override Future<void> write(String key,dynamic value) async {data[key]=value;}
}
ProjectModel project({String id='project',double minimum=1000,double target=1000000,double rate=5,int months=1}) => ProjectModel.fromBackend({
 'id':id,'title':'Website Development','minInvestment':minimum,'targetAmount':target,'fundedAmount':0,'expectedRoi':rate,'tenureMonths':months,'status':'ACTIVE','createdAt':'2026-11-02T00:00:00Z',
});
Future<(ProjectController,InvestmentController)> setup(WidgetTester tester,ProjectModel p,{double? amount,String? selectedId,bool initializeDefault=false}) async {
 Get.testMode=true;GoogleFonts.config.allowRuntimeFetching=false;
 final storage=LocalStorageService(backend:Store());
 final repo=DemoRepository(storage,NotificationService(storage));
 final projects=Get.put(ProjectController(repo));projects.selectProject(p);
 final investments=Get.put(InvestmentController(repo));
 if(initializeDefault) investments.setProject(p);
 if(amount!=null){investments.setProject(selectedId==null?p:project(id:selectedId));investments.selectQuickAmount(amount);}
 await tester.binding.setSurfaceSize(const Size(600,1600));
 addTearDown(()=>tester.binding.setSurfaceSize(null));
 await tester.pumpWidget(GetMaterialApp(translations:AppTranslations(),locale:const Locale('en','US'),home:const ProjectDetailsView(),getPages:[GetPage(name:AppRoutes.investNow,page:()=>const Scaffold(body:Text('Invest Now destination')))]));
 await tester.pumpAndSettle();return(projects,investments);
}
void main(){
 tearDown(Get.reset);
 for(final values in [[10000,5,1,500],[25000,5,1,1250],[10000,18,3,5400],[25000,10,12,30000]]) {
  testWidgets('selected principal, rate and duration stay dynamic $values',(tester) async {
   final (_,controller)=await setup(tester,project(rate:values[1].toDouble(),months:values[2]),amount:values[0].toDouble());
   expect(find.textContaining('Selected amount: ${CurrencyFormatter.format(values[0])}'),findsOneWidget);
   expect(find.text(CurrencyFormatter.format(values[3])),findsWidgets);
   expect(find.text('₹50.00'),findsNothing);
   expect(find.text(CurrencyFormatter.format(values[0]*values[1]/3000)),findsWidgets);
   expect(find.text(CurrencyFormatter.format(values[0]*values[1]/72000)),findsWidgets);
   final central=controller.calculationResult;expect(central.expectedTotalReturn,values[3]);expect(central.projectedMaturityAmount,values[0]+values[3]);
   expect(tester.takeException(),isNull);
  });
 }
 testWidgets('project target supplies the preview principal until an amount is selected',(tester) async {
  await setup(tester,project(target:50000));
  expect(find.textContaining('Project target: ₹50,000.00'),findsOneWidget);
  expect(find.text('5.00% / month'),findsOneWidget);
  expect(find.text('1 Months'),findsOneWidget);
  expect(find.text('₹2,500.00'),findsNWidgets(2));
  expect(find.text('₹83.33'),findsOneWidget);
  expect(find.text('₹3.47'),findsOneWidget);
 });
 for (final target in [50000.0,1000000.0]) {
  testWidgets('dynamic target $target supplies only the unselected preview principal', (tester) async {
   final (_,controller)=await setup(tester,project(minimum:1000,target:target),initializeDefault:true);
   expect(controller.investmentAmount.value,1000);
   expect(controller.hasSelectedInvestmentAmount.value,false);
   expect(find.textContaining('Project target: ${CurrencyFormatter.format(target)}'),findsOneWidget);
   expect(find.text(CurrencyFormatter.format(target*0.05)),findsNWidgets(2));
   expect(find.text('₹50.00'),findsNothing);
  });
 }
 testWidgets('typing a principal after default initialization updates Project Details', (tester) async {
  final (_,controller)=await setup(tester,project(),initializeDefault:true);
  controller.amountTextController.text='10000';await tester.pumpAndSettle();
  expect(controller.hasSelectedInvestmentAmount.value,true);expect(find.textContaining('Selected amount: ₹10,000.00'),findsOneWidget);expect(find.text('₹500.00'),findsNWidgets(2));
 });
 testWidgets('explicitly choosing the minimum is distinct from its automatic prefill', (tester) async {
  final (_,controller)=await setup(tester,project(),initializeDefault:true);
  controller.selectQuickAmount(1000);await tester.pumpAndSettle();
  expect(find.textContaining('Selected amount: ₹1,000.00'),findsOneWidget);expect(find.text('₹50.00'),findsNWidgets(2));
 });
 testWidgets('changing project resets explicit principal selection', (tester) async {
  final (projects,controller)=await setup(tester,project(),amount:10000);
  final next=project(id:'next',minimum:25000,target:30000);projects.selectProject(next);controller.setProject(next);await tester.pumpAndSettle();
  expect(controller.hasSelectedInvestmentAmount.value,false);expect(find.textContaining('Project target: ₹30,000.00'),findsOneWidget);expect(find.text('₹1,500.00'),findsNWidgets(2));expect(find.text('₹50,000.00'),findsNothing);
 });
 test('actual project API response maps its minimum, rate, duration and target independently', () {
  final response=jsonDecode(File('test/fixtures/project_details_api_13.json').readAsStringSync()) as Map<String,dynamic>;
  final p=ProjectModel.fromBackend(response);
  expect(p.minInvestment,1000);expect(p.returnRatePercent,5);expect(p.durationMonths,1);expect(p.targetAmount,50000);expect(p.raisedAmount,20000);
  final calc=InvestmentCalculator.calculate(principal:10000,returnRatePercent:p.returnRatePercent,durationMonths:p.durationMonths);
  expect(calc.expectedTotalReturn,500);expect(calc.projectedMaturityAmount,10500);expect(calc.dailyProjectedReturn,16.67);expect(calc.hourlyProjectedReturn,closeTo(0.6944,1e-4));
 });
 testWidgets('captured API target maps to the Project Details preview',(tester) async {
  final response=jsonDecode(File('test/fixtures/project_details_api_13.json').readAsStringSync()) as Map<String,dynamic>;
  final p=ProjectModel.fromBackend(response);
  await setup(tester,p);
  expect(find.textContaining('Project target: ₹50,000.00'),findsOneWidget);
  expect(find.text('₹2,500.00'),findsNWidgets(2));
  expect(find.text('₹83.33'),findsOneWidget);
  expect(find.text('₹3.47'),findsOneWidget);
 });
 for (final target in [50000,1000000]) {
  testWidgets('funding target $target does not become the selected principal', (tester) async {
   final p=ProjectModel.fromBackend({'id':'project','title':'Dynamic project','minInvestment':1000,'expectedRoi':5,'tenureMonths':1,'targetAmount':target,'fundedAmount':target/2,'status':'ACTIVE'});
   await setup(tester,p,amount:10000);expect(find.text('₹500.00'),findsNWidgets(2));expect(find.textContaining('Selected amount: ₹10,000.00'),findsOneWidget);
  });
 }
 testWidgets('missing target does not fall back to minimum or a hardcoded principal',(tester) async {
  await setup(tester,project(minimum:1000,target:0));expect(find.textContaining('Select an investment amount'),findsOneWidget);expect(find.text('—'),findsNWidgets(4));expect(find.text('₹50.00'),findsNothing);
 });
 testWidgets('an amount selected for another project cannot leak into this preview',(tester) async {
  await setup(tester,project(minimum:2000,target:2000),amount:25000,selectedId:'other');expect(find.textContaining('Project target: ₹2,000.00'),findsOneWidget);expect(find.text('₹100.00'),findsNWidgets(2));expect(find.text('₹1,250.00'),findsNothing);
 });
 testWidgets('amount updates rebuild all return figures and Invest Now keeps the amount',(tester) async {
  final (_,controller)=await setup(tester,project(),amount:10000);
  controller.selectQuickAmount(25000);await tester.pumpAndSettle();expect(find.textContaining('Selected amount: ₹25,000.00'),findsOneWidget);expect(find.text('₹1,250.00'),findsNWidgets(2));
  await tester.ensureVisible(find.text('Invest Now'));await tester.tap(find.text('Invest Now'));await tester.pumpAndSettle();expect(controller.investmentAmount.value,25000);expect(find.text('Invest Now destination'),findsOneWidget);
 });
 testWidgets('principal basis remains readable at a narrow viewport',(tester) async {
  await setup(tester,project(),amount:10000);await tester.binding.setSurfaceSize(const Size(320,640));await tester.pumpAndSettle();
  expect(find.textContaining('Selected amount: ₹10,000.00'),findsOneWidget);expect(tester.takeException(),isNull);
 });
 testWidgets('a matching backend projection is shared; stale rate or amount is rejected',(tester) async {
  final (projects,controller)=await setup(tester,project(),amount:10000);
  controller.backendProjection.value=InvestmentCalculationResult.fromJson({'principal':10000,'monthlyReturnRate':5,'durationMonths':1,'durationDays':30,'totalProjectedReturn':500,'projectedMaturityAmount':10500,'monthlyProjectedReturn':500,'dailyProjectedReturn':16.66666667,'hourlyProjectedReturn':0.69444444});await tester.pump();
  expect(find.text('₹500.00'),findsNWidgets(2));
  projects.selectProject(project(rate:7));await tester.pump();expect(find.text('₹700.00'),findsNWidgets(2));expect(find.text('₹500.00'),findsNothing);
 });
}
