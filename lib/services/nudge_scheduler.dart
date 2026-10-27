import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/events_service.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/nudge_policy.dart';
import 'package:sidequests/services/places_service.dart';
import 'package:sidequests/services/preferences_service.dart';
import 'package:sidequests/services/suggestion_engine.dart';

const _taskName = 'sidequests-nudge-check';

@pragma('vm:entry-point')
void nudgeCallbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    await runNudgeCheck();
    return true;
  });
}

/// One background pass. Shared by the OS task and the manual test button,
/// so both run the exact same logic. Returns what happened, in plain words.
Future<String> runNudgeCheck() async {
  try {
    final prefs = PreferencesService.device();
    final profile = await prefs.load();
    if (!profile.skillEnabled) return 'Skill is off, skipped.';
    final now = DateTime.now();
    if (inQuietHours(now)) return 'Quiet hours, skipped.';
    final notifications = NotificationService.device();
    await notifications.init();

    final sunset = await prefs.loadLastSunset();
    if (sunset.isNotEmpty && goldenHourSoon(minutesOfDay(sunset), now)) {
      await notifications.nudgeSimple(
        'Golden hour is close',
        'Step out for the light. Your quests are ready.',
      );
      return 'Sent a golden-hour nudge.';
    }

    final gig = await _gigAlert(prefs, profile, now);
    if (gig != null) {
      await prefs.saveLastGigNudge(gig.id);
      await notifications.nudgeSimple(
        'A gig for you',
        '${gig.title}. ${gig.why}',
      );
      return 'Sent a gig nudge.';
    }

    final idea = await _weekendIdea(prefs, profile, now);
    if (idea != null) {
      await prefs.saveLastWeekendNudge(weekendStamp(now));
      await notifications.nudgeSimple(
        'Weekend idea',
        '${idea.quest.title}. ${idea.reason}',
      );
      return 'Sent a weekend nudge.';
    }
    return 'Nothing worth a nudge right now.';
  } catch (_) {
    return 'Check ran into trouble.';
  }
}

/// A loved-genre gig within 7 days that hasn't pinged yet. Uses the last
/// known position, which needs no background location permission.
Future<Quest?> _gigAlert(
  PreferencesService prefs,
  UserProfile profile,
  DateTime now,
) async {
  try {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;
    final gigs = await EventsService().upcoming(
      position.latitude,
      position.longitude,
      apiKey: profile.ticketmasterKey,
    );
    final pick = pickGig(gigs, profile, now);
    if (pick == null) return null;
    if (await prefs.loadLastGigNudge() == pick.id) return null;
    return pick;
  } catch (_) {
    return null;
  }
}

/// Top local pick on a fresh weekend, ranked without weather.
Future<ScoredQuest?> _weekendIdea(
  PreferencesService prefs,
  UserProfile profile,
  DateTime now,
) async {
  try {
    if (!isWeekendPlanningTime(now)) return null;
    if (await prefs.loadLastWeekendNudge() == weekendStamp(now)) return null;
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;
    final found =
        await PlacesService().nearby(position.latitude, position.longitude);
    if (found.quests.isEmpty) return null;
    final context = QuestContext(
      hour: now.hour,
      minute: now.minute,
      weekday: now.weekday,
      temperatureC: 19,
      weatherCode: -1,
      traveling: profile.travelMode,
    );
    final ranked = rankQuests(
      candidates: found.quests,
      profile: profile,
      context: context,
    );
    return ranked.isEmpty ? null : ranked.first;
  } catch (_) {
    return null;
  }
}

/// Schedules the periodic background check. Android only for now.
class NudgeScheduler {
  static bool _ready = false;

  /// Call on boot and whenever the skill toggle flips.
  static Future<void> apply(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      if (!_ready) {
        await Workmanager().initialize(nudgeCallbackDispatcher);
        _ready = true;
      }
      if (enabled) {
        await Workmanager().registerPeriodicTask(
          _taskName,
          _taskName,
          frequency: const Duration(minutes: 30),
        );
      } else {
        await Workmanager().cancelByUniqueName(_taskName);
      }
    } catch (_) {}
  }
}
