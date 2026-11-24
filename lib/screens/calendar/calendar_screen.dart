import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/task_item.dart';
import '../../models/weather_forecast.dart';
import '../../state/fields_state.dart';
import '../../state/plantings_state.dart';
import '../../state/tasks_state.dart';
import '../../state/weather_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
  }

  List<TaskItem> _getTasksForDay(DateTime day, Map<DateTime, List<TaskItem>> tasksByDate) {
    final normalized = DateTime(day.year, day.month, day.day);
    return tasksByDate[normalized] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = context.watch<TasksState>();
    final fieldsState = context.watch<FieldsState>();
    final plantingsState = context.watch<PlantingsState>();
    final weatherState = context.watch<WeatherState>();
    final theme = Theme.of(context);
    final tasksByDate = tasksState.tasksByDate;

    final selectedTasks = _selectedDay != null
        ? _getTasksForDay(_selectedDay!, tasksByDate)
        : <TaskItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Calendar'),
      ),
      body: Column(
        children: [
          // TableCalendar Month View
          Card(
            margin: const EdgeInsets.all(12),
            child: TableCalendar<TaskItem>(
              firstDay: DateTime(DateTime.now().year - 1),
              lastDay: DateTime(DateTime.now().year + 2),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: (day) => _getTasksForDay(day, tasksByDate),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 4,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(4).map((task) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getTaskColor(task.type),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),

          // Selected Day Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay != null
                      ? DateFormat('EEEE, dd MMMM').format(_selectedDay!)
                      : 'Selected Day',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${selectedTasks.length} ${selectedTasks.length == 1 ? "task" : "tasks"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // Tasks for the Selected Day
          Expanded(
            child: selectedTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks scheduled for this day',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return _buildTaskTile(
                        context,
                        task,
                        tasksState,
                        fieldsState,
                        plantingsState,
                        weatherState,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    TaskItem task,
    TasksState state,
    FieldsState fieldsState,
    PlantingsState plantingsState,
    WeatherState weatherState,
  ) {
    final isDone = task.status == 'done';
    final cropName = state.getCropNameForPlanting(task.plantingId);

    final field = plantingsState.getFieldForPlanting(task.plantingId, fieldsState.fields);
    final advice = weatherState.getAdviceForTask(task, field);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _getTaskColor(task.type).withAlpha(40),
                child: Icon(
                  _getTaskIconData(task.type),
                  color: _getTaskColor(task.type),
                  size: 20,
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text('$cropName • ${task.stage}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDone) ...[
                    IconButton(
                      icon: const Icon(Icons.schedule_rounded, size: 20),
                      tooltip: 'Postpone 1 day',
                      onPressed: () => state.postponeTask(task, 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                      tooltip: 'Mark Done',
                      onPressed: () => state.markTaskDone(task),
                    ),
                  ] else
                    const Chip(
                      label: Text('DONE', style: TextStyle(fontSize: 10, color: Colors.green)),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            if (advice.type != AdviceType.none)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: advice.type == AdviceType.skipIrrigation
                        ? Colors.blue.shade50
                        : advice.type == AdviceType.warnSpray
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        advice.type == AdviceType.skipIrrigation
                            ? Icons.umbrella_rounded
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: advice.type == AdviceType.skipIrrigation
                            ? Colors.blue.shade800
                            : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          advice.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: advice.type == AdviceType.skipIrrigation
                                ? Colors.blue.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTaskColor(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation':
        return Colors.blue;
      case 'fertilizer':
        return Colors.orange;
      case 'spray':
        return Colors.purple;
      case 'weeding':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskIconData(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation':
        return Icons.water_drop_rounded;
      case 'fertilizer':
        return Icons.grain_rounded;
      case 'spray':
        return Icons.pest_control_rounded;
      case 'weeding':
        return Icons.content_cut_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }
}
