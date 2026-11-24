import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_forecast.dart';

/// Encapsulates the result of fetching a 7-day weather forecast,
/// including offline cache status and last updated age.
class WeatherForecastResult {
  final List<DailyWeatherForecast> forecasts;
  final DateTime fetchedAt;
  final bool isFromCache;
  final String statusMessage;

  const WeatherForecastResult({
    required this.forecasts,
    required this.fetchedAt,
    required this.isFromCache,
    required this.statusMessage,
  });

  static final WeatherForecastResult empty = WeatherForecastResult(
    forecasts: [],
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
    isFromCache: false,
    statusMessage: 'No weather data available',
  );
}

/// Abstract contract for fetching 7-day weather forecasts.
abstract class WeatherRepository {
  Future<WeatherForecastResult> getForecast({
    required double lat,
    required double lon,
  });
}

/// Production implementation calling the free Open-Meteo API (requires no API key).
/// Automatically caches responses locally and falls back to cache when offline.
class OpenMeteoWeatherRepository implements WeatherRepository {
  final http.Client _client;
  final SharedPreferences? _prefs;

  OpenMeteoWeatherRepository({
    http.Client? client,
    SharedPreferences? prefs,
  })  : _client = client ?? http.Client(),
        _prefs = prefs;

  @override
  Future<WeatherForecastResult> getForecast({
    required double lat,
    required double lon,
  }) async {
    // Key formatting to 2 decimal places to cluster nearby field requests
    final cacheKey = 'weather_cache_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
    final timeKey = 'weather_time_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?'
      'latitude=$lat&longitude=$lon'
      '&daily=precipitation_sum,precipitation_probability_max,wind_speed_10m_max,temperature_2m_max'
      '&timezone=auto&forecast_days=7',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final forecasts = _parseOpenMeteoDaily(decoded);

        final now = DateTime.now();

        // Cache the valid response and timestamp
        final prefs = _prefs;
        if (prefs != null) {
          await prefs.setString(cacheKey, response.body);
          await prefs.setString(timeKey, now.toIso8601String());
        }

        return WeatherForecastResult(
          forecasts: forecasts,
          fetchedAt: now,
          isFromCache: false,
          statusMessage: 'Live forecast',
        );
      } else {
        debugPrint('Open-Meteo HTTP error: status ${response.statusCode}');
        return await _loadFromCache(cacheKey, timeKey);
      }
    } catch (e) {
      debugPrint('Open-Meteo fetch failed: $e, falling back to cache');
      return await _loadFromCache(cacheKey, timeKey);
    }
  }

  Future<WeatherForecastResult> _loadFromCache(String cacheKey, String timeKey) async {
    final prefs = _prefs;
    if (prefs == null) {
      return WeatherForecastResult.empty;
    }

    final cachedJson = prefs.getString(cacheKey);
    final cachedTimeStr = prefs.getString(timeKey);

    if (cachedJson != null && cachedTimeStr != null) {
      try {
        final decoded = json.decode(cachedJson) as Map<String, dynamic>;
        final forecasts = _parseOpenMeteoDaily(decoded);
        final cachedTime = DateTime.parse(cachedTimeStr);

        final diff = DateTime.now().difference(cachedTime);
        final status = diff.inHours > 0
            ? 'Forecast updated ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago'
            : 'Forecast updated ${diff.inMinutes} mins ago';

        return WeatherForecastResult(
          forecasts: forecasts,
          fetchedAt: cachedTime,
          isFromCache: true,
          statusMessage: status,
        );
      } catch (e) {
        debugPrint('Error parsing cached weather JSON: $e');
      }
    }

    return WeatherForecastResult(
      forecasts: [],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
      isFromCache: false,
      statusMessage: 'Offline: No cached forecast found',
    );
  }

  List<DailyWeatherForecast> _parseOpenMeteoDaily(Map<String, dynamic> data) {
    final daily = data['daily'] as Map<String, dynamic>?;
    if (daily == null) return [];

    final times = daily['time'] as List<dynamic>? ?? [];
    final precipSums = daily['precipitation_sum'] as List<dynamic>? ?? [];
    final precipProbs = daily['precipitation_probability_max'] as List<dynamic>? ?? [];
    final winds = daily['wind_speed_10m_max'] as List<dynamic>? ?? [];
    final temps = daily['temperature_2m_max'] as List<dynamic>? ?? [];

    final List<DailyWeatherForecast> forecasts = [];

    for (int i = 0; i < times.length; i++) {
      final dateStr = times[i].toString();
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final pSum = i < precipSums.length ? (precipSums[i] as num?)?.toDouble() ?? 0.0 : 0.0;
      final pProb = i < precipProbs.length ? (precipProbs[i] as num?)?.toInt() ?? 0 : 0;
      final wind = i < winds.length ? (winds[i] as num?)?.toDouble() ?? 0.0 : 0.0;
      final temp = i < temps.length ? (temps[i] as num?)?.toDouble() ?? 0.0 : 0.0;

      forecasts.add(
        DailyWeatherForecast(
          date: date,
          precipitationSum: pSum,
          precipitationProbabilityMax: pProb,
          windSpeed10mMax: wind,
          temperature2mMax: temp,
        ),
      );
    }

    return forecasts;
  }
}

/// Fake repository for testing WeatherState and UI with simulated conditions.
class FakeWeatherRepository implements WeatherRepository {
  WeatherForecastResult result;

  FakeWeatherRepository({WeatherForecastResult? initialResult})
      : result = initialResult ?? WeatherForecastResult.empty;

  @override
  Future<WeatherForecastResult> getForecast({
    required double lat,
    required double lon,
  }) async {
    return result;
  }
}
