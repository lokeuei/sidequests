import 'package:flutter/foundation.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/services/preferences_service.dart';

/// Owns the profile. [revision] bumps on every change so screens can
/// re-rank only when something actually changed.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required PreferencesService prefs}) : _prefs = prefs;

  final PreferencesService _prefs;
  UserProfile profile = UserProfile();
  bool loaded = false;
  int revision = 0;

  Future<void> load() async {
    profile = await _prefs.load();
    loaded = true;
    notifyListeners();
  }

  Future<void> update(void Function(UserProfile profile) mutate) async {
    mutate(profile);
    revision++;
    notifyListeners();
    await _prefs.save(profile);
  }

  Future<void> toggleSave(Quest quest) {
    return update((p) {
      if (p.savedQuestIds.contains(quest.id)) {
        p.savedQuestIds.remove(quest.id);
        p.noteEngagement(quest.tags, -1);
      } else {
        p.savedQuestIds.add(quest.id);
        p.noteEngagement(quest.tags, 2);
      }
    });
  }

  Future<void> reset() async {
    profile = UserProfile();
    revision++;
    notifyListeners();
    await _prefs.save(profile);
  }
}
