import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_state.dart';
import '../../state/settings_state.dart';
import '../../state/tasks_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthState>();
    final settingsState = context.watch<SettingsState>();
    final theme = Theme.of(context);
    final user = authState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Farmer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'No email',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (authState.isDemoMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Demo Mode (Offline)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Preferences Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              'Preferences & Reminders',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Settings Options Card
          Card(
            child: Column(
              children: [
                // Language Switch Tile
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(l10n.language),
                  subtitle: Text(
                    settingsState.locale.languageCode == 'te'
                        ? l10n.telugu
                        : l10n.english,
                  ),
                  trailing: DropdownButton<String>(
                    value: settingsState.locale.languageCode,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(l10n.english),
                      ),
                      DropdownMenuItem(
                        value: 'te',
                        child: Text(l10n.telugu),
                      ),
                    ],
                    onChanged: (code) {
                      if (code != null) {
                        settingsState.setLocale(Locale(code));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),

                // Theme Mode Switch Tile
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(
                    settingsState.themeMode == ThemeMode.light
                        ? 'Light'
                        : settingsState.themeMode == ThemeMode.dark
                            ? 'Dark'
                            : 'System Default',
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: settingsState.themeMode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        settingsState.setThemeMode(mode);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),

                // Daily Reminder Time Picker
                ListTile(
                  leading: const Icon(Icons.alarm_rounded),
                  title: const Text('Daily Task Reminder Time'),
                  subtitle: Text(
                    _formatTime(settingsState.reminderHour, settingsState.reminderMinute),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: settingsState.reminderHour,
                        minute: settingsState.reminderMinute,
                      ),
                    );
                    if (picked != null) {
                      await settingsState.setReminderTime(picked.hour, picked.minute);
                      if (context.mounted) {
                        context.read<TasksState>().updateReminderTime(
                              picked.hour,
                              picked.minute,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reminder time updated to ${_formatTime(picked.hour, picked.minute)}',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),

                // Permission Request Tile
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Notification Permission'),
                  subtitle: const Text('Required for offline task alerts'),
                  trailing: TextButton(
                    onPressed: () async {
                      final notifService = context.read<NotificationService>();
                      final granted = await notifService.requestPermission();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              granted
                                  ? 'Notifications enabled successfully'
                                  : 'Notification permission was denied',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Grant'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // App Information
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('About SowSmart'),
              subtitle: Text('Phase 4: Today, Calendar & Reminders (v1.0.0)'),
            ),
          ),
          const SizedBox(height: 32),

          // Sign Out Button
          ElevatedButton.icon(
            onPressed: () async {
              await authState.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.signOut),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}
