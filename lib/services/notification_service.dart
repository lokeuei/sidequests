import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sidequests/models/quest.dart';

/// The "little nudge to look up": a local notification for the top quest.
/// [NotificationService.memory] is a no-op for tests.
class NotificationService {
  NotificationService.device() : _memory = false;
  NotificationService.memory() : _memory = true;

  final bool _memory;
  FlutterLocalNotificationsPlugin? _plugin;
  bool _ready = false;

  Future<void> init() async {
    if (_memory) return;
    try {
      _plugin = FlutterLocalNotificationsPlugin();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin!.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      await _plugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Nudge about [quest]. Bold nudges use max importance; gentle ones high.
  /// Audio cues ride on the notification sound until TTS lands.
  Future<void> nudge(Quest quest, {required bool bold}) async {
    if (_memory || !_ready || _plugin == null) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        'sidequests_nudges',
        'Adventure nudges',
        channelDescription: 'Little reasons to look up.',
        importance: bold ? Importance.max : Importance.high,
        priority: bold ? Priority.max : Priority.high,
      );
      await _plugin!.show(
        quest.id.hashCode,
        bold ? 'Go now: ${quest.title}' : quest.title,
        quest.why,
        NotificationDetails(android: androidDetails),
        payload: quest.id,
      );
    } catch (_) {
      // A missed nudge must never crash the app.
    }
  }
}
