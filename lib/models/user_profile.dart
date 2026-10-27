import 'package:sidequests/models/quest.dart';

/// What Mint knows about the user: explicit settings plus learned weights.
///
/// Learning happens by default from taps/saves/dismissals; the explicit
/// interests below only sharpen it.
class UserProfile {
  UserProfile({
    this.displayName = '',
    Set<String>? interests,
    Set<String>? avoid,
    List<Quest>? savedQuests,
    this.tempUnit = 'c',
    this.nudgeStyle = NudgeStyle.gentle,
    this.audioCues = false,
    this.voiceRate = 0.5,
    this.travelMode = false,
    this.skillEnabled = true,
    this.suggestWhenTraveling = true,
    this.museApiKey = '',
    this.ticketmasterKey = '',
    Map<String, int>? learnedWeights,
  })  : interests = interests ?? <String>{},
        avoid = avoid ?? <String>{},
        savedQuests = savedQuests ?? <Quest>[],
        learnedWeights = learnedWeights ?? <String, int>{};

  String displayName;
  Set<String> interests;
  Set<String> avoid;

  /// Full saved quests (live data has no stable catalog to look up).
  List<Quest> savedQuests;

  /// 'c' or 'f'.
  String tempUnit;
  NudgeStyle nudgeStyle;
  bool audioCues;

  /// Spoken voice speed, 0.3 to 1.0. 0.5 reads calm and clear.
  double voiceRate;
  bool travelMode;
  bool skillEnabled;
  bool suggestWhenTraveling;

  /// API keys, stored only on this phone. A --dart-define key wins when set.
  String museApiKey;
  String ticketmasterKey;

  /// Tag -> weight. Positive means "more like this". Mirrors the skill
  /// contract deltas: view +1, save +2, go +3, unsave -1, dismiss -2,
  /// went +3, loved +5, not for me -4.
  Map<String, int> learnedWeights;

  bool isSaved(String id) => savedQuests.any((q) => q.id == id);

  void noteEngagement(Iterable<String> tags, int delta) {
    for (final tag in tags) {
      learnedWeights[tag] = (learnedWeights[tag] ?? 0) + delta;
    }
  }

  /// After-quest feedback, stronger than taps.
  void noteWent(Quest quest) => noteEngagement(quest.tags, 3);
  void noteLoved(Quest quest) => noteEngagement(quest.tags, 5);
  void noteNotForMe(Quest quest) => noteEngagement(quest.tags, -4);

  /// Tags Mint noticed you love (weight > 0), best first.
  List<String> topLearned([int limit = 5]) {
    final entries =
        learnedWeights.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  /// Tags Mint noticed you skip (weight < 0), worst first.
  List<String> topSkipped([int limit = 3]) {
    final entries =
        learnedWeights.entries.where((e) => e.value < 0).toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  int weightFor(String tag) => learnedWeights[tag] ?? 0;

  /// Fingerprint of the settings that change results. Display-only picks
  /// (name, units, voice, saves) stay out, so tweaking them never
  /// triggers a fresh location and Mint lookup. Learned weights stay out
  /// too; they apply on the next natural refresh.
  String get resultsKey {
    final likes = [...interests]..sort();
    final skips = [...avoid]..sort();
    return [
      likes.join(','),
      skips.join(','),
      travelMode,
      skillEnabled,
      suggestWhenTraveling,
      museApiKey.trim(),
      ticketmasterKey.trim(),
    ].join('|');
  }

  Map<String, Object?> toJson() => {
        'displayName': displayName,
        'interests': interests.toList(),
        'avoid': avoid.toList(),
        'savedQuests': savedQuests.map((q) => q.toJson()).toList(),
        'tempUnit': tempUnit,
        'nudgeStyle': nudgeStyle.name,
        'audioCues': audioCues,
        'voiceRate': voiceRate,
        'travelMode': travelMode,
        'skillEnabled': skillEnabled,
        'suggestWhenTraveling': suggestWhenTraveling,
        'museApiKey': museApiKey,
        'ticketmasterKey': ticketmasterKey,
        'learnedWeights': learnedWeights,
      };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    Set<String> stringSet(Object? value) {
      final list = value as List?;
      if (list == null) return <String>{};
      return list.map((e) => e.toString()).toSet();
    }

    List<Quest> questList(Object? value) {
      final list = value as List?;
      if (list == null) return <Quest>[];
      final quests = <Quest>[];
      for (final entry in list) {
        try {
          quests.add(Quest.fromJson((entry as Map).cast<String, Object?>()));
        } catch (_) {
          continue;
        }
      }
      return quests;
    }

    Map<String, int> weights(Object? value) {
      final map = value as Map?;
      if (map == null) return <String, int>{};
      return map.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
    }

    final unit = json['tempUnit'] as String? ?? 'c';
    return UserProfile(
      displayName: json['displayName'] as String? ?? '',
      interests: stringSet(json['interests']),
      avoid: stringSet(json['avoid']),
      savedQuests: questList(json['savedQuests']),
      tempUnit: unit == 'f' ? 'f' : 'c',
      nudgeStyle: NudgeStyle.values.firstWhere(
        (v) => v.name == (json['nudgeStyle'] as String? ?? 'gentle'),
        orElse: () => NudgeStyle.gentle,
      ),
      audioCues: json['audioCues'] as bool? ?? false,
      voiceRate: (json['voiceRate'] as num?)?.toDouble() ?? 0.5,
      travelMode: json['travelMode'] as bool? ?? false,
      skillEnabled: json['skillEnabled'] as bool? ?? true,
      suggestWhenTraveling: json['suggestWhenTraveling'] as bool? ?? true,
      museApiKey: json['museApiKey'] as String? ?? '',
      ticketmasterKey: json['ticketmasterKey'] as String? ?? '',
      learnedWeights: weights(json['learnedWeights']),
    );
  }
}

enum NudgeStyle { gentle, bold }
