import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/profile_repository.dart';

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit(this._settings) : super(_settings.loadThemeMode());

  final SettingsRepository _settings;

  Future<void> setMode(AppThemeMode mode) async {
    emit(mode);
    await _settings.saveThemeMode(mode);
  }

  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
