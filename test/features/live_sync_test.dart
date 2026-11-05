import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/core/demo/demo_seed.dart';
import 'package:fridge_note/core/demo/fake_remote.dart';
import 'package:fridge_note/core/di/injection.dart';
import 'package:fridge_note/core/sync/record_patch.dart';
import 'package:fridge_note/features/lists/presentation/widgets/item_card.dart';

import '../helpers/demo_app.dart';

/// The whole app in demo mode: real database, real sync engine, fake server.
void main() {
  Map<String, Object?> serverMilk() =>
      sl<FakeRemote>().rowsOf('items').firstWhere((i) => i['name'] == 'Milk');

  bool isChecked(WidgetTester tester, String name) {
    final strike = tester.widget<StrikeText>(find.widgetWithText(StrikeText, name));
    return strike.struck;
  }

  testWidgets('a check-off on the other phone shows up on this one', (tester) async {
    final app = await pumpDemoApp(tester, location: '/list');
    expect(isChecked(tester, 'Milk'), isFalse);

    // Anis, walking the list from the top, checks off the first open item.
    await tester.runAsync(() async {
      final remote = sl<FakeRemote>();
      final milk = remote.rowsOf('items').firstWhere((i) => i['name'] == 'Milk');
      remote.receive(RecordPatch.local(
        table: 'items',
        id: milk['id'] as String,
        at: DateTime.now().millisecondsSinceEpoch,
        values: {'checked': true, 'checked_by': DemoSeed.anisId},
      ));
    });
    await settleUntil(tester, () => isChecked(tester, 'Milk'));

    expect(isChecked(tester, 'Milk'), isTrue);
    expect(find.text('Got by Anis'), findsWidgets);
    await app.close(tester);
  });

  testWidgets('checking an item here reaches the server', (tester) async {
    final app = await pumpDemoApp(tester, location: '/list');

    await tester.tap(find.byType(CheckCircle).first);
    await settleUntil(tester, () => serverMilk()['checked'] == true);

    expect(serverMilk()['checked'], isTrue);
    expect(isChecked(tester, 'Milk'), isTrue);
    await app.close(tester);
  });

  testWidgets('offline, the change waits and the list says so', (tester) async {
    final app = await pumpDemoApp(tester, location: '/list');
    sl<FakeRemote>().online = false;
    await settle(tester);

    await tester.tap(find.byType(CheckCircle).first);
    await settleUntil(tester, () => find.textContaining('waiting').evaluate().isNotEmpty);

    expect(isChecked(tester, 'Milk'), isTrue, reason: 'the screen reads the local database');
    expect(find.text('Offline · 2 changes waiting'), findsOneWidget);
    expect(serverMilk()['checked'], isFalse);

    sl<FakeRemote>().online = true;
    await settleUntil(tester, () => find.text('Synced').evaluate().isNotEmpty);

    expect(serverMilk()['checked'], isTrue);
    expect(find.text('Synced'), findsOneWidget);
    await app.close(tester);
  });
}
