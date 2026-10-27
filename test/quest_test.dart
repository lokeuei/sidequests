import 'package:flutter_test/flutter_test.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/services/preferences_service.dart';
import 'package:sidequests/state/profile_provider.dart';

import 'fixtures/sample_quests.dart';

void main() {
  test('quest survives a JSON round trip', () {
    final quest = questCatalog.first;
    final back = Quest.fromJson(quest.toJson());
    expect(back.id, quest.id);
    expect(back.title, quest.title);
    expect(back.category, quest.category);
    expect(back.tags, quest.tags);
    expect(back.latitude, quest.latitude);
  });

  test('saved quests persist full quests, not just ids', () async {
    final prefs = PreferencesService.memory();
    final profiles = ProfileProvider(prefs: prefs);
    await profiles.load();
    final quest = questCatalog.first;

    expect(profiles.profile.isSaved(quest.id), isFalse);
    await profiles.toggleSave(quest);
    expect(profiles.profile.isSaved(quest.id), isTrue);
    expect(profiles.profile.savedQuests.first.title, quest.title);

    // Reload from the same storage and confirm the quest is still whole.
    final reloaded = ProfileProvider(prefs: prefs);
    await reloaded.load();
    expect(reloaded.profile.isSaved(quest.id), isTrue);
    expect(reloaded.profile.savedQuests.first.title, quest.title);

    await profiles.toggleSave(quest);
    expect(profiles.profile.isSaved(quest.id), isFalse);
  });
}
