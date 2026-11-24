import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/weather_repository.dart';
import '../../models/task_item.dart';
import '../../models/weather_forecast.dart';
import '../../state/fields_state.dart';
import '../../state/plantings_state.dart';
import '../../state/tasks_state.dart';
import '../../state/weather_state.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksState = context.watch<TasksState>();
    final fieldsState = context.watch<FieldsState>();
    final plantingsState = context.watch<PlantingsState>();
    final weatherState = context.watch<WeatherState>();
    final theme = Theme.of(context);

    final overdue = tasksState.overdueTasks;
    final dueToday = tasksState.dueTodayTasks;

    // Pick first active field for current weather strip, if available
    final primaryField = fieldsState.fields.isNotEmpty ? fieldsState.fields.first : null;
    final todayWeather = weatherState.getTodayForecast(primaryField);
    final forecastResult = primaryField != null
        ? weatherState.getForecastForField(primaryField.id)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Tasks'),
      ),
      body: Builder(
        builder: (context) {
          if (tasksState.isLoading && tasksState.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Weather Summary Strip
              if (todayWeather != null && primaryField != null) ...[
                _buildWeatherStrip(context, primaryField.name, todayWeather, forecastResult),
                const SizedBox(height: 16),
              ],

              if (overdue.isEmpty && dueToday.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'All Caught Up!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks overdue or due today. Check the calendar to view upcoming schedule.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Overdue Section
              if (overdue.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Overdue Tasks (${overdue.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...overdue.map((t) => _buildTaskCard(
                      context,
                      t,
                      fieldsState,
                      plantingsState,
                      weatherState,
                      isOverdue: true,
                    )),
                const SizedBox(height: 20),
              ],

              // Due Today Section
              if (dueToday.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.today_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due Today (${dueToday.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...dueToday.map((t) => _buildTaskCard(
                      context,
                      t,
                      fieldsState,
                      plantingsState,
                      weatherState,
                      isOverdue: false,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeatherStrip(
    BuildContext context,
    String fieldName,
    DailyWeatherForecast forecast,
    WeatherForecastResult? result,
  ) {
    final theme = Theme.of(context);
    final statusMsg = result?.statusMessage ?? 'Live forecast';

    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Weather: $fieldName',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  statusMsg,
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherItem(
                  Icons.thermostat_rounded,
                  '${forecast.temperature2mMax.toStringAsFixed(1)}°C',
                  'Max Temp',
                  Colors.deepOrange,
                ),
                _buildWeatherItem(
                  Icons.water_drop_outlined,
                  '${forecast.precipitationProbabilityMax}%',
                  'Rain Prob (${forecast.precipitationSum.toStringAsFixed(1)}mm)',
                  Colors.blue,
                ),
                _buildWeatherItem(
                  Icons.air_rounded,
                  '${forecast.windSpeed10mMax.toStringAsFixed(1)} km/h',
                  'Max Wind',
                  Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Weather advice is guidance only. Always confirm with actual field conditions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskItem task,
    FieldsState fieldsState,
    PlantingsState plantingsState,
    WeatherState weatherState, {
    required bool isOverdue,
  }) {
    final tasksState = context.read<TasksState>();
    final theme = Theme.of(context);
    final cropName = tasksState.getCropNameForPlanting(task.plantingId);

    // Compute weather advice for this task
    final field = plantingsState.getFieldForPlanting(task.plantingId, fieldsState.fields);
    final advice = weatherState.getAdviceForTask(task, field);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOverdue ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getTaskIcon(task.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$cropName • ${task.stage}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.shade50
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOverdue
                        ? 'Due ${DateFormat('dd MMM').format(task.dueDate)}'
                        : 'Today',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red.shade800 : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (task.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                task.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],

            // Weather Advice Badge (Phase 5)
            if (advice.type != AdviceType.none) ...[
              const SizedBox(height: 12),
              _buildWeatherAdviceBadge(context, task, advice, tasksState),
            ],

            const SizedBox(height: 14),

            // Action Buttons (Done and Postpone)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showPostponeDialog(context, tasksState, task),
                  icon: const Icon(Icons.schedule_rounded, size: 16),
                  label: const Text('Postpone'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => tasksState.markTaskDone(task),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherAdviceBadge(
    BuildContext context,
    TaskItem task,
    WeatherAdvice advice,
    TasksState tasksState,
  ) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (advice.type) {
      case AdviceType.skipIrrigation:
        bgColor = const Color(0xFFE1F5FE); // Light Blue
        textColor = const Color(0xFF0277BD);
        icon = Icons.umbrella_rounded;
        break;
      case AdviceType.warnSpray:
        bgColor = const Color(0xFFFFF3E0); // Light Orange
        textColor = const Color(0xFFE65100);
        icon = Icons.air_rounded;
        break;
      case AdviceType.heatAlert:
        bgColor = const Color(0xFFFFEBEE); // Light Red
        textColor = const Color(0xFFC62828);
        icon = Icons.whatshot_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  advice.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
              ),
              if (advice.offerPostpone)
                ElevatedButton.icon(
                  onPressed: () async {
                    await tasksState.postponeTask(task, 1);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task postponed by 1 day due to weather advice'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.schedule, size: 14),
                  label: const Text('Postpone 1d', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            advice.message,
            style: TextStyle(fontSize: 11, color: textColor),
          ),
        ],
      ),
    );
  }

  void _showPostponeDialog(
    BuildContext context,
    TasksState tasksState,
    TaskItem task,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Postpone: ${task.title}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Postponing automatically shifts later pending tasks of the same type to maintain interval spacing.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: [1, 2, 3, 5, 7].map((days) {
                    return ActionChip(
                      label: Text('+$days ${days == 1 ? "Day" : "Days"}'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await tasksState.postponeTask(task, days);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getTaskIcon(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation':
        return const CircleAvatar(
          backgroundColor: Color(0xFFE3F2FD),
          child: Icon(Icons.water_drop_rounded, color: Colors.blue),
        );
      case 'fertilizer':
        return const CircleAvatar(
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.grain_rounded, color: Colors.orange),
        );
      case 'spray':
        return const CircleAvatar(
          backgroundColor: Color(0xFFF3E5F5),
          child: Icon(Icons.pest_control_rounded, color: Colors.purple),
        );
      case 'weeding':
        return const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.content_cut_rounded, color: Colors.green),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Color(0xFFECEFF1),
          child: Icon(Icons.task_alt_rounded, color: Colors.grey),
        );
    }
  }
}
