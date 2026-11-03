import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/widgets/investor_email_preferences.dart';

class _Api extends ApiService {
  final values = {'serviceEmails': true, 'dailyReports': true, 'projectAnnouncements': false};
  bool fail = false;
  @override
  Future<Map<String, bool>> getEmailPreferences() async => Map.of(values);
  @override
  Future<Map<String, bool>> updateEmailPreference(String key, bool value) async {
    if (fail) throw Exception('Unavailable');
    values[key] = value;
    return Map.of(values);
  }
}
void main() {
  testWidgets('project announcements require explicit saved opt-in', (tester) async {
    final api = _Api();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: InvestorEmailPreferences(api: api))));
    await tester.pumpAndSettle();
    expect(tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).last.value, isFalse);
    await tester.tap(find.text('New project announcements'));
    await tester.pumpAndSettle();
    expect(api.values['projectAnnouncements'], isTrue);
    api.fail = true;
    await tester.tap(find.text('New project announcements'));
    await tester.pumpAndSettle();
    expect(tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).last.value, isTrue);
    expect(find.textContaining('Could not save'), findsOneWidget);
  });
}
