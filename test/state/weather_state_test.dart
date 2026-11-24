import 'package:flutter_test/flutter_test.dart';
import 'package:sowsmart/data/weather_repository.dart';
import 'package:sowsmart/domain/weather_advisor.dart';
import 'package:sowsmart/models/field.dart';
import 'package:sowsmart/models/task_item.dart';
import 'package:sowsmart/models/weather_forecast.dart';
import 'package:sowsmart/state/weather_state.dart';

void main() {
  group('WeatherState Tests (Acceptance: With a mocked rainy forecast, irrigation task shows skip badge)', () {
    late FakeWeatherRepository fakeWeatherRepo;
    late WeatherAdvisor advisor;
    late WeatherState weatherState;

    final field = Field(
      id: 'field_rain_test',
      name: 'Rainy Field',
      areaAcres: 2.0,
      soilType: 'clay',
      lat: 11.0,
      lon: 76.0,
      createdAt: DateTime.now(),
    );

    setUp(() {
      advisor = WeatherAdvisor();
      fakeWeatherRepo = FakeWeatherRepository();
      weatherState = WeatherState(
        repository: fakeWeatherRepo,
        advisor: advisor,
      );
    });

    test('With a mocked rainy forecast (>=60% rain), an irrigation task shows skip badge with postpone shortcut', () async {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      // Mock rainy forecast for today: 85% probability, 14.5mm rain
      final rainyForecasts = [
        DailyWeatherForecast(
          date: normalizedToday,
          precipitationSum: 14.5,
          precipitationProbabilityMax: 85,
          windSpeed10mMax: 9.0,
          temperature2mMax: 27.0,
        ),
      ];

      fakeWeatherRepo.result = WeatherForecastResult(
        forecasts: rainyForecasts,
        fetchedAt: DateTime.now(),
        isFromCache: false,
        statusMessage: 'Live forecast',
      );

      // Load forecast for the field
      await weatherState.loadForecastsForFields([field]);

      // Irrigation task due today
      final irrigationTask = TaskItem(
        id: 'task_irr_rain',
        plantingId: 'p1',
        ruleId: 'r_irr',
        type: 'irrigation',
        title: 'Morning Irrigation',
        notes: '',
        stage: 'Vegetative',
        dueDate: normalizedToday,
        originalDueDate: normalizedToday,
        status: 'pending',
      );

      // Evaluate advice
      final advice = weatherState.getAdviceForTask(irrigationTask, field);

      // Acceptance: irrigation task shows skip badge and offers postpone
      expect(advice.type, equals(AdviceType.skipIrrigation));
      expect(advice.title, contains('Skip Irrigation'));
      expect(advice.offerPostpone, isTrue);
    });

    test('With high wind forecast (>15 km/h), a spray task shows spray warning badge', () async {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      final windyForecasts = [
        DailyWeatherForecast(
          date: normalizedToday,
          precipitationSum: 0.0,
          precipitationProbabilityMax: 10,
          windSpeed10mMax: 22.4, // > 15 km/h
          temperature2mMax: 30.0,
        ),
      ];

      fakeWeatherRepo.result = WeatherForecastResult(
        forecasts: windyForecasts,
        fetchedAt: DateTime.now(),
        isFromCache: false,
        statusMessage: 'Live forecast',
      );

      await weatherState.loadForecastsForFields([field]);

      final sprayTask = TaskItem(
        id: 'task_spray_wind',
        plantingId: 'p1',
        ruleId: 'r_spray',
        type: 'spray',
        title: 'Pest Spray',
        notes: '',
        stage: 'Flowering',
        dueDate: normalizedToday,
        originalDueDate: normalizedToday,
        status: 'pending',
      );

      final advice = weatherState.getAdviceForTask(sprayTask, field);

      expect(advice.type, equals(AdviceType.warnSpray));
      expect(advice.title, contains('Poor Spraying Weather'));
      expect(advice.offerPostpone, isTrue);
    });
  });
}
