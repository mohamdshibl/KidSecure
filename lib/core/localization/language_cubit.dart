import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<Locale> {
  final SharedPreferences prefs;
  static const _langKey = 'app_language';

  LanguageCubit(this.prefs) : super(const Locale('ar')) {
    _loadLanguage();
  }

  void _loadLanguage() {
    final languageCode = prefs.getString(_langKey) ?? 'ar';
    emit(Locale(languageCode));
  }

  Future<void> toggleLanguage() async {
    final newLanguage = state.languageCode == 'ar' ? 'en' : 'ar';
    await prefs.setString(_langKey, newLanguage);
    emit(Locale(newLanguage));
  }
  
  Future<void> setLanguage(String languageCode) async {
    await prefs.setString(_langKey, languageCode);
    emit(Locale(languageCode));
  }
}
