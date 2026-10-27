import 'package:flutter_test/flutter_test.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/services/nudge_policy.dart';

Quest _gig(
  String id,
  String title,
  DateTime start, [
  List<String> tags = const ['events', 'live music', 'social'],
]) {
  return Quest(
    id: id,
    title: title,
    blurb: 'Tickets still listed.',
    category: QuestCategory.social,
    minutes: 120,
    meters: 500,
    tags: tags,
    why: 'On Friday.',
    bestWindow: 'Friday',
    startsAt: start.toIso8601String(),
  );
}

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

  test('weekend planning runs Friday day and Saturday morning', () {
    expect(isWeekendPlanningTime(DateTime(2026, 10, 30, 9)), isTrue);
    expect(isWeekendPlanningTime(DateTime(2026, 10, 30, 7)), isFalse);
    expect(isWeekendPlanningTime(DateTime(2026, 10, 31, 9)), isTrue);
    expect(isWeekendPlanningTime(DateTime(2026, 10, 31, 13)), isFalse);
    expect(isWeekendPlanningTime(DateTime(2026, 10, 28, 9)), isFalse);
  });

  test('weekend stamp is shared across the weekend', () {
    expect(
      weekendStamp(DateTime(2026, 10, 30, 20)),
      weekendStamp(DateTime(2026, 10, 31, 9)),
    );
    expect(weekendStamp(DateTime(2026, 10, 31, 9)), '2026-10-31');
  });

  test('gig picker takes the soonest loved gig in range', () {
    final gigs = [
      _gig('tm-far', 'Far Fest', DateTime(2026, 11, 20)),
      _gig('tm-near', 'Riverside Gig', DateTime(2026, 10, 29)),
      _gig('tm-meh', 'Chess Club Night', DateTime(2026, 10, 28), ['social']),
    ];
    final profile = UserProfile(interests: {'live music'});
    final pick = pickGig(gigs, profile, DateTime(2026, 10, 27, 12));
    expect(pick?.id, 'tm-near');
  });

  test('gig picker skips unloved and dateless gigs', () {
    final now = DateTime(2026, 10, 27, 12);
    final profile = UserProfile(interests: {'live music'});
    final meh = _gig(
      'tm-meh',
      'Chess Club Night',
      DateTime(2026, 10, 28),
      ['social'],
    );
    expect(pickGig([meh], profile, now), isNull);
    const dateless = Quest(
      id: 'tm-x',
      title: 'Mystery Show',
      blurb: 'Tickets still listed.',
      category: QuestCategory.social,
      minutes: 120,
      meters: 500,
      tags: ['events', 'live music'],
      why: 'Soon.',
      bestWindow: 'Soon',
      startsAt: '',
    );
    expect(pickGig([dateless], profile, now), isNull);
  });
}
