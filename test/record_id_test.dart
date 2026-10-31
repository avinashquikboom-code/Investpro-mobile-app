import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/widgets/record_id.dart';
import 'package:investpro/app/utils/display_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const id = '21d1f53f-37c5-402a-ae81-a35bc466f4d8';
  test('identity metadata preserves relation IDs, nulls and cached IDs without secrets', () {
    final values = DisplayValue.ids({'id': id, 'displayId': 101, 'projectId': 'project', 'projectDisplayId': 102, 'wallet': {'id': 'wallet', 'displayId': 103}, 'userId': null, 'password': 'private', 'recordIds': {'investmentId': '104'}});
    expect(values, {'id': '101', 'projectId': '102', 'walletId': '103', 'investmentId': '104', 'userId': 'N/A'});
    expect(DisplayValue.text(0), '0');
    expect(DisplayValue.text('9007199254740993'), '9007199254740993');
    DisplayValue.register({'displayIds': {id: 101}});
    expect(DisplayValue.reference(id, internalId: id), '101');
  });
  testWidgets('integer ID fits narrow screen and copy writes the display number', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DisplayValue.register({'displayIds': {id: 101}});
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RecordId(label: 'Investment ID', value: id))));
    expect(find.text('Investment ID: 101'), findsOneWidget);
    await tester.tap(find.byTooltip('Copy Investment ID'));
    await tester.pump();
    expect(copied, '101');
    expect(find.textContaining(id), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
