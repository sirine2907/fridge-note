import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/local_clock.dart';
import '../../../core/sync/local_store.dart';
import '../../../core/sync/record_patch.dart';
import '../../lists/domain/entities/member.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.db, required this.store, required this.clock});

  final AppDatabase db;
  final LocalStore store;
  final LocalClock clock;

  @override
  Stream<Member?> watchProfile(String userId) {
    final query = db.select(db.profiles)..where((p) => p.id.equals(userId));
    return query.watchSingleOrNull().map(
          (row) => row == null ? null : Member(id: row.id, name: row.name, color: row.color),
        );
  }

  @override
  Future<void> ensureProfile(Member member) async {
    final existing = await (db.select(db.profiles)..where((p) => p.id.equals(member.id)))
        .getSingleOrNull();
    if (existing != null) return;
    // Time 1 instead of now: if the server already has a profile with a real
    // name, that one is newer and wins when it arrives.
    await store.applyLocal([
      RecordPatch.local(
        table: 'profiles',
        id: member.id,
        at: 1,
        values: {'name': member.name, 'color': member.color},
      ),
    ]);
  }

  @override
  Future<void> updateProfile(String userId, {String? name, int? color}) {
    return store.applyLocal([
      RecordPatch.local(table: 'profiles', id: userId, at: clock.next(), values: {
        // "?" leaves the key out when the value is null.
        'name': ?name,
        'color': ?color,
      }),
    ]);
  }
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'theme_mode';

  @override
  AppThemeMode loadThemeMode() {
    final saved = _prefs.getString(_themeKey);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) => _prefs.setString(_themeKey, mode.name);
}
