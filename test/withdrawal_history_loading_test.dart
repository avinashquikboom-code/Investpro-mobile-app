import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/withdrawal_controller.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/withdrawals/withdrawal_view.dart';
import 'sync_snapshot_retention_test.dart' show SnapshotApi, MemoryStore;
class WithdrawalApi extends SnapshotApi {
  bool historyFails=false, transactionFails=false, walletFails=false;
  int? status;
  Completer<List<dynamic>?>? pending;
  List<dynamic> rows=[{'id':'withdrawal-fixture','amount':'125.00','status':'PENDING','withdrawalReference':'WD-TEST-001','requestedAt':'2026-11-01T10:00:00Z','bankAccount':{'bankName':'Fixture Bank','accountNumber':'12345678'}}];
  List<dynamic> activity=[];
  List<Map<String,dynamic>> active=[];
  @override Future<Map<String,dynamic>> getWallet() async {
    if(walletFails) throw StateError('Wallet unavailable');
    return {'availableBalance':'1200.50','reservedBalance':'125.00','minimumWithdrawal':'100.00','banks':[],'activeInvestments':active};
  }
  @override Future<List<dynamic>?> getWithdrawals() async {
    if(pending!=null)return pending!.future;
    if(historyFails){final request=RequestOptions(path:'/mobile/withdrawals');throw DioException(requestOptions:request,response:Response(requestOptions:request,statusCode:status??500),type:DioExceptionType.badResponse);}
    return rows;
  }
  @override Future<List<dynamic>?> getTransactions() async {if(transactionFails)throw StateError('Transactions unavailable');return activity;}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 late WithdrawalApi api;late DemoRepository repo;late WithdrawalController controller;
 setUp((){
  Get.testMode=true;GoogleFonts.config.allowRuntimeFetching=false;
  api=WithdrawalApi();Get.put<ApiService>(api);
  final storage=LocalStorageService(backend:MemoryStore());repo=DemoRepository(storage,NotificationService(storage),api);
  repo.currentUser.value=const UserModel(id:'investor',fullName:'Investor',email:'fixture@example.test',mobileNumber:'1234567890',accountStatus:'ACTIVE');
  Get.put(repo);controller=Get.put(WithdrawalController(repo));
 });
 tearDown(Get.reset);
 test('history loads independently when an unrelated account endpoint fails',()async{
  api.fail=true;await expectLater(repo.syncFromBackend(),throwsA(anything));
  await controller.refreshData();
  expect(repo.withdrawals.single.referenceId,'WD-TEST-001');expect(controller.availableBalance,1200.50);expect(controller.reservedBalance,125);
  expect(controller.historyError.value,isEmpty);expect(controller.isLoadingHistory.value,isFalse);
 });
 test('transaction failure cannot hide existing withdrawal requests; all filters retain their actual records',()async{
  api.activity=[for(final type in ['DEPOSIT','RETURN_CREDIT','INVESTMENT','WITHDRAWAL']){'id':type,'type':type,'amount':'50.00','status':'COMPLETED','createdAt':'2026-11-01T09:00:00Z'}];
  await controller.loadHistory();expect(controller.filteredTransactions,hasLength(4));
  for(final filter in ['Withdrawals','Deposits','Returns','Investments']){controller.setFilter(filter);expect(controller.filteredTransactions,hasLength(1));}
  api.transactionFails=true;await controller.loadHistory();expect(repo.withdrawals,hasLength(1));expect(controller.historyError.value,contains('transaction history'));
 });
 test('API failure retains verified requests, finishes loading, and retry accepts an actual empty response',()async{
  await controller.loadHistory();api.historyFails=true;await controller.loadHistory();
  expect(repo.withdrawals,hasLength(1));expect(controller.historyError.value,contains('Unable to load withdrawal requests'));expect(controller.isLoadingHistory.value,isFalse);
  api.historyFails=false;api.rows=[];await controller.loadHistory();expect(repo.withdrawals,isEmpty);expect(controller.historyError.value,isEmpty);
 });
 for(final status in [401,403]){test('authentication error $status remains visible rather than becoming empty history',()async{
  api.historyFails=true;api.status=status;await controller.loadHistory();
  expect(controller.historyError.value,contains(status==401?'session expired':'cannot access'));expect(controller.isLoadingHistory.value,isFalse);
 });}
 test('wallet failure preserves the last verified balance and exposes an error',()async{
  await controller.loadWalletData();api.walletFails=true;await controller.loadWalletData();
  expect(controller.availableBalance,1200.50);expect(controller.walletError.value,contains('wallet details'));expect(controller.isLoadingWallet.value,isFalse);
 });
 test('late history cannot restore previous-account data after sign-out',()async{
  api.pending=Completer<List<dynamic>?>();final pending=controller.loadHistory();repo.clearLiveData();api.sessionVersion++;
  api.pending!.complete(api.rows);await pending;expect(repo.withdrawals,isEmpty);expect(controller.isLoadingHistory.value,isFalse);expect(controller.availableBalance,0);
 });
 testWidgets('screen entry loads requests without requiring a manual refresh',(tester)async{
  tester.view.physicalSize=const Size(430,1100);tester.view.devicePixelRatio=1;addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(theme:AppTheme.lightTheme,translations:AppTranslations(),locale:const Locale('en','US'),home:const WithdrawalView()));await tester.pumpAndSettle();
  expect(repo.withdrawals.single.referenceId,'WD-TEST-001');expect(find.textContaining('Fixture Bank'),findsOneWidget);expect(find.text('Withdrawal request'),findsOneWidget);expect(tester.takeException(),isNull);
 });
 for(final size in [const Size(320,568),const Size(390,844)]) {
 testWidgets('withdrawal requests remain accessible with active contracts on $size',(tester)async{
  api.active=List.generate(3,(i)=>{'projectTitle':'Active project $i','investedAmount':'5000','hourlyRate':'0.10'});
  tester.view.physicalSize=size;tester.view.devicePixelRatio=1;addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(theme:AppTheme.lightTheme,translations:AppTranslations(),locale:const Locale('en','US'),home:const WithdrawalView()));await tester.pumpAndSettle();
  expect(tester.takeException(),isNull);
  await tester.scrollUntilVisible(find.text('Withdrawal request'),200,scrollable:find.byType(Scrollable).first);await tester.pumpAndSettle();expect(find.text('Withdrawal request').hitTestable(),findsOneWidget);
 });
 }
 testWidgets('loading and failed history show progress and Retry instead of a misleading empty state',(tester)async{
  api.pending=Completer<List<dynamic>?>();tester.view.physicalSize=const Size(430,1100);tester.view.devicePixelRatio=1;addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(theme:AppTheme.lightTheme,translations:AppTranslations(),locale:const Locale('en','US'),home:const WithdrawalView()));await tester.pump();
  expect(find.text('Loading withdrawal requests…'),findsOneWidget);
  api.pending!.completeError(StateError('Unavailable'));await tester.pumpAndSettle();expect(find.textContaining('Unable to load withdrawal requests'),findsOneWidget);
  api.pending=null;await tester.tap(find.text('Retry'));await tester.pumpAndSettle();expect(find.text('Withdrawal request'),findsOneWidget);expect(tester.takeException(),isNull);
 });
}
