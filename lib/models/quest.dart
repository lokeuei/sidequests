/// A single suggested adventure.
class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.blurb,
    required this.category,
    required this.minutes,
    required this.meters,
    required this.tags,
    required this.why,
    required this.bestWindow,
    this.latitude,
    this.longitude,
    this.startsAt = '',
  });

  final String id;
  final String title;
  final String blurb;
  final QuestCategory category;

  /// Typical door-to-door time in minutes.
  final int minutes;

  /// Straight-line distance in meters from the current context.
  final int meters;

  /// Interest vocabulary, e.g. 'sunsets', 'quiet' (see kAllInterests).
  final List<String> tags;

  /// Evergreen flavor: why this place is worth it.
  final String why;

  /// Human best-time hint, e.g. '5–7 PM'.
  final String bestWindow;

  final double? latitude;
  final double? longitude;

  /// ISO start for dated events, e.g. 2026-11-01T20:00:00Z. Empty if n/a.
  final String startsAt;

  String get distanceLabel =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '$meters m';

  String get durationLabel {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'blurb': blurb,
        'category': category.name,
        'minutes': minutes,
        'meters': meters,
        'tags': tags,
        'why': why,
        'bestWindow': bestWindow,
        'latitude': latitude,
        'longitude': longitude,
        'startsAt': startsAt,
      };

  factory Quest.fromJson(Map<String, Object?> json) {
    final tags = (json['tags'] as List?) ?? [];
    return Quest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      blurb: json['blurb'] as String? ?? '',
      category: QuestCategory.values.firstWhere(
        (v) => v.name == (json['category'] as String? ?? 'outdoors'),
        orElse: () => QuestCategory.outdoors,
      ),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      meters: (json['meters'] as num?)?.toInt() ?? 0,
      tags: tags.map((e) => e.toString()).toList(),
      why: json['why'] as String? ?? '',
      bestWindow: json['bestWindow'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startsAt: json['startsAt'] as String? ?? '',
    );
  }
}

enum QuestCategory { outdoors, culture, food, water, night, social, quiet }

extension QuestCategoryLabel on QuestCategory {
  String get label => switch (this) {
        QuestCategory.outdoors => 'Outdoors',
        QuestCategory.culture => 'Culture',
        QuestCategory.food => 'Taste',
        QuestCategory.water => 'Water',
        QuestCategory.night => 'After dark',
        QuestCategory.social => 'Together',
        QuestCategory.quiet => 'Slow down',
      };
}
