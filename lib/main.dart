import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/crop_rules_repository.dart';
import 'data/firestore_repository.dart';
import 'data/notification_service.dart';
import 'data/prefs_service.dart';
import 'data/weather_repository.dart';
import 'domain/profit_calculator.dart';
import 'domain/rescheduler.dart';
import 'domain/schedule_generator.dart';
import 'domain/weather_advisor.dart';
import 'state/auth_state.dart';
import 'state/fields_state.dart';
import 'state/finance_state.dart';
import 'state/plantings_state.dart';
import 'state/settings_state.dart';
import 'state/tasks_state.dart';
import 'state/weather_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences and preferences service
  final prefs = await SharedPreferences.getInstance();
  final prefsService = SharedPrefsService(prefs);

  final settingsState = SettingsState(prefsService);
  await settingsState.loadSettings();

  // Initialize Notification Service
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // Initialize Firebase safely
  FirebaseAuth? firebaseAuth;
  GoogleSignIn? googleSignIn;
  FirestoreRepository firestoreRepository;

  try {
    await Firebase.initializeApp();
    firebaseAuth = FirebaseAuth.instance;
    googleSignIn = GoogleSignIn();
    firestoreRepository = CloudFirestoreRepository();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
    debugPrint('Running with in-memory repository until flutterfire configure is executed.');
    firestoreRepository = InMemoryFirestoreRepository();
  }

  final authState = AuthState(
    firebaseAuth: firebaseAuth,
    googleSignIn: googleSignIn,
  );

  final cropRulesRepo = StaticCropRulesRepository(
    jsonLoader: () => rootBundle.loadString('assets/crop_rules.json'),
  );

  final weatherRepo = OpenMeteoWeatherRepository(
    client: http.Client(),
    prefs: prefs,
  );

  final scheduleGenerator = ScheduleGenerator();
  final rescheduler = Rescheduler();
  final weatherAdvisor = WeatherAdvisor();
  final profitCalculator = ProfitCalculator();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreRepository>.value(value: firestoreRepository),
        Provider<CropRulesRepository>.value(value: cropRulesRepo),
        Provider<WeatherRepository>.value(value: weatherRepo),
        Provider<ScheduleGenerator>.value(value: scheduleGenerator),
        Provider<Rescheduler>.value(value: rescheduler),
        Provider<WeatherAdvisor>.value(value: weatherAdvisor),
        Provider<ProfitCalculator>.value(value: profitCalculator),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<SettingsState>.value(value: settingsState),
        ChangeNotifierProvider<AuthState>.value(value: authState),
        ChangeNotifierProxyProvider<AuthState, FieldsState>(
          create: (context) => FieldsState(
            context.read<FirestoreRepository>(),
            context.read<AuthState>().currentUser?.uid,
          ),
          update: (context, auth, fieldsState) {
            final state = fieldsState ?? FieldsState(context.read<FirestoreRepository>());
            state.updateUid(auth.currentUser?.uid);
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthState, PlantingsState>(
          create: (context) => PlantingsState(
            context.read<FirestoreRepository>(),
            context.read<ScheduleGenerator>(),
            context.read<AuthState>().currentUser?.uid,
          ),
          update: (context, auth, plantingsState) {
            final state = plantingsState ??
                PlantingsState(
                  context.read<FirestoreRepository>(),
                  context.read<ScheduleGenerator>(),
                );
            state.updateUid(auth.currentUser?.uid);
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthState, TasksState>(
          create: (context) => TasksState(
            repository: context.read<FirestoreRepository>(),
            rescheduler: context.read<Rescheduler>(),
            notificationService: context.read<NotificationService>(),
            uid: context.read<AuthState>().currentUser?.uid,
            reminderHour: settingsState.reminderHour,
            reminderMinute: settingsState.reminderMinute,
          ),
          update: (context, auth, tasksState) {
            final state = tasksState ??
                TasksState(
                  repository: context.read<FirestoreRepository>(),
                  rescheduler: context.read<Rescheduler>(),
                  notificationService: context.read<NotificationService>(),
                  reminderHour: settingsState.reminderHour,
                  reminderMinute: settingsState.reminderMinute,
                );
            state.updateUid(auth.currentUser?.uid);
            return state;
          },
        ),
        ChangeNotifierProxyProvider<FieldsState, WeatherState>(
          create: (context) => WeatherState(
            repository: context.read<WeatherRepository>(),
            advisor: context.read<WeatherAdvisor>(),
          ),
          update: (context, fieldsState, weatherState) {
            final state = weatherState ??
                WeatherState(
                  repository: context.read<WeatherRepository>(),
                  advisor: context.read<WeatherAdvisor>(),
                );
            if (fieldsState.fields.isNotEmpty) {
              state.loadForecastsForFields(fieldsState.fields);
            }
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthState, FinanceState>(
          create: (context) => FinanceState(
            context.read<FirestoreRepository>(),
            context.read<ProfitCalculator>(),
            context.read<AuthState>().currentUser?.uid,
          ),
          update: (context, auth, financeState) {
            final state = financeState ??
                FinanceState(
                  context.read<FirestoreRepository>(),
                  context.read<ProfitCalculator>(),
                );
            state.updateUid(auth.currentUser?.uid);
            return state;
          },
        ),
      ],
      child: const SowSmartApp(),
    ),
  );
}
