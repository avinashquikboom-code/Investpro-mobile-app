import 'dart:async';
import 'package:get/get.dart';
import 'package:investpro/app/controllers/subscription_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/constants/app_constants.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'sync_snapshot_retention_test.dart' show SnapshotApi, MemoryStore;
class ResetApi extends SnapshotApi {
  String revision='before-reset';
  Completer<List<Map<String,dynamic>>>? pendingHistory;
  @override Future<List<Map<String,dynamic>>> getSubscriptionHistory() async=>pendingHistory==null?[]:await pendingHistory!.future;
  @override Future<Map<String,dynamic>> object(String path) async=>{'status':'ACTIVE','dataRevision':revision};
}
void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a reset clears stale persisted and visible data before a failing refresh, preserves auth, and stays cleared after restart',()async{
    final memory=MemoryStore(),api=ResetApi();final storage=LocalStorageService(backend:memory);
    await storage.write('access_token','fixture-auth');await storage.write('refresh_token','fixture-refresh');
    await storage.setThemeMode('dark');await storage.setNotificationsEnabled(false);
    final notices=NotificationService(storage,api),repo=DemoRepository(storage,NotificationService(storage,api),api);
    await repo.syncFromBackend();expect(repo.projects,isNotEmpty);
    await storage.writeMap('ledger_v2',{'projects':[{'id':'deleted'}]});
    await storage.writeList(AppConstants.keyProjectsData,[{'id':'deleted'}]);
    api.revision='after-reset';api.fail=true;
    await expectLater(repo.syncFromBackend(),throwsA(anything));
    expect(repo.projects,isEmpty);expect(repo.investments,isEmpty);expect(repo.availableBalance.value,0);
    expect(storage.read('ledger_v2'),isNull);expect(storage.read(AppConstants.keyProjectsData),isNull);
    expect(storage.read('access_token'),'fixture-auth');expect(storage.read('refresh_token'),'fixture-refresh');
    expect(storage.themeMode,'dark');expect(storage.notificationsEnabled,isFalse);
    api.fail=false;api.empty=true;api.balance='0.00';
    final restarted=await DemoRepository(storage,notices,api).init();
    expect(restarted.currentUser.value.id,isEmpty);await restarted.syncFromBackend();
    expect(restarted.projects,isEmpty);expect(restarted.transactions,isEmpty);expect(restarted.availableBalance.value,0);
    expect(storage.read('application_data_revision'),'after-reset');
  });
  test('a pre-reset response arriving after a reset cannot repopulate deleted data',()async{
    final api=ResetApi(),storage=LocalStorageService(backend:MemoryStore());
    final repo=DemoRepository(storage,NotificationService(storage,api),api);
    await repo.syncFromBackend();expect(repo.projects,isNotEmpty);
    api.pendingProfile=Completer<Map<String,dynamic>>();
    final pending=repo.syncFromBackend();
    await Future<void>.delayed(Duration.zero);
    api.revision='reset-during-request';api.pendingProfile!.complete(SnapshotApi.profile);
    await expectLater(pending,throwsA(anything));
    expect(repo.projects,isEmpty);expect(repo.currentUser.value.id,isEmpty);
    api.pendingProfile=null;api.empty=true;await repo.syncFromBackend();expect(repo.projects,isEmpty);
  });
  test('a reset clears subscription history and rejects an older in-flight history response',()async{
    final api=ResetApi(),storage=LocalStorageService(backend:MemoryStore());
    final repo=DemoRepository(storage,NotificationService(storage,api),api);
    Get.put<DemoRepository>(repo);
    final controller=SubscriptionController(api);controller.onInit();
    try{
      await repo.syncFromBackend();controller.current.value={'id':'deleted-subscription'};controller.history.assignAll([{'id':'deleted-history'}]);
      api.pendingHistory=Completer<List<Map<String,dynamic>>>();final pending=controller.loadHistory();
      api.revision='subscription-reset';api.empty=true;await repo.syncFromBackend();
      expect(controller.current.value,isNull);expect(controller.history,isEmpty);
      api.pendingHistory!.complete([{'id':'old-response'}]);await pending;expect(controller.history,isEmpty);
    }finally{controller.onClose();Get.reset();}
  });

}
