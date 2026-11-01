import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/backend_snapshot.dart';
import 'package:investpro/app/models/investment_model.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/utils/project_image_url.dart';
import 'package:investpro/app/widgets/project_image.dart';
import 'sync_snapshot_retention_test.dart' show MemoryStore;

ProjectModel project(String? url, {String revision='2026-11-01T10:00:00Z'}) => ProjectModel.fromBackend({
  'id':'project','title':'Shared project','bannerUrl':url,'updatedAt':revision,
  'targetAmount':100000,'fundedAmount':0,'minInvestment':5000,'expectedRoi':1.5,'tenureMonths':12,'status':'ACTIVE',
});
void main() {
  tearDown(Get.reset);
  test('resolves relative media against the API origin, accepts remote URLs, rejects invalid schemes', () {
    const base='https://api.example.test/api/v1';
    expect(projectImageUrl('/uploads/media/image.png',apiBaseUrl:base),'https://api.example.test/uploads/media/image.png');
    expect(projectImageUrl('uploads/media/image.png',apiBaseUrl:base),'https://api.example.test/uploads/media/image.png');
    expect(projectImageUrl('//cdn.example.test/image.png',apiBaseUrl:base),'https://cdn.example.test/image.png');
    for(final value in [null,'','   ','file:///private/image.png','javascript:alert(1)','https://']) {
      expect(projectImageUrl(value,apiBaseUrl:base),isNull);
    }
  });
  test('same-path replacement changes cache URL while signed URLs remain byte-for-byte intact', () {
    const path='https://cdn.example.test/project.png';
    final before=projectImageUrl(path,apiBaseUrl:path,updatedAt:DateTime.utc(2026,11,1));
    final after=projectImageUrl(path,apiBaseUrl:path,updatedAt:DateTime.utc(2026,11,2));
    expect(before,isNot(after));
    const signed='https://bucket.s3.amazonaws.com/image.png?X-Amz-Signature=abc&X-Amz-Date=20261101';
    expect(projectImageUrl(signed,apiBaseUrl:path,updatedAt:DateTime.utc(2026)),signed);
  });
  test('shared banner wins, gallery fallback is supported, and clearing the image stays cleared after serialization', () {
    expect(ProjectModel.fromBackend({'id':'fixture','bannerUrl':' /uploads/banner.png ','images':['/uploads/gallery.png']}).imageUrl,'/uploads/banner.png');
    expect(ProjectModel.fromBackend({'id':'fixture','bannerUrl':null,'images':['', '/uploads/gallery.png']}).imageUrl,'/uploads/gallery.png');
    final cleared=ProjectModel.fromJson(project(null).toJson());expect(cleared.imageUrl,isNull);
  });
  test('investment image display metadata comes from the shared nested project and survives snapshots', () {
    final investment=BackendSnapshot.investment({'id':'investment','projectId':'project','amount':5000,'agreedRoi':1.5,'tenureMonths':12,'status':'ACTIVE','project':{'id':'project','title':'Project','bannerUrl':'/uploads/project.png','updatedAt':'2026-11-01T10:00:00Z'}});
    final restored=InvestmentModel.fromJson(investment.copyWith(status:'Active').toJson());
    expect(restored.projectImageUrl,'/uploads/project.png');expect(restored.projectUpdatedAt,DateTime.utc(2026,11,1,10));
  });
  testWidgets('missing/invalid and failed images retain their sized placeholder', (tester) async {
    for(final url in [null,'file:///invalid','https://images.example.test/missing.png']) {
      await tester.pumpWidget(MaterialApp(home: Center(child:ProjectImage(project:project(url),width:80,height:60))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.landscape_outlined),findsOneWidget);
      expect(tester.getSize(find.byType(ProjectImage)),const Size(80,60));
      expect(tester.takeException(),isNull);
    }
  });
  testWidgets('replacement resets the image provider and Invest Now observes refreshed metadata without changing payment input', (tester) async {
    final storage=LocalStorageService(backend:MemoryStore());
    final repo=DemoRepository(storage,NotificationService(storage));
    final controller=InvestmentController(repo);
    final original=project('/uploads/image.png');controller.setProject(original);
    final amount=controller.investmentAmount.value;
    await tester.pumpWidget(MaterialApp(home:Center(child:Obx(()=>ProjectImage(project:controller.currentProjectImageSource!,width:80,height:60)))));
    final before=(tester.widget<Image>(find.byType(Image)).image as NetworkImage).url;
    repo.projects.assignAll([project('/uploads/image.png',revision:'2026-11-02T10:00:00Z')]);await tester.pump();
    final after=(tester.widget<Image>(find.byType(Image)).image as NetworkImage).url;
    expect(after,isNot(before));expect(controller.currentProject.value,same(original));expect(controller.investmentAmount.value,amount);
    final image=tester.widget<Image>(find.byType(Image));expect(image.gaplessPlayback,isFalse);
    expect(image.frameBuilder!(tester.element(find.byType(Image)),const SizedBox(),null,false),isA<Stack>());
    await tester.pumpAndSettle();controller.onClose();expect(tester.takeException(),isNull);
  });
}
