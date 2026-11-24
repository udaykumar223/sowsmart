import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/domain/weather_advisor.dart';
import 'package:sowsmart/models/task_item.dart';
import 'package:sowsmart/models/weather_forecast.dart';

void main() {
  group('WeatherAdvisor Tests', () {
    late WeatherAdvisor advisor;
    const config = WeatherConfig(
      rainProbabilityThreshold: 60.0,
      precipitationSumThresholdMm: 5.0,
      windSpeedMaxKmH: 15.0,
      sprayRainProbabilityThreshold: 40.0,
      temperatureMaxThresholdC: 38.0,
    );

    setUp(() {
      advisor = WeatherAdvisor();
    });

    test('Advises skip irrigation when rain probability >= 60% on due date', () {
      final task = TaskItem(
        id: 'irr_1',
        ruleId: 'r1',
        type: 'irrigation',
        title: 'Morning Irrigation',
        notes: '',
        stage: 'Vegetative',
        dueDate: DateTime(2026, 7, 10),
        originalDueDate: DateTime(2026, 7, 10),
        status: 'pending',
      );

      final forecasts = [
        DailyWeatherForecast(
          date: DateTime(2026, 7, 10),
          precipitationSum: 2.0,
          precipitationProbabilityMax: 75, // >= 60%
          windSpeed10mMax: 8.0,
          temperature2mMax: 30.0,
        ),
      ];

      final advice = advisor.advise(task: task, forecasts: forecasts, config: config);

      expect(advice.type, equals(AdviceType.skipIrrigation));
      expect(advice.offerPostpone, isTrue);
      expect(advice.title, contains('Skip Irrigation'));
    });

    test('Advises skip irrigation when rainfall >= 5mm is forecast for the NEXT day', () {
      final task = TaskItem(
        id: 'irr_2',
        ruleId: 'r1',
        type: 'irrigation',
        title: 'Field Irrigation',
        notes: '',
        stage: 'Vegetative',
        dueDate: DateTime(2026, 7, 10),
        originalDueDate: DateTime(2026, 7, 10),
        status: 'pending',
      );

      final forecasts = [
        DailyWeatherForecast(
          date: DateTime(2026, 7, 10),
          precipitationSum: 0.0,
          precipitationProbabilityMax: 20,
          windSpeed10mMax: 8.0,
          temperature2mMax: 31.0,
        ),
        DailyWeatherForecast(
          date: DateTime(2026, 7, 11), // Next day heavy rain
          precipitationSum: 12.5, // >= 5.0 mm
          precipitationProbabilityMax: 85,
          windSpeed10mMax: 12.0,
          temperature2mMax: 28.0,
        ),
      ];

      final advice = advisor.advise(task: task, forecasts: forecasts, config: config);

      expect(advice.type, equals(AdviceType.skipIrrigation));
      expect(advice.offerPostpone, isTrue);
    });

    test('Advises spray warning when wind speed exceeds 15 km/h', () {
      final task = TaskItem(
        id: 'spray_1',
        ruleId: 'r2',
        type: 'spray',
        title: 'Fungicide Spray',
        notes: '',
        stage: 'Flowering',
        dueDate: DateTime(2026, 7, 12),
        originalDueDate: DateTime(2026, 7, 12),
        status: 'pending',
      );

      final forecasts = [
        DailyWeatherForecast(
          date: DateTime(2026, 7, 12),
          precipitationSum: 0.0,
          precipitationProbabilityMax: 10,
          windSpeed10mMax: 19.5, // > 15 km/h
          temperature2mMax: 32.0,
        ),
      ];

      final advice = advisor.advise(task: task, forecasts: forecasts, config: config);

      expect(advice.type, equals(AdviceType.warnSpray));
      expect(advice.title, contains('Poor Spraying Weather'));
      expect(advice.message, contains('High wind'));
    });

    test('Advises heat alert when temperature exceeds 38 C', () {
      final task = TaskItem(
        id: 'weed_1',
        ruleId: 'r3',
        type: 'weeding',
        title: 'Manual Weeding',
        notes: '',
        stage: 'Vegetative',
        dueDate: DateTime(2026, 7, 14),
        originalDueDate: DateTime(2026, 7, 14),
        status: 'pending',
      );

      final forecasts = [
        DailyWeatherForecast(
          date: DateTime(2026, 7, 14),
          precipitationSum: 0.0,
          precipitationProbabilityMax: 0,
          windSpeed10mMax: 6.0,
          temperature2mMax: 41.2, // > 38 C
        ),
      ];

      final advice = advisor.advise(task: task, forecasts: forecasts, config: config);

      expect(advice.type, equals(AdviceType.heatAlert));
      expect(advice.title, contains('Heat Alert'));
    });

    test('Returns none when forecast is empty or date is beyond window', () {
      final task = TaskItem(
        id: 'irr_far',
        ruleId: 'r1',
        type: 'irrigation',
        title: 'Later Irrigation',
        notes: '',
        stage: 'Maturity',
        dueDate: DateTime(2026, 9, 20), // Far in future
        originalDueDate: DateTime(2026, 9, 20),
        status: 'pending',
      );

      final forecasts = [
        DailyWeatherForecast(
          date: DateTime(2026, 7, 10),
          precipitationSum: 1.0,
          precipitationProbabilityMax: 10,
          windSpeed10mMax: 5.0,
          temperature2mMax: 30.0,
        ),
      ];

      final advice = advisor.advise(task: task, forecasts: forecasts, config: config);
      expect(advice.type, equals(AdviceType.none));

      // With completely empty forecasts
      final emptyAdvice = advisor.advise(task: task, forecasts: [], config: config);
      expect(emptyAdvice.type, equals(AdviceType.none));
    });
  });
}
