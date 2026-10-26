import 'package:flutter/foundation.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/services/context_service.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/quest_catalog.dart';
import 'package:sidequests/services/suggestion_engine.dart';

/// Ranked quests for "right now", plus the reasoning line the UI shows.
class QuestProvider extends ChangeNotifier {
  QuestProvider({required this.contextService, required this.notifications});

  final ContextService contextService;
  final NotificationService notifications;

  List<ScoredQuest> quests = [];
  DeviceContext device = const DeviceContext();
  QuestContext? lastContext;
  String reasoning = '';
  bool loading = false;
  bool _autoNudged = false;
  final List<String> _dismissed = [];

  Future<void> refresh(UserProfile profile, {bool autoNudge = true}) async {
    loading = true;
    notifyListeners();
    try {
      device = await contextService.current();
      final now = DateTime.now();
      final context = QuestContext(
        hour: now.hour,
        weekday: now.weekday,
        temperatureC: device.temperatureC ?? 19,
        weatherCode: device.weatherCode,
        traveling: device.traveling || profile.travelMode,
      );
      lastContext = context;
      quests = rankQuests(
        candidates: questCatalog,
        profile: profile,
        context: context,
      ).where((q) => !_dismissed.contains(q.quest.id)).toList();
      reasoning = _describe(context, profile);
      if (autoNudge &&
          !_autoNudged &&
          context.traveling &&
          profile.skillEnabled &&
          profile.suggestWhenTraveling) {
        _autoNudged = true;
        await sendNudge(profile);
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> sendNudge(UserProfile profile) async {
    if (quests.isEmpty) return;
    await notifications.nudge(
      quests.first.quest,
      bold: profile.nudgeStyle == NudgeStyle.bold,
    );
  }

  void shuffle() {
    quests.shuffle();
    notifyListeners();
  }

  void dismiss(String id) {
    _dismissed.add(id);
    quests.removeWhere((q) => q.quest.id == id);
    notifyListeners();
  }

  void undoDismiss(ScoredQuest quest) {
    _dismissed.remove(quest.quest.id);
    quests.insert(0, quest);
    notifyListeners();
  }

  void clearDismissed() {
    _dismissed.clear();
    notifyListeners();
  }

  String _describe(QuestContext context, UserProfile profile) {
    final parts = <String>[];
    if (context.traveling) parts.add('away from home');
    if (context.isGoldenHour) {
      parts.add('golden-hour light');
    } else if (context.isMorning) {
      parts.add('fresh morning');
    } else if (context.isNight) {
      parts.add('night is falling');
    }
    if (context.isRainy) {
      parts.add('rain outside');
    } else if (context.isClear) {
      parts.add('clear skies');
    }
    if (profile.interests.isNotEmpty) {
      parts.add('you love ${profile.interests.take(2).join(' and ')}');
    }
    if (parts.isEmpty) return 'A few ideas worth looking up for.';
    final lead = parts.join(', ');
    return '${lead[0].toUpperCase()}${lead.substring(1)}. A few ideas worth looking up for.';
  }
}
