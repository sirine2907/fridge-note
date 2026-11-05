import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/core/router/app_router.dart';
import 'package:fridge_note/features/auth/domain/entities/app_user.dart';
import 'package:fridge_note/features/auth/presentation/cubit/session_cubit.dart';
import 'package:fridge_note/features/home_screen_widget/data/home_widget_updater.dart';

import '../helpers/fixtures.dart';

const signedOut = SessionState(status: SessionStatus.signedOut);
const signedIn = SessionState(
  status: SessionStatus.signedIn,
  user: AppUser(id: 'sirine', name: 'Sirine', color: 1),
);

void main() {
  group('redirectFor', () {
    test('signed out people land on the welcome screen', () {
      expect(redirectFor(signedOut, Uri.parse('/home')), '/welcome');
      expect(redirectFor(signedOut, Uri.parse('/welcome')), isNull);
    });

    test('an invite link is remembered through sign in', () {
      expect(
        redirectFor(signedOut, Uri.parse('/invite/MOVIE24')),
        '/welcome?next=%2Finvite%2FMOVIE24',
      );
      expect(redirectFor(signedIn, Uri.parse('/welcome?next=%2Finvite%2FMOVIE24')), '/invite/MOVIE24');
    });

    test('signed in people skip the welcome screen', () {
      expect(redirectFor(signedIn, Uri.parse('/welcome')), '/home');
      expect(redirectFor(signedIn, Uri.parse('/list')), isNull);
    });

    test('an https invite link opened in the app drops the GitHub Pages folder', () {
      expect(redirectFor(signedIn, Uri.parse('/fridge-note/invite/K7Q2MX')), '/invite/K7Q2MX');
    });
  });

  group('home widget texts', () {
    test('lists the open items and how many are left', () {
      final values = HomeWidgetUpdater.widgetValues(
        weeklyList(shopper: anis),
        [milk(), milk(id: 'eggs', name: 'Eggs', checked: true)],
      );
      expect(values['list_name'], 'Weekly groceries');
      expect(values['items_left'], '1 left');
      expect(values['items'], '•  Milk   2 L');
      expect(values['shopper'], 'Anis is shopping');
    });

    test('cuts long lists and says how many more', () {
      final items = [for (var i = 0; i < 9; i++) milk(id: '$i', name: 'Item $i')];
      final values = HomeWidgetUpdater.widgetValues(weeklyList(), items, maxLines: 6);
      final lines = values['items']!.split('\n');
      expect(lines, hasLength(7));
      expect(lines.last, '+ 3 more');
    });

    test('says when everything is done', () {
      final values = HomeWidgetUpdater.widgetValues(weeklyList(), [milk(checked: true)]);
      expect(values['items_left'], 'All done');
      expect(values['items'], 'Nothing left to buy.');
    });
  });
}
