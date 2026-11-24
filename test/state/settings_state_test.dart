import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/prefs_service.dart';
import 'package:sowsmart/state/settings_state.dart';

class FakePrefsService implements PrefsService {
  String? languageCode;
  String? themeMode;
  int reminderHour = 7;
  int reminderMinute = 0;

  @override
  Future<String?> getLanguageCode() async => languageCode;

  @override
  Future<void> saveLanguageCode(String code) async {
    languageCode = code;
  }

  @override
  Future<String?> getThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(String mode) async {
    themeMode = mode;
  }

  @override
  Future<int> getReminderHour() async => reminderHour;

  @override
  Future<int> getReminderMinute() async => reminderMinute;

  @override
  Future<void> saveReminderTime(int hour, int minute) async {
    reminderHour = hour;
    reminderMinute = minute;
  }
}

void main() {
  group('SettingsState Tests', () {
    late FakePrefsService fakePrefs;
    late SettingsState settingsState;

    setUp(() {
      fakePrefs = FakePrefsService();
      settingsState = SettingsState(fakePrefs);
    });

    test('Initializes with default English locale and system theme mode', () {
      expect(settingsState.locale.languageCode, equals('en'));
      expect(settingsState.themeMode, equals(ThemeMode.system));
      expect(settingsState.isInitialized, isFalse);
    });

    test('Loads persisted Telugu locale and Dark theme from preferences', () async {
      fakePrefs.languageCode = 'te';
      fakePrefs.themeMode = 'dark';
      fakePrefs.reminderHour = 8;
      fakePrefs.reminderMinute = 30;

      await settingsState.loadSettings();

      expect(settingsState.isInitialized, isTrue);
      expect(settingsState.locale.languageCode, equals('te'));
      expect(settingsState.themeMode, equals(ThemeMode.dark));
      expect(settingsState.reminderHour, equals(8));
      expect(settingsState.reminderMinute, equals(30));
    });

    test('Updates locale and persists to PrefsService', () async {
      await settingsState.loadSettings();
      expect(settingsState.locale.languageCode, equals('en'));

      await settingsState.setLocale(const Locale('te'));

      expect(settingsState.locale.languageCode, equals('te'));
      expect(fakePrefs.languageCode, equals('te'));
    });

    test('Updates theme mode and persists to PrefsService', () async {
      await settingsState.loadSettings();

      await settingsState.setThemeMode(ThemeMode.light);

      expect(settingsState.themeMode, equals(ThemeMode.light));
      expect(fakePrefs.themeMode, equals('light'));
    });
  });
}
