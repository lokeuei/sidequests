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

  String get distanceLabel =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '$meters m';

  String get durationLabel {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
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
