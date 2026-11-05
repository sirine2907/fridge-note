// Renders every screen into docs/screenshots for the README.
// Run: flutter test test/screenshots --update-goldens
@Tags(['screenshots'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/app.dart';
import 'package:fridge_note/core/di/injection.dart';
import 'package:fridge_note/features/lists/domain/usecases/create_list.dart';
import 'package:fridge_note/features/lists/presentation/bloc/current_list_cubit.dart';

import '../helpers/demo_app.dart';

Future<void> shoot(WidgetTester tester, String name) async {
  await expectLater(find.byType(FridgeNoteApp), matchesGoldenFile('../../docs/screenshots/$name.png'));
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('welcome ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, signedIn: false, location: '/welcome');
      await shoot(tester, '01_welcome_$mode');
      await app.close(tester);
    });

    testWidgets('home ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark);
      await shoot(tester, '02_home_$mode');
      await app.close(tester);
    });

    testWidgets('list ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, location: '/list');
      await shoot(tester, '03_list_$mode');
      await app.close(tester);
    });

    testWidgets('trip ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, location: '/trip');
      await shoot(tester, '04_trip_$mode');
      await app.close(tester);
    });

    testWidgets('usuals ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, location: '/usuals');
      await shoot(tester, '05_usuals_$mode');
      await app.close(tester);
    });

    testWidgets('invite sheet ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, location: '/list');
      await tester.tap(find.byTooltip('Invite'));
      await settle(tester);
      await shoot(tester, '06_invite_$mode');
      await app.close(tester);
    });

    testWidgets('join from a link ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, location: '/invite/MOVIE24');
      await shoot(tester, '09_join_$mode');
      await app.close(tester);
    });

    testWidgets('profile ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, location: '/profile', partner: true);
      await shoot(tester, '07_profile_$mode');
      await app.close(tester);
    });

    testWidgets('empty list ($mode)', (tester) async {
      final app = await pumpDemoApp(tester, dark: dark, location: '/home');
      await tester.runAsync(() async {
        final id = await sl<CreateList>()(name: 'Picnic', store: 'Farmers market');
        sl<CurrentListCubit>().select(id);
      });
      await settle(tester);
      app.go('/list');
      await settle(tester);
      await shoot(tester, '08_empty_list_$mode');
      await app.close(tester);
    });
  }
}
