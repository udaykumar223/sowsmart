import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_item.dart';

/// Abstract interface for local reminder notifications, allowing tests to run without platform channels.
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> scheduleReminders({
    required List<TaskItem> pendingTasks,
    required int reminderHour,
    required int reminderMinute,
  });
  Future<void> cancelAllReminders();
}

/// Production implementation using flutter_local_notifications and timezone.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission error: $e');
      return false;
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  @override
  Future<void> scheduleReminders({
    required List<TaskItem> pendingTasks,
    required int reminderHour,
    required int reminderMinute,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Cancel existing scheduled notifications to avoid duplicate stacking
    await cancelAllReminders();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxWindow = today.add(const Duration(days: 14));

    // Filter tasks due within the 14-day scheduling window
    final upcomingTasks = pendingTasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return !taskDate.isBefore(today) && taskDate.isBefore(maxWindow);
    }).toList();

    int notificationId = 1000;

    for (final task in upcomingTasks) {
      notificationId++;

      // Compute scheduled time at farmer's configured reminder time
      final scheduledDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
        reminderHour,
        reminderMinute,
      );

      // Only schedule if target time is in the future
      if (scheduledDate.isAfter(now)) {
        try {
          final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

          const androidDetails = AndroidNotificationDetails(
            'crop_reminders_channel',
            'Crop Tasks Reminders',
            channelDescription: 'Notifications for daily crop management tasks',
            importance: Importance.high,
            priority: Priority.high,
          );

          const notificationDetails = NotificationDetails(android: androidDetails);

          await _plugin.zonedSchedule(
            id: notificationId,
            title: 'SowSmart: ${task.title}',
            body: 'Due today: ${task.stage} (${task.type})',
            scheduledDate: tzScheduled,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
          );
        } catch (e) {
          debugPrint('Failed to schedule reminder for task ${task.id}: $e');
        }
      }
    }
  }
}

/// In-memory fake notification service for testing and development.
class FakeNotificationService implements NotificationService {
  int scheduledCount = 0;
  bool permissionGranted = true;
  int lastHour = 7;
  int lastMinute = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> cancelAllReminders() async {
    scheduledCount = 0;
  }

  @override
  Future<void> scheduleReminders({
    required List<TaskItem> pendingTasks,
    required int reminderHour,
    required int reminderMinute,
  }) async {
    lastHour = reminderHour;
    lastMinute = reminderMinute;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxWindow = today.add(const Duration(days: 14));

    scheduledCount = pendingTasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return !taskDate.isBefore(today) && taskDate.isBefore(maxWindow);
    }).length;
  }
}
