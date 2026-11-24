import '../models/task_item.dart';
import '../models/weather_forecast.dart';

/// Pure Dart domain service evaluating weather forecasts to provide actionable farm advice.
class WeatherAdvisor {
  /// Evaluates weather conditions for a scheduled task and returns advice.
  /// Always marked with a disclaimer as guidance only.
  WeatherAdvice advise({
    required TaskItem task,
    required List<DailyWeatherForecast> forecasts,
    WeatherConfig config = const WeatherConfig(),
  }) {
    if (forecasts.isEmpty) {
      return WeatherAdvice.none;
    }

    final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final nextDate = taskDate.add(const Duration(days: 1));

    // Find forecast for task due date
    final dueForecast = _findForecast(forecasts, taskDate);
    if (dueForecast == null) {
      // Date outside forecast window
      return WeatherAdvice.none;
    }

    final nextForecast = _findForecast(forecasts, nextDate);

    final taskType = task.type.toLowerCase();

    // 1. Irrigation Advice: Skip if rain is expected today or tomorrow
    if (taskType == 'irrigation') {
      final isRainToday = dueForecast.precipitationProbabilityMax >= config.rainProbabilityThreshold ||
          dueForecast.precipitationSum >= config.precipitationSumThresholdMm;

      final isRainTomorrow = nextForecast != null &&
          (nextForecast.precipitationProbabilityMax >= config.rainProbabilityThreshold ||
              nextForecast.precipitationSum >= config.precipitationSumThresholdMm);

      if (isRainToday || isRainTomorrow) {
        return const WeatherAdvice(
          type: AdviceType.skipIrrigation,
          title: 'Skip Irrigation: Rain Expected',
          message:
              'Significant rainfall forecast on or after due date. Postpone watering to conserve water and prevent waterlogging.',
          offerPostpone: true,
        );
      }
    }

    // 2. Spray Advice: Warn if high wind or rain probability on due date
    if (taskType == 'spray') {
      final highWind = dueForecast.windSpeed10mMax > config.windSpeedMaxKmH;
      final highRainRisk =
          dueForecast.precipitationProbabilityMax >= config.sprayRainProbabilityThreshold;

      if (highWind || highRainRisk) {
        final reason = highWind && highRainRisk
            ? 'High wind (${dueForecast.windSpeed10mMax.toStringAsFixed(1)} km/h) and rain risk'
            : highWind
                ? 'High wind (${dueForecast.windSpeed10mMax.toStringAsFixed(1)} km/h) causing drift'
                : 'Rain risk (${dueForecast.precipitationProbabilityMax}%) causing wash-off';

        return WeatherAdvice(
          type: AdviceType.warnSpray,
          title: 'Poor Spraying Weather',
          message: 'Spraying not recommended: $reason. Consider postponing to a calm day.',
          offerPostpone: true,
        );
      }
    }

    // 3. Heat Alert for Any Task
    if (dueForecast.temperature2mMax > config.temperatureMaxThresholdC) {
      return WeatherAdvice(
        type: AdviceType.heatAlert,
        title: 'Heat Alert (${dueForecast.temperature2mMax.toStringAsFixed(0)}°C)',
        message: 'High temperatures forecast. Carry out operations early in the morning or evening.',
        offerPostpone: false,
      );
    }

    return WeatherAdvice.none;
  }

  DailyWeatherForecast? _findForecast(List<DailyWeatherForecast> forecasts, DateTime targetDate) {
    for (final f in forecasts) {
      if (f.date.year == targetDate.year &&
          f.date.month == targetDate.month &&
          f.date.day == targetDate.day) {
        return f;
      }
    }
    return null;
  }
}
