import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/firestore_repository.dart';
import '../domain/schedule_generator.dart';
import '../models/crop_rule.dart';
import '../models/field.dart';
import '../models/planting.dart';
import '../models/task_item.dart';

/// Manages crop plantings (schedule generation preview, batched creation, progress tracking).
class PlantingsState extends ChangeNotifier {
  final FirestoreRepository _repository;
  final ScheduleGenerator _generator;
  String? _uid;

  List<Planting> _plantings = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Planting>>? _subscription;

  PlantingsState(this._repository, this._generator, [this._uid]) {
    if (_uid != null && _uid!.isNotEmpty) {
      _subscribeToPlantings();
    }
  }

  List<Planting> get plantings => _plantings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _plantings.isEmpty;

  void updateUid(String? newUid) {
    if (_uid == newUid) return;
    _uid = newUid;
    _subscription?.cancel();
    _plantings = [];
    if (_uid != null && _uid!.isNotEmpty) {
      _subscribeToPlantings();
    } else {
      notifyListeners();
    }
  }

  void _subscribeToPlantings() {
    if (_uid == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _repository.watchPlantings(_uid!).listen(
      (data) {
        _plantings = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load plantings: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Previews schedule before saving to Firestore
  List<TaskItem> previewSchedule({
    required CropRule crop,
    required DateTime sowingDate,
    required String soilType,
  }) {
    return _generator.generate(
      crop: crop,
      sowingDate: sowingDate,
      soilType: soilType,
    );
  }

  /// Generates the schedule and writes planting + all tasks in a single atomic batch
  Future<bool> createPlantingWithGeneratedSchedule({
    required String fieldId,
    required CropRule crop,
    required DateTime sowingDate,
    required String seasonLabel,
    required String soilType,
  }) async {
    if (_uid == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plantingId = 'planting_${DateTime.now().millisecondsSinceEpoch}';
      final expectedHarvest =
          _generator.calculateExpectedHarvestDate(sowingDate, crop.durationDays);

      final planting = Planting(
        id: plantingId,
        fieldId: fieldId,
        cropId: crop.cropId,
        cropName: crop.cropName,
        sowingDate: DateTime(sowingDate.year, sowingDate.month, sowingDate.day),
        seasonLabel: seasonLabel.trim(),
        status: 'active',
        expectedHarvestDate: expectedHarvest,
        createdAt: DateTime.now(),
      );

      final tasks = _generator.generate(
        crop: crop,
        sowingDate: sowingDate,
        soilType: soilType,
        plantingId: plantingId,
      );

      // Atomic batched write
      await _repository.createPlantingWithTasks(_uid!, planting, tasks);
      if (!_plantings.any((p) => p.id == planting.id)) {
        _plantings = [planting, ..._plantings];
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create planting: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Stream<List<TaskItem>> watchTasksForPlanting(String plantingId) {
    if (_uid == null) return const Stream.empty();
    return _repository.watchPlantingTasks(_uid!, plantingId);
  }

  /// Finds the Field associated with a given planting
  Field? getFieldForPlanting(String plantingId, List<Field> fields) {
    try {
      final planting = _plantings.firstWhere((p) => p.id == plantingId);
      return fields.firstWhere((f) => f.id == planting.fieldId);
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePlanting(Planting planting) async {
    if (_uid == null) return;
    try {
      await _repository.updatePlanting(_uid!, planting);
    } catch (e) {
      _errorMessage = 'Failed to update planting: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
