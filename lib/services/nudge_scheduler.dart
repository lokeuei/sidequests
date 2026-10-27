import 'dart:io';

import 'package:workmanager/workmanager.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/nudge_policy.dart';
import 'package:sidequests/services/preferences_service.dart';

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
    if (inQuietHours(DateTime.now())) return 'Quiet hours, skipped.';
    final sunset = await prefs.loadLastSunset();
    if (sunset.isEmpty) return 'No sunset saved yet.';
    if (!goldenHourSoon(minutesOfDay(sunset), DateTime.now())) {
      return 'Not golden hour yet.';
    }
    final notifications = NotificationService.device();
    await notifications.init();
    await notifications.nudgeSimple(
      'Golden hour is close',
      'Step out for the light. Your quests are ready.',
    );
    return 'Sent a golden-hour nudge.';
  } catch (_) {
    return 'Check ran into trouble.';
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
