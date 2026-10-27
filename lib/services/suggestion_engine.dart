import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';

/// Interest vocabulary shared by the onboarding chips and the stub catalog.
/// Every entry matches at least one quest in the catalog.
const kAllInterests = <String>[
  'sunsets',
  'viewpoints',
  'history',
  'architecture',
  'street art',
  'water',
  'cafes',
  'food markets',
  'live music',
  'stargazing',
  'night walks',
  'local gems',
  'quiet',
  'mornings',
  'museums',
  'social',
  'events',
];

/// Automatic context the ranker (and later, the Muse skill) reasons over.
/// Pure Dart with no Flutter imports, so this file is unit-testable.
class QuestContext {
  const QuestContext({
    required this.hour,
    required this.weekday,
    required this.temperatureC,
    required this.weatherCode,
    required this.traveling,
    this.minute = 0,
    this.sunsetMinutes = -1,
    this.latitude,
    this.longitude,
  });

  final int hour;
  final int minute;
  final int weekday; // 1 = Monday .. 7 = Sunday
  final double temperatureC;
  final int weatherCode; // Open-Meteo WMO code; -1 = unknown
  final bool traveling;

  /// Minutes since midnight of true sunset, local time. -1 = unknown.
  final int sunsetMinutes;
  final double? latitude;
  final double? longitude;

  /// The 90 minutes before true sunset, or 5-7 PM when sunset is unknown.
  bool get isGoldenHour {
    if (sunsetMinutes < 0) return hour >= 17 && hour <= 19;
    final now = hour * 60 + minute;
    return now <= sunsetMinutes && sunsetMinutes - now <= 90;
  }

  bool get isMorning => hour >= 6 && hour < 11;
  bool get isNight => hour >= 21 || hour < 5;
  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;
  bool get isClear => weatherCode == 0 || weatherCode == 1;
  bool get isRainy => weatherCode >= 51 && weatherCode <= 82;
}

String daylightLabel(int hour) {
  if (hour >= 5 && hour < 8) return 'Sunrise';
  if (hour >= 8 && hour < 12) return 'Morning light';
  if (hour >= 12 && hour < 17) return 'Afternoon';
  if (hour >= 17 && hour < 20) return 'Golden hour';
  if (hour >= 20 && hour < 22) return 'Blue hour';
  return 'Night';
}

class ScoredQuest {
  const ScoredQuest({
    required this.quest,
    required this.score,
    required this.reason,
  });

  final Quest quest;
  final double score;
  final String reason;
}

class _Note {
  const _Note(this.points, this.label);
  final double points;
  final String label;
}

/// Stub "Muse" reasoning: scores candidates from profile + automatic context.
///
/// The live Muse skill replaces this function behind the same signature.
/// See `muse-skill/SKILL.md`. Contributors double as the user-facing
/// "why this now" reason.
List<ScoredQuest> rankQuests({
  required List<Quest> candidates,
  required UserProfile profile,
  required QuestContext context,
  int limit = 5,
}) {
  final scored = <ScoredQuest>[];
  for (final quest in candidates) {
    var score = 50.0;
    final notes = <_Note>[];

    void add(double points, String note) {
      score += points;
      if (points != 0) notes.add(_Note(points, note));
    }

    final tags = quest.tags.toSet();

    final loved = tags.intersection(profile.interests).length;
    if (loved > 0) {
      add(12.0 * loved, 'matches ${loved == 1 ? 'an interest' : '$loved interests'}');
    }
    final hated = tags.intersection(profile.avoid).length;
    if (hated > 0) add(-25.0 * hated, 'you asked for less of this');

    var learned = 0;
    for (final tag in tags) {
      learned += profile.weightFor(tag);
    }
    if (learned != 0) {
      add(
        (learned * 3).clamp(-15, 21).toDouble(),
        learned > 0 ? 'you usually love this' : 'not usually your thing',
      );
    }

    if (context.isGoldenHour &&
        tags.intersection({'sunsets', 'viewpoints', 'water', 'evenings'}).isNotEmpty) {
      add(18, 'golden hour light');
    }
    if (context.isMorning &&
        tags.intersection({'mornings', 'cafes', 'quiet', 'bakery'}).isNotEmpty) {
      add(10, 'made for the morning');
    }
    if (context.isNight &&
        tags.intersection({'night', 'stargazing', 'live music', 'night walks'}).isNotEmpty) {
      add(14, 'made for tonight');
    }
    if (context.isNight && tags.contains('outdoors') && !tags.contains('night')) {
      add(-6, 'better before dark');
    }
    if (context.isRainy &&
        tags.intersection({'museums', 'cafes', 'food markets', 'bookshops'}).isNotEmpty) {
      add(16, 'cozy while it rains');
    }
    if (context.isRainy && tags.contains('outdoors')) {
      add(-15, 'rainy for this one');
    }
    if (context.isClear && tags.contains('outdoors')) {
      add(10, 'clear skies');
    }
    if (context.isClear && tags.contains('stargazing')) {
      add(8, 'clear night sky');
    }
    if (!context.isNight && tags.contains('stargazing')) {
      add(-12, 'wait for dark');
    }
    if (context.isWeekend &&
        tags.intersection({'day trips', 'social', 'food markets', 'live music'}).isNotEmpty) {
      add(6, 'weekend-perfect');
    }
    if (context.traveling &&
        tags.intersection({'local gems', 'history', 'viewpoints'}).isNotEmpty) {
      add(16, 'worth it while you are here');
    }

    // Gentle distance penalty: -2 per km, capped at -10.
    score -= (quest.meters / 500).clamp(0, 10).toDouble();

    final positive = notes.where((n) => n.points > 0).toList()
      ..sort((a, b) => b.points.compareTo(a.points));
    final reason = positive.isEmpty
        ? quest.why
        : positive.take(2).map((n) => n.label).join(', ');
    scored.add(ScoredQuest(quest: quest, score: score, reason: reason));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(limit).toList();
}

/// Spoken brief of the top picks. Plain words, short enough to say aloud.
String buildBrief(List<ScoredQuest> top) {
  if (top.isEmpty) return 'Nothing to brief yet.';
  const ordinals = ['First', 'Second', 'Third'];
  final bits = <String>[];
  for (var i = 0; i < top.length && i < 3; i++) {
    bits.add('${ordinals[i]}, ${top[i].quest.title}. ${top[i].reason}');
  }
  return "Here's your brief. ${bits.join(' ')}";
}
