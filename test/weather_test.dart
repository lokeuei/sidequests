import 'package:flutter_test/flutter_test.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/map_pins.dart';

void main() {
  test('weather labels stay plain', () {
    expect(weatherLabel(0), 'Clear sky');
    expect(weatherLabel(2), 'Partly cloudy');
    expect(weatherLabel(61), 'Rain');
    expect(weatherLabel(95), 'Thunderstorm');
    expect(weatherLabel(-1), 'Unknown');
  });

  test('hour labels use 12 hour clock', () {
    expect(hourLabel('2026-10-27T00:00'), '12 AM');
    expect(hourLabel('2026-10-27T09:00'), '9 AM');
    expect(hourLabel('2026-10-27T12:00'), '12 PM');
    expect(hourLabel('2026-10-27T13:00'), '1 PM');
    expect(hourLabel('nope'), '');
  });

  test('weekday labels use short names', () {
    expect(weekdayLabel('2026-10-27'), 'Tue');
    expect(weekdayLabel('nope'), '');
  });

  test('preview pins are stable per quest', () {
    final first = previewPin(59.9, 10.7, 'q-sunset-bluff', 0);
    final again = previewPin(59.9, 10.7, 'q-sunset-bluff', 0);
    final other = previewPin(59.9, 10.7, 'q-small-museum', 5);
    expect(again.latitude, first.latitude);
    expect(again.longitude, first.longitude);
    expect(other.latitude == first.latitude && other.longitude == first.longitude, isFalse);
    // Pins stay close to the user (within ~2 km).
    expect((first.latitude - 59.9).abs(), lessThan(0.03));
    expect((first.longitude - 10.7).abs(), lessThan(0.03));
  });
}
