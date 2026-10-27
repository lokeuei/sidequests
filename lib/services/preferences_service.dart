import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidequests/models/user_profile.dart';

/// Persists the profile. [PreferencesService.memory] is the in-memory
/// variant for tests — no platform channels involved.
class PreferencesService {
  PreferencesService.device() : _memory = null;
  PreferencesService.memory() : _memory = <String, Object?>{};

  final Map<String, Object?>? _memory;

  static const _key = 'sidequests.profile.v1';
  static const _sunsetKey = 'sidequests.sunset.v1';

  Future<UserProfile> load() async {
    try {
      final raw = _memory != null
          ? _memory[_key] as String?
          : (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null || raw.isEmpty) return UserProfile();
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return UserProfile();
    }
  }

  Future<void> save(UserProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    if (_memory != null) {
      _memory[_key] = raw;
      return;
    }
    try {
      await (await SharedPreferences.getInstance()).setString(_key, raw);
    } catch (_) {
      // Prefs are a bonus; the session keeps working without them.
    }
  }

  /// Last seen sunset ISO, so the background check can spot golden hour.
  Future<String> loadLastSunset() async {
    try {
      if (_memory != null) return _memory[_sunsetKey] as String? ?? '';
      return (await SharedPreferences.getInstance()).getString(_sunsetKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> saveLastSunset(String iso) async {
    if (_memory != null) {
      _memory[_sunsetKey] = iso;
      return;
    }
    try {
      await (await SharedPreferences.getInstance()).setString(_sunsetKey, iso);
    } catch (_) {}
  }
}
