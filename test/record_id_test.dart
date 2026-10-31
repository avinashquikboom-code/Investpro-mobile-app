import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/widgets/record_id.dart';
import 'package:investpro/app/utils/display_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const id = '21d1f53f-37c5-402a-ae81-a35bc466f4d8';
  test('identity metadata preserves relation IDs, nulls and cached IDs without secrets', () {
    final values = DisplayValue.ids({'id': id, 'projectId': 'project', 'wallet': {'id': 'wallet'}, 'userId': null, 'password': 'private', 'recordIds': {'investmentId': 'investment'}});
    expect(values, {'id': id, 'projectId': 'project', 'walletId': 'wallet', 'investmentId': 'investment'});
    expect(DisplayValue.text(0), '0');
    expect(DisplayValue.text('9007199254740993'), '9007199254740993');
    expect(DisplayValue.reference(id, internalId: id), id);
  });
  testWidgets('full UUID fits narrow screen and copy writes the exact ID', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RecordId(label: 'Investment ID', value: id))));
    expect(find.text('Investment ID: $id'), findsOneWidget);
    await tester.tap(find.byTooltip('Copy Investment ID'));
    await tester.pump();
    expect(copied, id);
    expect(tester.takeException(), isNull);
  });
}
