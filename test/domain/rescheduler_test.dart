import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/domain/rescheduler.dart';
import 'package:sowsmart/models/task_item.dart';

void main() {
  group('Rescheduler Tests', () {
    late Rescheduler rescheduler;
    late List<TaskItem> sampleTasks;
    final today = DateTime(2026, 6, 10);

    setUp(() {
      rescheduler = Rescheduler();
      sampleTasks = [
        TaskItem(
          id: 'spray_1',
          ruleId: 'r_spray',
          type: 'spray',
          title: 'Protective Spray 1',
          notes: '',
          stage: 'Vegetative',
          dueDate: DateTime(2026, 6, 12),
          originalDueDate: DateTime(2026, 6, 12),
          status: 'pending',
        ),
        TaskItem(
          id: 'spray_2',
          ruleId: 'r_spray',
          type: 'spray',
          title: 'Protective Spray 2',
          notes: '',
          stage: 'Flowering',
          dueDate: DateTime(2026, 6, 22),
          originalDueDate: DateTime(2026, 6, 22),
          status: 'pending',
        ),
        TaskItem(
          id: 'irr_1',
          ruleId: 'r_irr',
          type: 'irrigation',
          title: 'Field Irrigation',
          notes: '',
          stage: 'Vegetative',
          dueDate: DateTime(2026, 6, 15),
          originalDueDate: DateTime(2026, 6, 15),
          status: 'pending',
        ),
        TaskItem(
          id: 'irr_2',
          ruleId: 'r_irr',
          type: 'irrigation',
          title: 'Next Irrigation',
          notes: '',
          stage: 'Vegetative',
          dueDate: DateTime(2026, 6, 20),
          originalDueDate: DateTime(2026, 6, 20),
          status: 'pending',
        ),
        TaskItem(
          id: 'done_spray_0',
          ruleId: 'r_spray',
          type: 'spray',
          title: 'Early Nursery Spray',
          notes: '',
          stage: 'Nursery',
          dueDate: DateTime(2026, 6, 1),
          originalDueDate: DateTime(2026, 6, 1),
          status: 'done',
        ),
      ];
    });

    test('Postponing a spray task shifts later pending spray tasks to preserve interval', () {
      final updated = rescheduler.postponeTask(
        tasks: sampleTasks,
        targetTaskId: 'spray_1',
        daysToPostpone: 3,
        today: today,
      );

      final spray1 = updated.firstWhere((t) => t.id == 'spray_1');
      final spray2 = updated.firstWhere((t) => t.id == 'spray_2');
      final irr1 = updated.firstWhere((t) => t.id == 'irr_1');
      final doneSpray = updated.firstWhere((t) => t.id == 'done_spray_0');

      // spray_1 moved from June 12 to June 15, status becomes 'postponed'
      expect(spray1.dueDate, equals(DateTime(2026, 6, 15)));
      expect(spray1.originalDueDate, equals(DateTime(2026, 6, 12)));
      expect(spray1.status, equals('postponed'));

      // spray_2 moved from June 22 to June 25 to preserve 10-day interval
      expect(spray2.dueDate, equals(DateTime(2026, 6, 25)));
      expect(spray2.status, equals('pending'));

      // Irrigation tasks and completed spray task must NOT change
      expect(irr1.dueDate, equals(DateTime(2026, 6, 15)));
      expect(doneSpray.dueDate, equals(DateTime(2026, 6, 1)));
    });

    test('Postponing irrigation shifts ONLY that task, not subsequent irrigation tasks', () {
      final updated = rescheduler.postponeTask(
        tasks: sampleTasks,
        targetTaskId: 'irr_1',
        daysToPostpone: 2,
        today: today,
      );

      final irr1 = updated.firstWhere((t) => t.id == 'irr_1');
      final irr2 = updated.firstWhere((t) => t.id == 'irr_2');

      // irr_1 moved from June 15 to June 17
      expect(irr1.dueDate, equals(DateTime(2026, 6, 17)));
      expect(irr1.status, equals('postponed'));

      // irr_2 remains at June 20 (weather advice manages irrigation)
      expect(irr2.dueDate, equals(DateTime(2026, 6, 20)));
    });

    test('Postponing the last task of a type works without errors', () {
      final updated = rescheduler.postponeTask(
        tasks: sampleTasks,
        targetTaskId: 'spray_2',
        daysToPostpone: 4,
        today: today,
      );

      final spray2 = updated.firstWhere((t) => t.id == 'spray_2');
      expect(spray2.dueDate, equals(DateTime(2026, 6, 26)));
      expect(spray2.status, equals('postponed'));
    });

    test('Throws ArgumentError if days to postpone is zero or negative', () {
      expect(
        () => rescheduler.postponeTask(
          tasks: sampleTasks,
          targetTaskId: 'spray_1',
          daysToPostpone: 0,
          today: today,
        ),
        throwsArgumentError,
      );

      expect(
        () => rescheduler.postponeTask(
          tasks: sampleTasks,
          targetTaskId: 'spray_1',
          daysToPostpone: -2,
          today: today,
        ),
        throwsArgumentError,
      );
    });

    test('Returns identical list if target task is not found', () {
      final updated = rescheduler.postponeTask(
        tasks: sampleTasks,
        targetTaskId: 'non_existent_id',
        daysToPostpone: 3,
        today: today,
      );

      expect(updated.length, equals(sampleTasks.length));
    });
  });
}
