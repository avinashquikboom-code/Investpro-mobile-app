// Explicit debug entry point for actual FCM testing against a local fixture.
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:investpro/firebase_options.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/firebase_notification_service.dart';
import 'package:investpro/app/routes/app_routes.dart';

class ProbeStore implements LocalStore {
  final values = <String, dynamic>{'push_device_id': 'android-investor-probe'};
  @override dynamic read(String key) => values[key];
  @override Future<void> write(String key, dynamic value) async { values[key] = value; }
}
class ProbeApi extends ApiService {
  final String access;
  ProbeApi(this.access);
  @override Future<String?> getAccessToken() async => access;
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final bootstrap = (await Dio().get('http://127.0.0.1:5031/probe/bootstrap/INVESTOR')).data as Map;
  final api = ProbeApi(bootstrap['token'] as String);
  api.dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5031/api/v1', headers: {'Authorization': 'Bearer ${bootstrap['token']}'}));
  final storage = LocalStorageService(backend: ProbeStore());
  final notifications = NotificationService(storage, api);
  Get.put(AuthController(storage, DemoRepository(storage, notifications))).isLoggedIn.value = true;
  final push = await FirebaseNotificationService(storage, api, notifications).init();
  runApp(GetMaterialApp(initialRoute: '/probe', getPages: [
    GetPage(name: '/probe', page: () => const Scaffold(body: Center(child: Text('Investor real push probe')))),
    GetPage(name: AppRoutes.notifications, page: () => const Scaffold(body: Center(child: Text('Investor notification opened')))),
  ]));
  WidgetsBinding.instance.addPostFrameCallback((_) => push.flushKyc());
}
