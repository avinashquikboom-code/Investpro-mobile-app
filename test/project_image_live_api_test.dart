import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/utils/project_image_url.dart';

void main() {
  const fixturePath=String.fromEnvironment('PROJECT_IMAGE_FIXTURE');
  test('mobile API reads the Admin-saved replacement image and downloads the actual local upload',() async {
    final fixture=jsonDecode(File(fixturePath).readAsStringSync()) as Map;
    final base=fixture['baseUrl'] as String,id=fixture['projectId'] as String;
    final api=ApiService();api.dio=Dio(BaseOptions(baseUrl:base,headers:{'Authorization':'Bearer ${fixture['investorToken']}'}));
    final detail=ProjectModel.fromBackend((await api.getProject(id))!);
    final page=await api.getEligibleProjectPage();final listed=ProjectModel.fromBackend(page.projects.firstWhere((p)=>p['id']==id));
    expect(detail.imageUrl,fixture['imageUrl']);expect(listed.imageUrl,detail.imageUrl);expect(detail.updatedAt,isNotNull);
    expect(ProjectModel.fromJson(detail.toJson()).imageUrl,detail.imageUrl);
    final url=projectImageUrl(detail.imageUrl,apiBaseUrl:base,updatedAt:detail.updatedAt)!;
    final response=await Dio().get<List<int>>(url,options:Options(responseType:ResponseType.bytes));
    expect(response.statusCode,200);expect(response.data,base64Decode(fixture['png'] as String));
    api.dio.close();
  },skip:fixturePath.isEmpty);
}
