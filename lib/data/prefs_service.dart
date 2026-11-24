import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Abstract service interface for local key-value preferences.
/// Concrete implementation uses SharedPreferences, keeping callers decoupled.
abstract class PrefsService {
  Future<String?> getLanguageCode();
  Future<void> saveLanguageCode(String code);
  Future<String?> getThemeMode();
  Future<void> saveThemeMode(String mode);
  Future<int> getReminderHour();
  Future<int> getReminderMinute();
  Future<void> saveReminderTime(int hour, int minute);
}

class SharedPrefsService implements PrefsService {
  final SharedPreferences _prefs;

  SharedPrefsService(this._prefs);

  @override
  Future<String?> getLanguageCode() async {
    return _prefs.getString(AppConstants.keyLanguage);
  }

  @override
  Future<void> saveLanguageCode(String code) async {
    await _prefs.setString(AppConstants.keyLanguage, code);
  }

  @override
  Future<String?> getThemeMode() async {
    return _prefs.getString(AppConstants.keyThemeMode);
  }

  @override
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(AppConstants.keyThemeMode, mode);
  }

  @override
  Future<int> getReminderHour() async {
    return _prefs.getInt(AppConstants.keyReminderHour) ?? AppConstants.defaultReminderHour;
  }

  @override
  Future<int> getReminderMinute() async {
    return _prefs.getInt(AppConstants.keyReminderMinute) ?? AppConstants.defaultReminderMinute;
  }

  @override
  Future<void> saveReminderTime(int hour, int minute) async {
    await _prefs.setInt(AppConstants.keyReminderHour, hour);
    await _prefs.setInt(AppConstants.keyReminderMinute, minute);
  }
}
