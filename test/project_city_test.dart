import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/backend_snapshot.dart';

void main() {
  test('canonical funding percentage survives API parsing and caching', () {
    final project = ProjectModel.fromBackend({'id': 'funding', 'targetAmount': 50000, 'fundedAmount': 99999, 'fundingProgress': 20});
    expect(project.progressPercentage, 20);
    expect(project.copyWith(name: 'Updated').progressPercentage, 20);
    expect(ProjectModel.fromJson(project.toJson()).progressPercentage, 20);
    expect(ProjectModel.fromBackend({'id': 'zero', 'fundingProgress': -1}).progressPercentage, 0);
  });
  test('city survives API parsing, copies, and cached model round trips', () {
    final project = ProjectModel.fromBackend({'id': 'project', 'city': '  नवी मुंबई  ', 'location': 'Maharashtra'});
    expect(project.cityLabel, 'नवी मुंबई');
    expect(project.locationLabel, 'नवी मुंबई · Maharashtra');
    expect(project.copyWith(name: 'Updated').city, project.city);
    expect(ProjectModel.fromJson(project.toJson()).city, project.city);
    expect(ProjectModel.fromBackend({'id': 'legacy'}).locationLabel, 'Location not specified');
    expect(ProjectModel.fromBackend({'id': 'empty', 'city': '  '}).cityLabel, 'Location not specified');
  });
  test('investment displays the saved project city from real response shape', () {
    final investment = BackendSnapshot.investment({'id': 'investment', 'project': {'id': 'project', 'city': 'पुणे'}});
    expect(investment.projectCityLabel, 'पुणे');
    expect(investment.copyWith(status: 'Completed').projectCity, 'पुणे');
    expect(BackendSnapshot.investment({'id': 'legacy'}).projectCityLabel, 'Location not specified');
  });
}
