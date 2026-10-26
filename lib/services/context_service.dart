import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Automatic signals: where the user is, what the sky is doing.
///
/// Everything degrades to a stub — the app never blocks on sensors.
class DeviceContext {
  const DeviceContext({
    this.latitude,
    this.longitude,
    this.placeLabel = 'Your neighborhood',
    this.temperatureC,
    this.weatherCode = -1,
    this.traveling = false,
  });

  final double? latitude;
  final double? longitude;
  final String placeLabel;
  final double? temperatureC;

  /// Open-Meteo WMO weather code; -1 = unknown.
  final int weatherCode;
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
        temperatureC: weather.temperatureC,
        weatherCode: weather.code,
        traveling: traveling,
      );
    } catch (_) {
      return _stub();
    }
  }

  DeviceContext _stub() => const DeviceContext(
        placeLabel: 'Your neighborhood',
        temperatureC: 19,
        weatherCode: 1,
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

  /// Keyless current weather from Open-Meteo.
  Future<({double? temperatureC, int code})> _weather(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,weather_code',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return (temperatureC: null, code: -1);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      return (
        temperatureC: (current?['temperature_2m'] as num?)?.toDouble(),
        code: (current?['weather_code'] as num?)?.toInt() ?? -1,
      );
    } catch (_) {
      return (temperatureC: null, code: -1);
    }
  }
}
