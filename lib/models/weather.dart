/// Weather data from Open-Meteo (keyless). Pure Dart, no Flutter imports.
class WeatherInfo {
  const WeatherInfo({
    required this.temperatureC,
    required this.code,
    required this.highC,
    required this.lowC,
    required this.hourly,
    required this.daily,
    this.sunrise = '',
    this.sunset = '',
  });

  final double temperatureC;
  final int code;
  final double highC;
  final double lowC;
  final List<HourlyPoint> hourly;
  final List<DailyPoint> daily;

  /// Local ISO datetimes, e.g. 2026-10-27T06:30. Empty when unknown.
  final String sunrise;
  final String sunset;

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

/// Turns 2026-10-27T06:42 into 6:42 AM. Falls back to '' on bad input.
String timeLabel(String timeIso) {
  if (timeIso.length < 16) return '';
  final hour = int.tryParse(timeIso.substring(11, 13));
  final minute = timeIso.substring(14, 16);
  if (hour == null || int.tryParse(minute) == null) return '';
  if (hour == 0) return '12:$minute AM';
  if (hour == 12) return '12:$minute PM';
  if (hour < 12) return '$hour:$minute AM';
  return '${hour - 12}:$minute PM';
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

/// Minutes since midnight for 2026-10-27T19:45. Returns -1 when unknown.
int minutesOfDay(String timeIso) {
  if (timeIso.length < 16) return -1;
  final hour = int.tryParse(timeIso.substring(11, 13));
  final minute = int.tryParse(timeIso.substring(14, 16));
  if (hour == null || minute == null) return -1;
  return hour * 60 + minute;
}

/// Renders Celsius [c] in the user's unit ('c' or 'f').
String tempLabel(double c, String unit) {
  if (unit == 'f') return '${(c * 9 / 5 + 32).round()}°';
  return '${c.round()}°';
}
