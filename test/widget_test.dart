import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sowsmart/app.dart';
import 'package:sowsmart/data/crop_rules_repository.dart';
import 'package:sowsmart/data/firestore_repository.dart';
import 'package:sowsmart/data/notification_service.dart';
import 'package:sowsmart/data/weather_repository.dart';
import 'package:sowsmart/domain/rescheduler.dart';
import 'package:sowsmart/domain/schedule_generator.dart';
import 'package:sowsmart/domain/weather_advisor.dart';
import 'package:sowsmart/state/auth_state.dart';
import 'package:sowsmart/state/fields_state.dart';
import 'package:sowsmart/state/plantings_state.dart';
import 'package:sowsmart/state/settings_state.dart';
import 'package:sowsmart/state/tasks_state.dart';
import 'package:sowsmart/state/weather_state.dart';
import 'state/settings_state_test.dart';

void main() {
  testWidgets('SowSmartApp launches and renders LoginScreen when unauthenticated',
      (WidgetTester tester) async {
    final fakePrefs = FakePrefsService();
    final settingsState = SettingsState(fakePrefs);
    await settingsState.loadSettings();

    final authState = AuthState();
    final repo = InMemoryFirestoreRepository();
    final generator = ScheduleGenerator();
    final rescheduler = Rescheduler();
    final notifService = FakeNotificationService();
    final cropRepo = StaticCropRulesRepository(jsonLoader: () async => '[]');
    final weatherRepo = FakeWeatherRepository();
    final weatherAdvisor = WeatherAdvisor();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirestoreRepository>.value(value: repo),
          Provider<CropRulesRepository>.value(value: cropRepo),
          Provider<WeatherRepository>.value(value: weatherRepo),
          Provider<ScheduleGenerator>.value(value: generator),
          Provider<Rescheduler>.value(value: rescheduler),
          Provider<WeatherAdvisor>.value(value: weatherAdvisor),
          Provider<NotificationService>.value(value: notifService),
          ChangeNotifierProvider<SettingsState>.value(value: settingsState),
          ChangeNotifierProvider<AuthState>.value(value: authState),
          ChangeNotifierProvider<FieldsState>(
            create: (_) => FieldsState(repo),
          ),
          ChangeNotifierProvider<PlantingsState>(
            create: (_) => PlantingsState(repo, generator),
          ),
          ChangeNotifierProvider<TasksState>(
            create: (_) => TasksState(
              repository: repo,
              rescheduler: rescheduler,
              notificationService: notifService,
            ),
          ),
          ChangeNotifierProvider<WeatherState>(
            create: (_) => WeatherState(
              repository: weatherRepo,
              advisor: weatherAdvisor,
            ),
          ),
        ],
        child: const SowSmartApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app title and Login screen components appear
    expect(find.text('SowSmart'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });
}
