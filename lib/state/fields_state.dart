import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/firestore_repository.dart';
import '../models/field.dart';

/// Manages field operations (CRUD, location acquisition, loading/error states).
class FieldsState extends ChangeNotifier {
  final FirestoreRepository _repository;
  String? _uid;

  List<Field> _fields = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Field>>? _subscription;

  FieldsState(this._repository, [this._uid]) {
    if (_uid != null && _uid!.isNotEmpty) {
      _subscribeToFields();
    }
  }

  List<Field> get fields => _fields;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _fields.isEmpty;

  void updateUid(String? newUid) {
    if (_uid == newUid) return;
    _uid = newUid;
    _subscription?.cancel();
    _fields = [];
    if (_uid != null && _uid!.isNotEmpty) {
      _subscribeToFields();
    } else {
      notifyListeners();
    }
  }

  void _subscribeToFields() {
    if (_uid == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _repository.watchFields(_uid!).listen(
      (data) {
        _fields = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load fields: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Look up a field by its ID, returns null if not found.
  Field? getFieldById(String fieldId) {
    return _fields.cast<Field?>().firstWhere(
          (f) => f?.id == fieldId,
          orElse: () => null,
        );
  }

  /// Adds a new field
  Future<bool> addField({
    required String name,
    required double areaAcres,
    required String soilType,
    required double lat,
    required double lon,
  }) async {
    if (_uid == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final field = Field(
        id: 'field_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        areaAcres: areaAcres,
        soilType: soilType.toLowerCase(),
        lat: lat,
        lon: lon,
        createdAt: DateTime.now(),
      );

      await _repository.addField(_uid!, field);
      if (!_fields.any((f) => f.id == field.id)) {
        _fields = [field, ..._fields];
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add field: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing field
  Future<bool> updateField(Field field) async {
    if (_uid == null) return false;
    try {
      await _repository.updateField(_uid!, field);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update field: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a field
  Future<bool> deleteField(String fieldId) async {
    if (_uid == null) return false;
    try {
      await _repository.deleteField(_uid!, fieldId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete field: $e';
      notifyListeners();
      return false;
    }
  }

  /// Acquires user device coordinates via Geolocator with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled on your device.';
        notifyListeners();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission was denied.';
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage =
            'Location permissions are permanently denied. Please enable them in system settings.';
        notifyListeners();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      _errorMessage = 'Could not acquire coordinates: $e';
      notifyListeners();
      return null;
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
