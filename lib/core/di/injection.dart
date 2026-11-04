import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import 'session_scope.dart';

/// The service locator. App-wide things are registered here at start-up;
/// per-user things live in [SessionScope].
final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl())
    ..registerLazySingleton<SessionScope>(() => GetItSessionScope(sl))
    ..registerFactory(() => StartDemo(sl()))
    ..registerFactory(() => RestoreSession(sl()))
    ..registerFactory(() => SendEmailCode(sl()))
    ..registerFactory(() => VerifyEmailCode(sl()))
    ..registerFactory(() => SignOut(sl()));
}
