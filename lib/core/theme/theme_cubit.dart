import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'theme_mode';
  static const String _dismissedBroadcastsKey = 'dismissed_broadcasts';
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final themeString = prefs.getString(_themeKey);
    if (themeString == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.toString() == themeString,
      orElse: () => ThemeMode.system,
    );
  }

  void toggleTheme() {
    final nextMode = state == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _prefs.setString(_themeKey, nextMode.toString());
    emit(nextMode);
  }

  void setTheme(ThemeMode mode) {
    _prefs.setString(_themeKey, mode.toString());
    emit(mode);
  }

  List<String> get dismissedBroadcastIds =>
      _prefs.getStringList(_dismissedBroadcastsKey) ?? [];

  void dismissBroadcast(String id) {
    final current = dismissedBroadcastIds;
    if (!current.contains(id)) {
      _prefs.setStringList(_dismissedBroadcastsKey, [...current, id]);
      emit(state); // Trigger rebuild of listener components
    }
  }
}
