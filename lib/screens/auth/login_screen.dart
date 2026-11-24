import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_state.dart';
import '../../state/settings_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthState>();
    final settingsState = context.watch<SettingsState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.agriculture_rounded,
                      size: 52,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Title
                  Text(
                    l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Language Switcher Card on Login
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.language_rounded, size: 22),
                      title: Text(
                        l10n.language,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: settingsState.locale.languageCode,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(12),
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
                  ),
                  const SizedBox(height: 32),

                  // Error notification if present
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: TextStyle(color: theme.colorScheme.onErrorContainer),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: authState.clearError,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Sign-in Button
                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ElevatedButton.icon(
                      onPressed: () => authState.signInWithGoogle(),
                      icon: const Icon(Icons.login_rounded),
                      label: Text(l10n.signInWithGoogle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => authState.signInDemo(),
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('Continue as Demo Farmer (Offline Test)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text(
                    'Guidance & Scheduling for Smart Farming',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
