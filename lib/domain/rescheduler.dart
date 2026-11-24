import '../models/task_item.dart';

/// Pure Dart domain service to handle postponing tasks and shifting dependent pending rounds.
class Rescheduler {
  /// Postpones the target task by [daysToPostpone] days.
  ///
  /// Rules:
  /// 1. Target task's due date shifts by [daysToPostpone], status becomes 'postponed'.
  /// 2. Target task retains its originalDueDate.
  /// 3. If target task is NOT irrigation, every later pending task of the same type
  ///    in that planting also shifts by [daysToPostpone] days to preserve intervals.
  /// 4. Irrigation tasks do not automatically shift later tasks (weather handles them).
  /// 5. Tasks are never moved before [today].
  List<TaskItem> postponeTask({
    required List<TaskItem> tasks,
    required String targetTaskId,
    required int daysToPostpone,
    required DateTime today,
  }) {
    if (daysToPostpone <= 0) {
      throw ArgumentError('Days to postpone must be greater than zero');
    }

    final normalizedToday = DateTime(today.year, today.month, today.day);

    final targetIndex = tasks.indexWhere((t) => t.id == targetTaskId);
    if (targetIndex == -1) {
      return List<TaskItem>.from(tasks);
    }

    final targetTask = tasks[targetIndex];
    final originalDue = targetTask.dueDate;
    final newTargetDue = DateTime(
      originalDue.year,
      originalDue.month,
      originalDue.day + daysToPostpone,
    );

    // Rule: Never move a task before today
    if (newTargetDue.isBefore(normalizedToday)) {
      throw ArgumentError('Rescheduled date cannot be prior to today');
    }

    final updatedTasks = <TaskItem>[];
    final isIrrigation = targetTask.type.toLowerCase() == 'irrigation';

    for (final task in tasks) {
      if (task.id == targetTaskId) {
        // Shift target task and mark as postponed
        updatedTasks.add(
          task.copyWith(
            dueDate: newTargetDue,
            status: 'postponed',
          ),
        );
      } else if (!isIrrigation &&
          task.type.toLowerCase() == targetTask.type.toLowerCase() &&
          task.status == 'pending' &&
          task.dueDate.isAfter(originalDue)) {
        // Shift later pending tasks of the same type to maintain interval
        final newLaterDue = DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day + daysToPostpone,
        );
        updatedTasks.add(
          task.copyWith(dueDate: newLaterDue),
        );
      } else {
        // Other tasks remain unchanged
        updatedTasks.add(task);
      }
    }

    return updatedTasks;
  }
}
