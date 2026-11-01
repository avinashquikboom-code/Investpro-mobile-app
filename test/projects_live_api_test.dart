import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/models/project_model.dart';

void main() {
  const fixturePath = String.fromEnvironment('PROJECTS_API_FIXTURE');
  test('investor API service reads the city saved by admin mobile', () async {
    final fixture = jsonDecode(File(fixturePath).readAsStringSync()) as Map;
    final api = ApiService();
    api.dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5019/api/v1', headers: {'Authorization': 'Bearer ${fixture['investorToken']}'}));
    final id = fixture['projectId'] as String;
    final project = ProjectModel.fromBackend((await api.getProject(id))!);
    expect(project.cityLabel, 'Nagpur');
    expect(project.location, 'Baner Road, Pune, Maharashtra');
    expect(project.progressPercentage, 0);
    final page = await api.getEligibleProjectPage(search: 'Nagpur');
    expect(ProjectModel.fromBackend(page.projects.singleWhere((p) => p['id'] == id)).cityLabel, 'Nagpur');
    api.dio.close();
  }, skip: fixturePath.isEmpty);
}
