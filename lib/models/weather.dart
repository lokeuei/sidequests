/// Weather data from Open-Meteo (keyless). Pure Dart, no Flutter imports.
class WeatherInfo {
  const WeatherInfo({
    required this.temperatureC,
    required this.code,
    required this.highC,
    required this.lowC,
    required this.hourly,
    required this.daily,
  });

  final double temperatureC;
  final int code;
  final double highC;
  final double lowC;
  final List<HourlyPoint> hourly;
  final List<DailyPoint> daily;

  /// Offline sample built around right now. Used when sensors are off.
  factory WeatherInfo.sample() {
    final now = DateTime.now();
    final hourly = <HourlyPoint>[];
    for (var i = 0; i < 8; i++) {
      final t = now.add(Duration(hours: i));
      hourly.add(HourlyPoint(
        timeIso: _isoHour(t),
        temperatureC: 19 + (i == 3 ? 2 : 0) - (i > 5 ? 1 : 0),
        code: 1,
      ));
    }
    final daily = <DailyPoint>[];
    for (var i = 0; i < 4; i++) {
      final d = now.add(Duration(days: i));
      daily.add(DailyPoint(
        dateIso: _isoHour(d).substring(0, 10),
        maxC: (21 - i).toDouble(),
        minC: (14 - i).toDouble(),
        code: i == 2 ? 3 : 1,
      ));
    }
    return WeatherInfo(
      temperatureC: 19,
      code: 1,
      highC: 21,
      lowC: 14,
      hourly: hourly,
      daily: daily,
    );
  }

  static String _isoHour(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}T${two(t.hour)}:00';
  }
}

class HourlyPoint {
  const HourlyPoint({
    required this.timeIso,
    required this.temperatureC,
    required this.code,
  });

  final String timeIso; // Local ISO hour, e.g. 2026-10-27T14:00
  final double temperatureC;
  final int code;
}

class DailyPoint {
  const DailyPoint({
    required this.dateIso,
    required this.maxC,
    required this.minC,
    required this.code,
  });

  final String dateIso; // Local ISO date, e.g. 2026-10-28
  final double maxC;
  final double minC;
  final int code;
}

/// Plain-English label for an Open-Meteo WMO code.
String weatherLabel(int code) {
  if (code == 0) return 'Clear sky';
  if (code == 1) return 'Mainly clear';
  if (code == 2) return 'Partly cloudy';
  if (code == 3) return 'Overcast';
  if (code == 45 || code == 48) return 'Fog';
  if (code == 51 || code == 53 || code == 55) return 'Drizzle';
  if (code == 56 || code == 57) return 'Freezing drizzle';
  if (code == 61 || code == 63 || code == 65) return 'Rain';
  if (code == 66 || code == 67) return 'Freezing rain';
  if (code == 71 || code == 73 || code == 75) return 'Snow';
  if (code == 77) return 'Snow grains';
  if (code == 80 || code == 81 || code == 82) return 'Showers';
  if (code == 95) return 'Thunderstorm';
  if (code == 96 || code == 99) return 'Storm with hail';
  return 'Unknown';
}

/// Turns 2026-10-27T14:00 into 2 PM. Falls back to '' on bad input.
String hourLabel(String timeIso) {
  if (timeIso.length < 13) return '';
  final hour = int.tryParse(timeIso.substring(11, 13));
  if (hour == null) return '';
  if (hour == 0) return '12 AM';
  if (hour == 12) return '12 PM';
  if (hour < 12) return '$hour AM';
  return '${hour - 12} PM';
}

/// Turns 2026-10-28 into Tue. Falls back to '' on bad input.
String weekdayLabel(String dateIso) {
  try {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.parse(dateIso).weekday - 1];
  } catch (_) {
    return '';
  }
}
