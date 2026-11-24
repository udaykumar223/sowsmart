import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/firestore_repository.dart';
import 'package:sowsmart/data/notification_service.dart';
import 'package:sowsmart/domain/rescheduler.dart';
import 'package:sowsmart/models/planting.dart';
import 'package:sowsmart/models/task_item.dart';
import 'package:sowsmart/state/tasks_state.dart';

void main() {
  group('TasksState Tests (Today Screen, Calendar & Reminders)', () {
    late InMemoryFirestoreRepository repo;
    late Rescheduler rescheduler;
    late FakeNotificationService notificationService;
    const testUid = 'user_tasks_test';

    setUp(() {
      repo = InMemoryFirestoreRepository();
      rescheduler = Rescheduler();
      notificationService = FakeNotificationService();
    });

    test('Separates overdue tasks and due-today tasks correctly', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      final planting = Planting(
        id: 'p1',
        fieldId: 'f1',
        cropId: 'paddy',
        cropName: 'Paddy IR20',
        sowingDate: today.subtract(const Duration(days: 20)),
        seasonLabel: 'Kharif',
        status: 'active',
        expectedHarvestDate: today.add(const Duration(days: 100)),
        createdAt: DateTime.now(),
      );

      final tasks = [
        // Overdue task
        TaskItem(
          id: 't_overdue',
          plantingId: 'p1',
          ruleId: 'r1',
          type: 'fertilizer',
          title: 'Overdue Fertilizer',
          notes: '',
          stage: 'Tillering',
          dueDate: yesterday,
          originalDueDate: yesterday,
          status: 'pending',
        ),
        // Due today task
        TaskItem(
          id: 't_today',
          plantingId: 'p1',
          ruleId: 'r2',
          type: 'irrigation',
          title: 'Today Irrigation',
          notes: '',
          stage: 'Tillering',
          dueDate: today,
          originalDueDate: today,
          status: 'pending',
        ),
        // Future task
        TaskItem(
          id: 't_future',
          plantingId: 'p1',
          ruleId: 'r3',
          type: 'spray',
          title: 'Tomorrow Spray',
          notes: '',
          stage: 'Tillering',
          dueDate: tomorrow,
          originalDueDate: tomorrow,
          status: 'pending',
        ),
      ];

      // Save planting and tasks in repo
      await repo.createPlantingWithTasks(testUid, planting, tasks);

      final state = TasksState(
        repository: repo,
        rescheduler: rescheduler,
        notificationService: notificationService,
        uid: testUid,
      );

      // Wait for stream to deliver tasks
      await Future<void>.delayed(Duration.zero);

      expect(state.overdueTasks.length, equals(1));
      expect(state.overdueTasks.first.id, equals('t_overdue'));

      expect(state.dueTodayTasks.length, equals(1));
      expect(state.dueTodayTasks.first.id, equals('t_today'));
    });

    test('Marking task done updates status and completedAt timestamp', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final planting = Planting(
        id: 'p2',
        fieldId: 'f1',
        cropId: 'tomato',
        cropName: 'Tomato Hybrid',
        sowingDate: today,
        seasonLabel: 'Rabi',
        status: 'active',
        expectedHarvestDate: today.add(const Duration(days: 120)),
        createdAt: DateTime.now(),
      );

      final task = TaskItem(
        id: 't_done_test',
        plantingId: 'p2',
        ruleId: 'r1',
        type: 'weeding',
        title: 'Hand Weeding',
        notes: '',
        stage: 'Vegetative',
        dueDate: today,
        originalDueDate: today,
        status: 'pending',
      );

      await repo.createPlantingWithTasks(testUid, planting, [task]);

      final state = TasksState(
        repository: repo,
        rescheduler: rescheduler,
        notificationService: notificationService,
        uid: testUid,
      );
      await Future<void>.delayed(Duration.zero);

      final success = await state.markTaskDone(task);
      expect(success, isTrue);

      final updatedTask = state.tasks.firstWhere((t) => t.id == 't_done_test');
      expect(updatedTask.status, equals('done'));
      expect(updatedTask.completedAt, isNotNull);
      expect(state.dueTodayTasks, isEmpty);
    });

    test('Postponing task shifts dependent tasks in single batched write and refreshes reminders', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final planting = Planting(
        id: 'p3',
        fieldId: 'f1',
        cropId: 'tomato',
        cropName: 'Tomato Hybrid',
        sowingDate: today,
        seasonLabel: 'Rabi',
        status: 'active',
        expectedHarvestDate: today.add(const Duration(days: 120)),
        createdAt: DateTime.now(),
      );

      final spray1 = TaskItem(
        id: 'spray_1',
        plantingId: 'p3',
        ruleId: 'r_spray',
        type: 'spray',
        title: 'Protective Spray Round 1',
        notes: '',
        stage: 'Vegetative',
        dueDate: today,
        originalDueDate: today,
        status: 'pending',
      );

      final spray2 = TaskItem(
        id: 'spray_2',
        plantingId: 'p3',
        ruleId: 'r_spray',
        type: 'spray',
        title: 'Protective Spray Round 2',
        notes: '',
        stage: 'Flowering',
        dueDate: today.add(const Duration(days: 10)),
        originalDueDate: today.add(const Duration(days: 10)),
        status: 'pending',
      );

      await repo.createPlantingWithTasks(testUid, planting, [spray1, spray2]);

      final state = TasksState(
        repository: repo,
        rescheduler: rescheduler,
        notificationService: notificationService,
        uid: testUid,
      );
      await Future<void>.delayed(Duration.zero);

      // Postpone spray_1 by 2 days
      final success = await state.postponeTask(spray1, 2);
      expect(success, isTrue);

      final updatedSpray1 = state.tasks.firstWhere((t) => t.id == 'spray_1');
      final updatedSpray2 = state.tasks.firstWhere((t) => t.id == 'spray_2');

      // spray1 moved from today to today + 2
      expect(updatedSpray1.dueDate, equals(today.add(const Duration(days: 2))));
      expect(updatedSpray1.status, equals('postponed'));

      // spray2 automatically shifted by 2 days to maintain 10-day interval
      expect(updatedSpray2.dueDate, equals(today.add(const Duration(days: 12))));

      // Verify reminders were updated
      expect(notificationService.scheduledCount, greaterThan(0));
    });
  });
}
