import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';
import 'features/profile/presentation/cubit/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean URLs on the web (/invite/CODE instead of /#/invite/CODE).
  usePathUrlStrategy();
  // The Outfit font files are bundled in assets/fonts.
  GoogleFonts.config.allowRuntimeFetching = false;

  await initDependencies();

  final session = SessionCubit(
    startDemo: sl(),
    restoreSession: sl(),
    signOut: sl(),
    scope: sl(),
    startInDemo: Env.startInDemo,
  );
  await session.init();

  runApp(FridgeNoteApp(session: session, theme: ThemeCubit(sl())));
}
