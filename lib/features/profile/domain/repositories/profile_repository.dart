import '../../../lists/domain/entities/member.dart';

abstract class ProfileRepository {
  Stream<Member?> watchProfile(String userId);

  /// Creates the profile row the first time someone signs in.
  Future<void> ensureProfile(Member member);

  Future<void> updateProfile(String userId, {String? name, int? color});
}

enum AppThemeMode { system, light, dark }

/// Settings that only live on this phone.
abstract class SettingsRepository {
  AppThemeMode loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);
}
