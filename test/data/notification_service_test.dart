import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/notification_service.dart';
import 'package:sowsmart/models/task_item.dart';

void main() {
  group('NotificationService Tests (Acceptance: Task due tomorrow scheduled for reminder offline)', () {
    late FakeNotificationService notificationService;

    setUp(() {
      notificationService = FakeNotificationService();
    });

    test('Schedules a notification for a task due tomorrow at chosen reminder time', () async {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      final taskDueTomorrow = TaskItem(
        id: 't_tomorrow',
        ruleId: 'r1',
        type: 'irrigation',
        title: 'Morning Irrigation',
        notes: 'Water the paddy seedlings',
        stage: 'Nursery',
        dueDate: tomorrow,
        originalDueDate: tomorrow,
        status: 'pending',
      );

      // Schedule at 7:00 AM
      await notificationService.scheduleReminders(
        pendingTasks: [taskDueTomorrow],
        reminderHour: 7,
        reminderMinute: 0,
      );

      // Acceptance: Scheduled count is 1, reminder time is 7:00 AM
      expect(notificationService.scheduledCount, equals(1));
      expect(notificationService.lastHour, equals(7));
      expect(notificationService.lastMinute, equals(0));
    });

    test('Schedules tasks within 14-day window and ignores tasks beyond 14 days', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final tasks = [
        // Task 1: Due in 3 days (within window)
        TaskItem(
          id: 't1',
          ruleId: 'r1',
          type: 'irrigation',
          title: 'Irrigation Round 1',
          notes: '',
          stage: 'Tillering',
          dueDate: today.add(const Duration(days: 3)),
          originalDueDate: today.add(const Duration(days: 3)),
          status: 'pending',
        ),
        // Task 2: Due in 10 days (within window)
        TaskItem(
          id: 't2',
          ruleId: 'r2',
          type: 'fertilizer',
          title: 'Top Dressing',
          notes: '',
          stage: 'Tillering',
          dueDate: today.add(const Duration(days: 10)),
          originalDueDate: today.add(const Duration(days: 10)),
          status: 'pending',
        ),
        // Task 3: Due in 25 days (outside 14-day window)
        TaskItem(
          id: 't3',
          ruleId: 'r3',
          type: 'spray',
          title: 'Protective Spray',
          notes: '',
          stage: 'Panicle',
          dueDate: today.add(const Duration(days: 25)),
          originalDueDate: today.add(const Duration(days: 25)),
          status: 'pending',
        ),
      ];

      await notificationService.scheduleReminders(
        pendingTasks: tasks,
        reminderHour: 8,
        reminderMinute: 30,
      );

      // Only the 2 tasks within the 14-day window should be scheduled
      expect(notificationService.scheduledCount, equals(2));
      expect(notificationService.lastHour, equals(8));
      expect(notificationService.lastMinute, equals(30));
    });

    test('Cancelling all reminders clears pending count', () async {
      final now = DateTime.now();
      final task = TaskItem(
        id: 't1',
        ruleId: 'r1',
        type: 'weeding',
        title: 'Manual Weeding',
        notes: '',
        stage: 'Vegetative',
        dueDate: now.add(const Duration(days: 2)),
        originalDueDate: now.add(const Duration(days: 2)),
        status: 'pending',
      );

      await notificationService.scheduleReminders(
        pendingTasks: [task],
        reminderHour: 7,
        reminderMinute: 0,
      );
      expect(notificationService.scheduledCount, equals(1));

      await notificationService.cancelAllReminders();
      expect(notificationService.scheduledCount, equals(0));
    });
  });
}
