import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sowsmart/data/weather_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('WeatherRepository Tests (Mocked HTTP: Success, Timeout, Malformed JSON)', () {
    late MockHttpClient mockClient;
    late SharedPreferences prefs;
    late OpenMeteoWeatherRepository repository;

    const sampleSuccessJson = '''
    {
      "latitude": 11.0,
      "longitude": 76.0,
      "daily": {
        "time": ["2026-11-21", "2026-11-22"],
        "precipitation_sum": [1.5, 12.0],
        "precipitation_probability_max": [25, 80],
        "wind_speed_10m_max": [10.2, 18.5],
        "temperature_2m_max": [31.0, 28.5]
      }
    }
    ''';

    setUp(() async {
      mockClient = MockHttpClient();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = OpenMeteoWeatherRepository(
        client: mockClient,
        prefs: prefs,
      );
    });

    test('Parses 200 OK Open-Meteo response, caches it, and returns Live status', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(sampleSuccessJson, 200),
      );

      final result = await repository.getForecast(lat: 11.0, lon: 76.0);

      expect(result.isFromCache, isFalse);
      expect(result.statusMessage, equals('Live forecast'));
      expect(result.forecasts.length, equals(2));

      expect(result.forecasts[0].precipitationSum, equals(1.5));
      expect(result.forecasts[0].precipitationProbabilityMax, equals(25));
      expect(result.forecasts[1].precipitationProbabilityMax, equals(80));

      // Verify cached in SharedPreferences
      expect(prefs.getString('weather_cache_11.00_76.00'), isNotNull);
      expect(prefs.getString('weather_time_11.00_76.00'), isNotNull);
    });

    test('Falls back to cache when HTTP request times out', () async {
      // Seed cache with previous forecast updated 2 hours ago
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      await prefs.setString('weather_cache_11.00_76.00', sampleSuccessJson);
      await prefs.setString('weather_time_11.00_76.00', twoHoursAgo.toIso8601String());

      // Simulate network timeout
      when(() => mockClient.get(any())).thenAnswer(
        (_) => throw TimeoutException('Connection timed out'),
      );

      final result = await repository.getForecast(lat: 11.0, lon: 76.0);

      expect(result.isFromCache, isTrue);
      expect(result.forecasts.length, equals(2));
      expect(result.statusMessage, contains('Forecast updated 2 hours ago'));
    });

    test('Handles malformed JSON gracefully by falling back to cache or empty', () async {
      // Simulate server returning corrupted/malformed HTML/JSON
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('<html>502 Bad Gateway</html>', 502),
      );

      final result = await repository.getForecast(lat: 11.0, lon: 76.0);

      // No cache was present, returns empty without crashing
      expect(result.forecasts, isEmpty);
      expect(result.statusMessage, contains('No cached forecast found'));
    });
  });
}
