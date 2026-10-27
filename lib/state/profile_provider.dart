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

  /// Remembers sunset for the background check. Skips revision on purpose.
  Future<void> noteSunset(String iso) => _prefs.saveLastSunset(iso);

  Future<void> toggleSave(Quest quest) {
    return update((p) {
      if (p.isSaved(quest.id)) {
        p.savedQuests.removeWhere((q) => q.id == quest.id);
        p.noteEngagement(quest.tags, -1);
      } else {
        p.savedQuests.add(quest);
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
