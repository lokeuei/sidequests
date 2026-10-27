import 'package:flutter_test/flutter_test.dart';
import 'package:sidequests/services/nudge_policy.dart';

void main() {
  test('quiet hours cover night only', () {
    expect(inQuietHours(DateTime(2026, 10, 27, 23)), isTrue);
    expect(inQuietHours(DateTime(2026, 10, 27, 7, 59)), isTrue);
    expect(inQuietHours(DateTime(2026, 10, 27, 8)), isFalse);
    expect(inQuietHours(DateTime(2026, 10, 27, 12)), isFalse);
    expect(inQuietHours(DateTime(2026, 10, 27, 22)), isTrue);
  });

  test('golden hour warning fires inside 70 minutes', () {
    const sunset = 19 * 60 + 45;
    expect(goldenHourSoon(sunset, DateTime(2026, 10, 27, 17, 30)), isFalse);
    expect(goldenHourSoon(sunset, DateTime(2026, 10, 27, 18, 40)), isTrue);
    expect(goldenHourSoon(sunset, DateTime(2026, 10, 27, 19, 50)), isFalse);
    expect(goldenHourSoon(-1, DateTime(2026, 10, 27, 18, 40)), isFalse);
  });
}
