import 'package:flutter/foundation.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/context_service.dart';
import 'package:sidequests/services/events_service.dart';
import 'package:sidequests/services/muse_brain.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/nudge_policy.dart';
import 'package:sidequests/services/places_service.dart';
import 'package:sidequests/services/suggestion_engine.dart';

/// Ranked quests for "right now", plus the reasoning line the UI shows.
/// Live nearby places and events only. No samples, no stubs.
class QuestProvider extends ChangeNotifier {
  QuestProvider({
    required this.contextService,
    required this.notifications,
    PlacesService? places,
    EventsService? events,
  })  : places = places ?? PlacesService(),
        events = events ?? EventsService();

  final ContextService contextService;
  final NotificationService notifications;
  final PlacesService places;
  final EventsService events;

  List<ScoredQuest> quests = [];
  DeviceContext device = const DeviceContext();
  QuestContext? lastContext;
  String reasoning = '';
  bool loading = false;
  bool livePlaces = false;
  bool museUsed = false;

  /// True once a refresh finished (even an empty one). The UI only shows
  /// the blocking loader before the first finish; later reloads keep
  /// the old content up with a thin progress bar.
  bool hasLoaded = false;

  /// True when every places endpoint failed. False with no quests means
  /// the area is truly bare.
  bool placesFailed = false;

  /// Set when the user taps the map or searches a place. Refresh then
  /// looks around this point instead of the GPS location.
  double? searchLat;
  double? searchLon;
  String searchLabel = '';

  bool get searchingElsewhere => searchLat != null && searchLon != null;

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
        minute: now.minute,
        weekday: now.weekday,
        temperatureC: device.temperatureC ?? 19,
        weatherCode: device.weatherCode,
        traveling: device.traveling || profile.travelMode,
        sunsetMinutes: minutesOfDay(device.weather?.sunset ?? ''),
      );
      lastContext = context;
      var candidates = <Quest>[];
      livePlaces = false;
      placesFailed = false;
      final lat = searchLat ?? device.latitude;
      final lon = searchLon ?? device.longitude;
      if (lat != null && lon != null) {
        final (found, gigs) = await (
          places.nearby(lat, lon),
          events.upcoming(lat, lon, apiKey: profile.ticketmasterKey),
        ).wait;
        placesFailed = found.failed;
        final live = [...found.quests, ...gigs];
        if (live.isNotEmpty) {
          candidates = live;
          livePlaces = true;
        }
      }
      var ranked = rankQuests(
        candidates: candidates,
        profile: profile,
        context: context,
      ).where((q) => !_dismissed.contains(q.quest.id)).toList();
      var line = _describe(context, profile);
      museUsed = false;
      if (candidates.isNotEmpty) {
        final suggestion = await MuseBrain().suggest(
          profile: profile,
          now: now,
          traveling: context.traveling,
          weather: device.weather,
          candidates: candidates,
          apiKey: profile.museApiKey,
        );
        final picks = suggestion?.picks
                .where((q) => !_dismissed.contains(q.quest.id))
                .toList() ??
            [];
        if (picks.isNotEmpty) {
          ranked = picks;
          if (suggestion!.reasoning.isNotEmpty) line = suggestion.reasoning;
          museUsed = true;
        }
      }
      quests = ranked;
      reasoning = line;
      final quiet = inQuietHours(now);
      final nightQuest = quests.isNotEmpty &&
          quests.first.quest.tags
              .toSet()
              .intersection({'night', 'stargazing', 'live music'})
              .isNotEmpty;
      if (autoNudge &&
          !_autoNudged &&
          context.traveling &&
          profile.skillEnabled &&
          profile.suggestWhenTraveling &&
          (!quiet ||
              (profile.nudgeStyle == NudgeStyle.bold && nightQuest))) {
        _autoNudged = true;
        await sendNudge(profile);
      }
    } finally {
      hasLoaded = true;
      loading = false;
      notifyListeners();
    }
  }

  /// Manual nudge. Always allowed, and speaks when audio cues are on.
  Future<void> sendNudge(UserProfile profile) async {
    if (quests.isEmpty) return;
    await notifications.nudge(
      quests.first.quest,
      bold: profile.nudgeStyle == NudgeStyle.bold,
      speak: profile.audioCues,
    );
  }

  void setSearchPoint(double lat, double lon, String label) {
    searchLat = lat;
    searchLon = lon;
    searchLabel = label;
    notifyListeners();
  }

  void clearSearchPoint() {
    searchLat = null;
    searchLon = null;
    searchLabel = '';
    notifyListeners();
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
