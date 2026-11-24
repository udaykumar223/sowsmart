import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/planting.dart';
import '../../state/auth_state.dart';
import '../../state/fields_state.dart';
import '../../state/plantings_state.dart';
import '../../state/tasks_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthState>();
    final fieldsState = context.watch<FieldsState>();
    final plantingsState = context.watch<PlantingsState>();
    final tasksState = context.watch<TasksState>();
    final theme = Theme.of(context);
    final user = authState.currentUser;

    final urgentCount = tasksState.overdueTasks.length + tasksState.dueTodayTasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Welcome Banner
          Card(
            color: theme.colorScheme.primaryContainer.withAlpha(128),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.waving_hand_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.welcome}, ${user?.displayName ?? "Farmer"}!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email != null
                        ? l10n.signedInAs(user!.email!)
                        : l10n.signedInAs('farmer@sowsmart.app'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Navigation Grid (Today, Calendar, Fields, Plantings)
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Today\'s Tasks',
                  subtitle: urgentCount > 0 ? '$urgentCount due / overdue' : 'All done!',
                  icon: Icons.checklist_rounded,
                  color: urgentCount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                  badge: urgentCount > 0 ? '$urgentCount' : null,
                  onTap: () => context.push('/today'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Crop Calendar',
                  subtitle: 'Month schedule',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.blue.shade700,
                  onTap: () => context.push('/calendar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Fields (${fieldsState.fields.length})',
                  subtitle: 'Plots & soil types',
                  icon: Icons.landscape_rounded,
                  color: Colors.brown.shade600,
                  onTap: () => context.push('/fields'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Start Planting',
                  subtitle: 'Generate schedule',
                  icon: Icons.add_circle_outline_rounded,
                  color: Colors.teal.shade700,
                  onTap: () => context.push('/plantings/start'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            title: 'Profit & Finance',
            subtitle: 'Track costs, revenue & yield',
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.indigo.shade700,
            onTap: () => context.push('/finance'),
          ),
          const SizedBox(height: 24),

          // Active Plantings Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Plantings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (plantingsState.plantings.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/plantings/start'),
                  child: const Text('+ New Crop'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (plantingsState.isLoading && plantingsState.plantings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (plantingsState.plantings.isEmpty)
            Card(
              elevation: 0.5,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.eco_outlined, size: 40, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    const Text('No active plantings yet.'),
                    const SizedBox(height: 4),
                    const Text(
                      'Select a field and crop to generate a customized task schedule.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/plantings/start'),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                      label: const Text('Start First Planting'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...plantingsState.plantings.map((p) => _buildPlantingTile(context, p)),

          const SizedBox(height: 24),

          // Phase 4 Completion Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Phase 4: Today, Calendar & Reminders Active',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('✓ Today screen with Overdue & Due-Today groupings'),
                  const SizedBox(height: 4),
                  const Text('✓ Mark Done & Postpone with automatic interval shifts'),
                  const SizedBox(height: 4),
                  const Text('✓ Month Calendar with colored task type dots'),
                  const SizedBox(height: 4),
                  const Text('✓ Local notifications for next 14 days at custom reminder time'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantingTile(BuildContext context, Planting planting) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.eco_rounded, color: theme.colorScheme.primary),
        ),
        title: Text(
          planting.cropName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Sown ${dateFormat.format(planting.sowingDate)} • Harvest ~${dateFormat.format(planting.expectedHarvestDate)}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () => context.push('/plantings/${planting.id}', extra: planting),
      ),
    );
  }
}
