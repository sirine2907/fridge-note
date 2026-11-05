import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/supabase_email_auth_source.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/invite/data/supabase_invite_repository.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../config/env.dart';
import '../supabase/supabase_sync_remote.dart';
import 'session_scope.dart';

/// The service locator. App-wide things are registered here at start-up;
/// per-user things live in [SessionScope].
final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  // Without keys (tests, the web demo) the app only offers demo mode.
  SupabaseClient? supabase;
  if (Env.hasSupabase) {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseKey);
    supabase = Supabase.instance.client;
  }

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(email: supabase == null ? null : SupabaseEmailAuthSource(supabase)),
    )
    ..registerLazySingleton<SessionScope>(
      () => GetItSessionScope(
        sl,
        realRemote: supabase == null
            ? null
            : (user) => (
                  remote: SupabaseSyncRemote(supabase!),
                  invites: SupabaseInviteRepository(supabase),
                ),
      ),
    )
    ..registerFactory(() => StartDemo(sl()))
    ..registerFactory(() => RestoreSession(sl()))
    ..registerFactory(() => SendEmailCode(sl()))
    ..registerFactory(() => VerifyEmailCode(sl()))
    ..registerFactory(() => SignOut(sl()));
}
