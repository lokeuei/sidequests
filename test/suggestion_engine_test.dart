import 'package:flutter_test/flutter_test.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/services/quest_catalog.dart';
import 'package:sidequests/services/suggestion_engine.dart';

void main() {
  test('golden hour boosts sunset viewpoints for sunset lovers', () {
    final profile = UserProfile(interests: {'sunsets', 'viewpoints'});
    const evening = QuestContext(
      hour: 18,
      weekday: DateTime.friday,
      temperatureC: 19,
      weatherCode: 1,
      traveling: false,
    );
    final ranked = rankQuests(
      candidates: questCatalog,
      profile: profile,
      context: evening,
    );
    expect(ranked, isNotEmpty);
    expect(ranked.first.quest.tags, contains('sunsets'));
    expect(ranked.first.reason, contains('golden hour'));
  });

  test('avoided tags are demoted below the top pick', () {
    final profile = UserProfile(avoid: {'live music'});
    const saturday = QuestContext(
      hour: 20,
      weekday: DateTime.saturday,
      temperatureC: 18,
      weatherCode: 0,
      traveling: false,
    );
    final ranked = rankQuests(
      candidates: questCatalog,
      profile: profile,
      context: saturday,
    );
    expect(ranked.first.quest.tags, isNot(contains('live music')));
    final music = ranked.where((q) => q.quest.tags.contains('live music'));
    if (music.isNotEmpty) {
      expect(ranked.indexOf(music.first), greaterThan(0));
    }
  });

  test('rain favors cozy indoor ideas', () {
    const rainy = QuestContext(
      hour: 15,
      weekday: DateTime.wednesday,
      temperatureC: 14,
      weatherCode: 61,
      traveling: false,
    );
    final ranked = rankQuests(
      candidates: questCatalog,
      profile: UserProfile(),
      context: rainy,
    );
    const indoor = {'museums', 'cafes', 'food markets'};
    expect(ranked.first.quest.tags.any(indoor.contains), isTrue);
  });

  test('traveling surfaces local gems', () {
    const away = QuestContext(
      hour: 10,
      weekday: DateTime.saturday,
      temperatureC: 22,
      weatherCode: 1,
      traveling: true,
    );
    final ranked = rankQuests(
      candidates: questCatalog,
      profile: UserProfile(),
      context: away,
    );
    expect(ranked.first.quest.tags, contains('local gems'));
  });

  test('learned weights lift familiar favorites', () {
    final fresh = rankQuests(
      candidates: questCatalog,
      profile: UserProfile(),
      context: const QuestContext(
        hour: 12,
        weekday: DateTime.monday,
        temperatureC: 20,
        weatherCode: 2,
        traveling: false,
      ),
    );
    final profile = UserProfile();
    profile.noteEngagement(['stargazing'], 5);
    final learned = rankQuests(
      candidates: questCatalog,
      profile: profile,
      context: const QuestContext(
        hour: 22,
        weekday: DateTime.monday,
        temperatureC: 16,
        weatherCode: 0,
        traveling: false,
      ),
    );
    // Sanity: ranking is stable input-dependent, and learning + night
    // puts the stargazing quest on top.
    expect(fresh, isNotEmpty);
    expect(learned.first.quest.tags, contains('stargazing'));
  });

  test('respects the limit', () {
    final ranked = rankQuests(
      candidates: questCatalog,
      profile: UserProfile(),
      context: const QuestContext(
        hour: 12,
        weekday: DateTime.monday,
        temperatureC: 20,
        weatherCode: 2,
        traveling: false,
      ),
      limit: 3,
    );
    expect(ranked.length, 3);
  });

  test('real sunset drives golden hour', () {
    const golden = QuestContext(
      hour: 18,
      minute: 30,
      weekday: DateTime.friday,
      temperatureC: 12,
      weatherCode: 1,
      traveling: false,
      sunsetMinutes: 19 * 60 + 45,
    );
    expect(golden.isGoldenHour, isTrue);

    const late = QuestContext(
      hour: 18,
      minute: 30,
      weekday: DateTime.friday,
      temperatureC: 12,
      weatherCode: 1,
      traveling: false,
      sunsetMinutes: 18 * 60,
    );
    expect(late.isGoldenHour, isFalse);
  });

  test('unknown sunset falls back to evening hours', () {
    const evening = QuestContext(
      hour: 18,
      weekday: DateTime.friday,
      temperatureC: 12,
      weatherCode: 1,
      traveling: false,
    );
    expect(evening.isGoldenHour, isTrue);
    const noon = QuestContext(
      hour: 12,
      weekday: DateTime.friday,
      temperatureC: 12,
      weatherCode: 1,
      traveling: false,
    );
    expect(noon.isGoldenHour, isFalse);
  });
}
