import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';

/// Quiet hours: 10 PM to 8 AM local. No automatic nudges inside the window.
bool inQuietHours(DateTime now) => now.hour >= 22 || now.hour < 8;

/// True when sunset is right now or within the next 70 minutes.
bool goldenHourSoon(int sunsetMinutes, DateTime now) {
  if (sunsetMinutes < 0) return false;
  final diff = sunsetMinutes - (now.hour * 60 + now.minute);
  return diff >= 0 && diff <= 70;
}

/// Friday from 8 AM, or Saturday before noon. The weekend-planning window.
bool isWeekendPlanningTime(DateTime now) {
  if (now.weekday == DateTime.friday) return now.hour >= 8;
  if (now.weekday == DateTime.saturday) return now.hour < 12;
  return false;
}

/// One stamp per weekend: the Saturday date. Friday and Saturday of the
/// same weekend share it, so the nudge fires once.
String weekendStamp(DateTime now) {
  final saturday = now.add(Duration(days: DateTime.saturday - now.weekday));
  return '${saturday.year}-${saturday.month}-${saturday.day}';
}

/// First gig within 7 days matching something the user loves
/// (an explicit interest or a learned weight above zero).
Quest? pickGig(List<Quest> gigs, UserProfile profile, DateTime now) {
  final loved = {
    ...profile.interests,
    for (final entry in profile.learnedWeights.entries)
      if (entry.value > 0) entry.key,
  };
  for (final gig in gigs) {
    final startsAt = DateTime.tryParse(gig.startsAt);
    if (startsAt == null) continue;
    final daysOut = startsAt.difference(now).inDays;
    if (daysOut < 0 || daysOut > 7) continue;
    if (gig.tags.any(loved.contains)) return gig;
  }
  return null;
}
