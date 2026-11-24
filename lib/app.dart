import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'models/field.dart';
import 'models/planting.dart';
import 'screens/auth/login_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/fields/add_edit_field_screen.dart';
import 'screens/fields/fields_screen.dart';
import 'screens/finance/add_transaction_screen.dart';
import 'screens/finance/finance_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/plantings/harvest_screen.dart';
import 'screens/plantings/planting_detail_screen.dart';
import 'screens/plantings/start_planting_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/today/today_screen.dart';
import 'state/auth_state.dart';
import 'state/settings_state.dart';

class SowSmartApp extends StatelessWidget {
  const SowSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsState>();
    final authState = context.read<AuthState>();

    // Configure GoRouter with reactive route guard based on AuthState
    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: authState,
      redirect: (context, state) {
        final isLoggedIn = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }
        if (isLoggedIn && isLoggingIn) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/fields',
          builder: (context, state) => const FieldsScreen(),
        ),
        GoRoute(
          path: '/fields/add',
          builder: (context, state) => const AddEditFieldScreen(),
        ),
        GoRoute(
          path: '/fields/edit/:fieldId',
          builder: (context, state) {
            final field = state.extra as Field?;
            return AddEditFieldScreen(existingField: field);
          },
        ),
        GoRoute(
          path: '/plantings/start',
          builder: (context, state) => const StartPlantingScreen(),
        ),
        GoRoute(
          path: '/plantings/:plantingId',
          builder: (context, state) {
            final planting = state.extra as Planting;
            return PlantingDetailScreen(planting: planting);
          },
        ),
        GoRoute(
          path: '/today',
          builder: (context, state) => const TodayScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinanceScreen(),
        ),
        GoRoute(
          path: '/finance/add-transaction',
          builder: (context, state) {
            final plantingId = state.extra as String?;
            return AddTransactionScreen(initialPlantingId: plantingId);
          },
        ),
        GoRoute(
          path: '/plantings/harvest/:plantingId',
          builder: (context, state) {
            final planting = state.extra as Planting;
            return HarvestScreen(planting: planting);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'SowSmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsState.themeMode,
      locale: settingsState.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
