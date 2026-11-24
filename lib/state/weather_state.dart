import 'package:flutter/foundation.dart';
import '../data/weather_repository.dart';
import '../domain/weather_advisor.dart';
import '../models/field.dart';
import '../models/task_item.dart';
import '../models/weather_forecast.dart';

/// Manages fetching, caching, and serving weather forecasts and agronomic advice.
class WeatherState extends ChangeNotifier {
  final WeatherRepository _repository;
  final WeatherAdvisor _advisor;
  final WeatherConfig _config;

  final Map<String, WeatherForecastResult> _fieldForecasts = {};
  bool _isLoading = false;
  String? _errorMessage;

  WeatherState({
    required WeatherRepository repository,
    WeatherAdvisor? advisor,
    WeatherConfig config = const WeatherConfig(),
  })  : _repository = repository,
        _advisor = advisor ?? WeatherAdvisor(),
        _config = config;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WeatherForecastResult? getForecastForField(String fieldId) =>
      _fieldForecasts[fieldId];

  /// Loads weather forecasts for all registered fields
  Future<void> loadForecastsForFields(List<Field> fields) async {
    if (fields.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final field in fields) {
        if (field.lat != 0.0 || field.lon != 0.0) {
          final result = await _repository.getForecast(
            lat: field.lat,
            lon: field.lon,
          );
          _fieldForecasts[field.id] = result;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load weather: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Evaluates weather advice for a specific task using the field's forecast
  WeatherAdvice getAdviceForTask(TaskItem task, Field? field) {
    if (field == null) return WeatherAdvice.none;

    final result = _fieldForecasts[field.id];
    if (result == null || result.forecasts.isEmpty) {
      return WeatherAdvice.none;
    }

    return _advisor.advise(
      task: task,
      forecasts: result.forecasts,
      config: _config,
    );
  }

  /// Returns today's forecast for the given field, if available
  DailyWeatherForecast? getTodayForecast(Field? field) {
    if (field == null) return null;
    final result = _fieldForecasts[field.id];
    if (result == null || result.forecasts.isEmpty) return null;

    final today = DateTime.now();
    for (final f in result.forecasts) {
      if (f.date.year == today.year &&
          f.date.month == today.month &&
          f.date.day == today.day) {
        return f;
      }
    }
    return result.forecasts.first;
  }
}
