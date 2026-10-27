import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sidequests/models/quest.dart';

/// The "little nudge to look up": a local notification for the top quest,
/// plus optional spoken cues through the system voice.
/// [NotificationService.memory] is a no-op for tests.
class NotificationService {
  NotificationService.device() : _memory = false;
  NotificationService.memory() : _memory = true;

  final bool _memory;
  FlutterLocalNotificationsPlugin? _plugin;
  FlutterTts? _tts;
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
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.8);
    } catch (_) {
      _tts = null;
    }
  }

  /// Nudge about [quest]. Bold nudges use max importance; gentle ones high.
  /// When [speak] is true the system voice also reads the nudge out loud.
  Future<void> nudge(Quest quest, {required bool bold, bool speak = false}) async {
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
      if (speak) await this.speak('${quest.title}. ${quest.why}');
    } catch (_) {
      // A missed nudge must never crash the app.
    }
  }

  /// Plain nudge without a quest, used by the background check.
  Future<void> nudgeSimple(String title, String body) async {
    if (_memory || !_ready || _plugin == null) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'sidequests_nudges',
        'Adventure nudges',
        channelDescription: 'Little reasons to look up.',
        importance: Importance.high,
        priority: Priority.high,
      );
      await _plugin!.show(
        title.hashCode,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {
      // A missed nudge must never crash the app.
    }
  }

  /// Reads [text] out loud. Silent no-op when voice is unavailable.
  Future<void> speak(String text) async {
    if (_memory || _tts == null) return;
    try {
      await _tts!.speak(text);
    } catch (_) {}
  }

  /// Stops any in-progress speech.
  Future<void> stop() async {
    if (_memory || _tts == null) return;
    try {
      await _tts!.stop();
    } catch (_) {}
  }
}
