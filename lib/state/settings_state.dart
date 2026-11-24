import 'package:flutter/material.dart';
import '../data/prefs_service.dart';

/// Manages application-wide user settings (language, theme, reminder times).
class SettingsState extends ChangeNotifier {
  final PrefsService _prefsService;

  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;
  int _reminderHour = 7;
  int _reminderMinute = 0;
  bool _isInitialized = false;

  SettingsState(this._prefsService);

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get isInitialized => _isInitialized;

  /// Loads persisted settings from SharedPreferences on application startup.
  Future<void> loadSettings() async {
    final langCode = await _prefsService.getLanguageCode();
    if (langCode != null && (langCode == 'en' || langCode == 'te')) {
      _locale = Locale(langCode);
    }

    final modeString = await _prefsService.getThemeMode();
    if (modeString != null) {
      if (modeString == ThemeMode.light.name) {
        _themeMode = ThemeMode.light;
      } else if (modeString == ThemeMode.dark.name) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    _reminderHour = await _prefsService.getReminderHour();
    _reminderMinute = await _prefsService.getReminderMinute();

    _isInitialized = true;
    notifyListeners();
  }

  /// Updates language and persists preference.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    await _prefsService.saveLanguageCode(newLocale.languageCode);
  }

  /// Updates theme mode (Light, Dark, System) and persists preference.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefsService.saveThemeMode(mode.name);
  }

  /// Updates preferred notification reminder time and persists preference.
  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    notifyListeners();
    await _prefsService.saveReminderTime(hour, minute);
  }
}
