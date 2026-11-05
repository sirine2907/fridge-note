import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/app.dart';
import 'package:fridge_note/core/demo/demo_partner.dart';
import 'package:fridge_note/core/di/injection.dart';
import 'package:fridge_note/features/auth/presentation/cubit/session_cubit.dart';
import 'package:fridge_note/features/home_screen_widget/data/home_widget_updater.dart';
import 'package:fridge_note/features/profile/presentation/cubit/theme_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone size used for every screenshot (logical pixels).
const phoneSize = Size(390, 844);

bool _fontsLoaded = false;

/// Without real fonts the test renders every letter as a box.
Future<void> loadFonts() async {
  if (_fontsLoaded) return;
  GoogleFonts.config.allowRuntimeFetching = false;
  final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  _fontsLoaded = true;
}

class DemoApp {
  DemoApp(this.session, this.tester);

  final SessionCubit session;
  final WidgetTester tester;

  /// Navigates like a tap on a link would.
  void go(String location) {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  }

  /// Closes the demo session so no timers are left running.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Stream subscriptions are cancelled on the fake clock. Let that finish
    // before the database closes on the real clock, or close() waits forever.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.runAsync(() async {
      await session.signOut();
      await session.close();
      await sl.reset();
    });
  }
}

/// Starts the app in demo mode at [location].
Future<DemoApp> pumpDemoApp(
  WidgetTester tester, {
  String location = '/home',
  bool dark = false,
  bool partner = false,
  bool signedIn = true,
}) async {
  tester.view.physicalSize = phoneSize * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  SessionCubit.closeDelay = Duration.zero;
  HomeWidgetUpdater.enabled = false;
  SharedPreferences.setMockInitialValues({'theme_mode': dark ? 'dark' : 'light'});

  late SessionCubit session;
  await tester.runAsync(() async {
    await loadFonts();
    await sl.reset();
    await initDependencies();
    session = SessionCubit(
      startDemo: sl(),
      restoreSession: sl(),
      signOut: sl(),
      scope: sl(),
      startInDemo: signedIn,
    );
    await session.init();
    if (signedIn && !partner) sl<DemoPartner>().stop();
  });

  await tester.pumpWidget(FridgeNoteApp(
    session: session,
    theme: ThemeCubit(sl()),
    initialLocation: location,
  ));
  await settle(tester);
  return DemoApp(session, tester);
}

/// Lets database streams and Google Fonts finish. They run on real async,
/// outside the fake test clock, so we hand out a bit of real time.
Future<void> settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() async {
      await GoogleFonts.pendingFonts();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Like [settle], but keeps going until [done] is true (or gives up).
/// For things that run on real time, like the fake server's latency.
Future<void> settleUntil(WidgetTester tester, bool Function() done, {int maxRounds = 30}) async {
  for (var i = 0; i < maxRounds && !done(); i++) {
    await settle(tester, rounds: 1);
  }
  await settle(tester, rounds: 1);
}
