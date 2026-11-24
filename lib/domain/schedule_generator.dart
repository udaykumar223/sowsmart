import '../models/crop_rule.dart';
import '../models/task_item.dart';

/// Pure Dart domain service to generate a crop calendar schedule
/// based on crop agronomy rules, sowing date, and field soil type.
class ScheduleGenerator {
  /// Generates chronological list of dated tasks for a planting.
  /// Applies soil modifiers to irrigation intervals and calculates expected harvest date.
  List<TaskItem> generate({
    required CropRule crop,
    required DateTime sowingDate,
    required String soilType,
    String plantingId = '',
  }) {
    final List<TaskItem> tasks = [];

    // Normalize sowing date to midnight (clears time component)
    final normalizedSowing = DateTime(
      sowingDate.year,
      sowingDate.month,
      sowingDate.day,
    );

    // Retrieve soil multiplier for irrigation interval (default 1.0)
    final double soilMultiplier = crop.soilModifiers[soilType.toLowerCase()] ?? 1.0;

    int taskCounter = 0;

    for (final rule in crop.tasks) {
      final isIrrigation = rule.type.toLowerCase() == 'irrigation';
      final hasRepeat = rule.repeatEveryDays != null && rule.repeatEveryDays! > 0;

      // Apply soil modifier only to irrigation tasks
      final double intervalBase = hasRepeat ? rule.repeatEveryDays!.toDouble() : 0.0;
      final int effectiveInterval = hasRepeat
          ? (isIrrigation
              ? (intervalBase * soilMultiplier).round().clamp(1, 365)
              : intervalBase.round().clamp(1, 365))
          : 0;

      int currentDay = rule.startDay;
      final int endDay = rule.endDay ?? rule.startDay;

      while (currentDay <= endDay) {
        taskCounter++;
        final dueDate = DateTime(
          normalizedSowing.year,
          normalizedSowing.month,
          normalizedSowing.day + currentDay,
        );

        tasks.add(
          TaskItem(
            id: 'task_${rule.id}_$taskCounter',
            plantingId: plantingId,
            ruleId: rule.id,
            type: rule.type,
            title: rule.title,
            notes: rule.notes,
            stage: rule.stage,
            dueDate: dueDate,
            originalDueDate: dueDate,
            status: 'pending',
          ),
        );

        if (!hasRepeat || effectiveInterval <= 0) {
          break;
        }

        currentDay += effectiveInterval;
      }
    }

    // Sort chronologically by due date
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return tasks;
  }

  /// Calculates expected harvest date from sowing date and crop duration
  DateTime calculateExpectedHarvestDate(DateTime sowingDate, int durationDays) {
    return DateTime(
      sowingDate.year,
      sowingDate.month,
      sowingDate.day + durationDays,
    );
  }
}
