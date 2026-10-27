import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sidequests/models/weather.dart';

/// Automatic signals: where the user is, what the sky is doing.
///
/// Everything degrades to a stub. The app never blocks on sensors.
class DeviceContext {
  const DeviceContext({
    this.latitude,
    this.longitude,
    this.placeLabel = 'Your neighborhood',
    this.temperatureC,
    this.weatherCode = -1,
    this.weather,
    this.traveling = false,
  });

  final double? latitude;
  final double? longitude;
  final String placeLabel;
  final double? temperatureC;

  /// Open-Meteo WMO weather code; -1 = unknown.
  final int weatherCode;

  /// Full weather (current + hourly + daily). Null when unknown.
  final WeatherInfo? weather;
  final bool traveling;
}

class ContextService {
  ContextService({this.useDeviceSensors = false});

  bool useDeviceSensors;

  Future<DeviceContext> current({
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    if (!useDeviceSensors) return _stub();
    try {
      final position = await _position();
      if (position == null) return _stub();
      final weather = await _weather(position.latitude, position.longitude);

      var traveling = false;
      if (homeLatitude != null && homeLongitude != null) {
        final meters = Geolocator.distanceBetween(
          homeLatitude,
          homeLongitude,
          position.latitude,
          position.longitude,
        );
        traveling = meters > 80000;
      }
      return DeviceContext(
        latitude: position.latitude,
        longitude: position.longitude,
        placeLabel: traveling ? 'Somewhere new' : 'Nearby',
        temperatureC: weather?.temperatureC,
        weatherCode: weather?.code ?? -1,
        weather: weather,
        traveling: traveling,
      );
    } catch (_) {
      return _stub();
    }
  }

  DeviceContext _stub() => DeviceContext(
        placeLabel: 'Your neighborhood',
        temperatureC: 19,
        weatherCode: 1,
        weather: WeatherInfo.sample(),
      );

  Future<Position?> _position() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 8),
    );
  }

  /// Keyless current + hourly + daily weather from Open-Meteo.
  Future<WeatherInfo?> _weather(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,weather_code'
        '&hourly=temperature_2m,weather_code'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        '&forecast_days=5&timezone=auto',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      final current = body['current'] as Map<String, dynamic>?;
      final temp = (current?['temperature_2m'] as num?)?.toDouble();
      final code = (current?['weather_code'] as num?)?.toInt() ?? -1;
      if (temp == null) return null;

      final hourly = _parseHourly(body['hourly']);
      final daily = _parseDaily(body['daily']);
      return WeatherInfo(
        temperatureC: temp,
        code: code,
        highC: daily.isNotEmpty ? daily.first.maxC : temp,
        lowC: daily.isNotEmpty ? daily.first.minC : temp,
        hourly: hourly,
        daily: daily,
      );
    } catch (_) {
      return null;
    }
  }

  List<HourlyPoint> _parseHourly(Object? json) {
    try {
      final map = json as Map<String, dynamic>;
      final times = (map['time'] as List?) ?? [];
      final temps = (map['temperature_2m'] as List?) ?? [];
      final codes = (map['weather_code'] as List?) ?? [];
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final nowIso =
          '${now.year}-${two(now.month)}-${two(now.day)}T${two(now.hour)}:00';

      var start = times.indexWhere((t) => t.toString().compareTo(nowIso) >= 0);
      if (start < 0) start = 0;
      final points = <HourlyPoint>[];
      for (var i = start; i < times.length && points.length < 8; i++) {
        final temp = i < temps.length ? (temps[i] as num?)?.toDouble() : null;
        if (temp == null) continue;
        points.add(HourlyPoint(
          timeIso: times[i].toString(),
          temperatureC: temp,
          code: i < codes.length ? (codes[i] as num?)?.toInt() ?? -1 : -1,
        ));
      }
      return points;
    } catch (_) {
      return [];
    }
  }

  List<DailyPoint> _parseDaily(Object? json) {
    try {
      final map = json as Map<String, dynamic>;
      final dates = (map['date'] as List?) ?? (map['time'] as List?) ?? [];
      final maxes = (map['temperature_2m_max'] as List?) ?? [];
      final mins = (map['temperature_2m_min'] as List?) ?? [];
      final codes = (map['weather_code'] as List?) ?? [];
      final points = <DailyPoint>[];
      for (var i = 0; i < dates.length && points.length < 5; i++) {
        final max = i < maxes.length ? (maxes[i] as num?)?.toDouble() : null;
        final min = i < mins.length ? (mins[i] as num?)?.toDouble() : null;
        if (max == null || min == null) continue;
        points.add(DailyPoint(
          dateIso: dates[i].toString().substring(0, 10),
          maxC: max,
          minC: min,
          code: i < codes.length ? (codes[i] as num?)?.toInt() ?? -1 : -1,
        ));
      }
      return points;
    } catch (_) {
      return [];
    }
  }
}
