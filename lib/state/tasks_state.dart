import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/firestore_repository.dart';
import '../data/notification_service.dart';
import '../domain/rescheduler.dart';
import '../models/planting.dart';
import '../models/task_item.dart';

/// Manages tasks across all plantings for Today screen, Calendar, and Reminder scheduling.
class TasksState extends ChangeNotifier {
  final FirestoreRepository _repository;
  final Rescheduler _rescheduler;
  final NotificationService _notificationService;

  String? _uid;
  int _reminderHour = 7;
  int _reminderMinute = 0;

  List<TaskItem> _tasks = [];
  Map<String, String> _plantingCropNames = {}; // plantingId -> cropName
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, StreamSubscription<List<TaskItem>>> _taskSubscriptions = {};
  StreamSubscription<List<Planting>>? _plantingsSubscription;

  TasksState({
    required FirestoreRepository repository,
    required Rescheduler rescheduler,
    required NotificationService notificationService,
    String? uid,
    int reminderHour = 7,
    int reminderMinute = 0,
  })  : _repository = repository,
        _rescheduler = rescheduler,
        _notificationService = notificationService,
        _uid = uid,
        _reminderHour = reminderHour,
        _reminderMinute = reminderMinute {
    if (_uid != null && _uid!.isNotEmpty) {
      _subscribeToPlantingsAndTasks();
    }
  }

  List<TaskItem> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String getCropNameForPlanting(String plantingId) =>
      _plantingCropNames[plantingId] ?? 'Crop';

  /// Tasks whose due date is prior to today and not yet completed
  List<TaskItem> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return taskDate.isBefore(today) && t.status != 'done' && t.status != 'skipped';
    }).toList();
  }

  /// Tasks due strictly today and not yet completed
  List<TaskItem> get dueTodayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return taskDate.isAtSameMomentAs(today) &&
          t.status != 'done' &&
          t.status != 'skipped';
    }).toList();
  }

  /// Groups tasks by date for the calendar view
  Map<DateTime, List<TaskItem>> get tasksByDate {
    final Map<DateTime, List<TaskItem>> map = {};
    for (final task in _tasks) {
      final normalizedDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      map.putIfAbsent(normalizedDate, () => []).add(task);
    }
    return map;
  }

  void updateUid(String? newUid) {
    if (_uid == newUid) return;
    _uid = newUid;
    _clearSubscriptions();
    _tasks = [];
    _plantingCropNames = {};
    if (_uid != null && _uid!.isNotEmpty) {
      _subscribeToPlantingsAndTasks();
    } else {
      notifyListeners();
    }
  }

  void updateReminderTime(int hour, int minute) {
    _reminderHour = hour;
    _reminderMinute = minute;
    refreshReminders();
  }

  void _clearSubscriptions() {
    _plantingsSubscription?.cancel();
    for (final sub in _taskSubscriptions.values) {
      sub.cancel();
    }
    _taskSubscriptions.clear();
  }

  void _subscribeToPlantingsAndTasks() {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();

    _plantingsSubscription = _repository.watchPlantings(_uid!).listen((plantings) {
      _plantingCropNames = {
        for (final p in plantings) p.id: '${p.cropName} (${p.seasonLabel})',
      };

      // Watch tasks for each active planting
      final activePlantings = plantings.where((p) => p.status == 'active').toList();
      final activeIds = activePlantings.map((p) => p.id).toSet();

      // Cancel removed plantings
      _taskSubscriptions.removeWhere((id, sub) {
        if (!activeIds.contains(id)) {
          sub.cancel();
          return true;
        }
        return false;
      });

      for (final p in activePlantings) {
        if (!_taskSubscriptions.containsKey(p.id)) {
          _taskSubscriptions[p.id] =
              _repository.watchPlantingTasks(_uid!, p.id).listen((plantingTasks) {
            _updateTasksForPlanting(p.id, plantingTasks);
          });
        }
      }

      if (activePlantings.isEmpty) {
        _tasks = [];
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (e) {
      _errorMessage = 'Failed to load plantings tasks: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  void _updateTasksForPlanting(String plantingId, List<TaskItem> plantingTasks) {
    // Replace existing tasks for this planting
    _tasks.removeWhere((t) => t.plantingId == plantingId);
    _tasks.addAll(plantingTasks);
    _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _isLoading = false;
    notifyListeners();

    refreshReminders();
  }

  /// Marks task as completed ('done')
  Future<bool> markTaskDone(TaskItem task) async {
    if (_uid == null) return false;
    try {
      final updatedTask = task.copyWith(
        status: 'done',
        completedAt: DateTime.now(),
      );

      // Local optimistic update
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = updatedTask;
        notifyListeners();
      }

      await _repository.updateTask(_uid!, task.plantingId, updatedTask);
      refreshReminders();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark task done: $e';
      notifyListeners();
      return false;
    }
  }

  /// Postpones a task and shifts subsequent rounds via Rescheduler in a batched write
  Future<bool> postponeTask(TaskItem task, int daysToPostpone) async {
    if (_uid == null || daysToPostpone <= 0) return false;

    try {
      final plantingTasks = _tasks.where((t) => t.plantingId == task.plantingId).toList();

      final updatedTasks = _rescheduler.postponeTask(
        tasks: plantingTasks,
        targetTaskId: task.id,
        daysToPostpone: daysToPostpone,
        today: DateTime.now(),
      );

      // Optimistic local update
      for (final updated in updatedTasks) {
        final idx = _tasks.indexWhere((t) => t.id == updated.id);
        if (idx != -1) {
          _tasks[idx] = updated;
        }
      }
      notifyListeners();

      // Batched write to Firestore
      await _repository.batchUpdateTasks(_uid!, task.plantingId, updatedTasks);

      refreshReminders();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to postpone task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Refreshes local notification reminders for next 14 days
  Future<void> refreshReminders() async {
    final pending = _tasks.where((t) => t.status != 'done' && t.status != 'skipped').toList();
    await _notificationService.scheduleReminders(
      pendingTasks: pending,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
    );
  }

  @override
  void dispose() {
    _clearSubscriptions();
    super.dispose();
  }
}
