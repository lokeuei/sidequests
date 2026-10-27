import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/services/context_service.dart';
import 'package:sidequests/services/events_service.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/places_service.dart';
import 'package:sidequests/services/suggestion_engine.dart';
import 'package:sidequests/state/quest_provider.dart';

class _FakeContext extends ContextService {
  @override
  Future<DeviceContext> current({
    double? homeLatitude,
    double? homeLongitude,
  }) async =>
      const DeviceContext(latitude: 47.6, longitude: -122.3);
}

class _RecordingPlaces extends PlacesService {
  double? seenLat;
  double? seenLon;

  @override
  Future<PlacesOutcome> nearby(
    double latitude,
    double longitude, {
    http.Client? client,
  }) async {
    seenLat = latitude;
    seenLon = longitude;
    return const PlacesOutcome(quests: [], failed: false);
  }
}

class _RecordingEvents extends EventsService {
  double? seenLat;
  double? seenLon;
  List<Quest> items = [];

  @override
  Future<List<Quest>> upcoming(
    double latitude,
    double longitude, {
    String? apiKey,
    http.Client? client,
  }) async {
    seenLat = latitude;
    seenLon = longitude;
    return items;
  }
}

QuestProvider _provider(_RecordingPlaces places, _RecordingEvents events) {
  return QuestProvider(
    contextService: _FakeContext(),
    notifications: NotificationService.memory(),
    places: places,
    events: events,
  );
}

const _gig = Quest(
  id: 'tm-9',
  title: 'Riverside Gig',
  blurb: 'Pier Hall. Tickets still listed.',
  category: QuestCategory.social,
  minutes: 120,
  meters: 500,
  tags: ['events', 'live music', 'social'],
  why: 'On Saturday.',
  bestWindow: 'Saturday',
);

void main() {
  test('refresh searches the dropped point when set', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents();
    final quests = _provider(places, events);
    quests.setSearchPoint(47.61, -122.2, 'Bellevue, King County');
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(places.seenLat, 47.61);
    expect(places.seenLon, -122.2);
    expect(events.seenLat, 47.61);
    expect(events.seenLon, -122.2);
    expect(quests.searchingElsewhere, isTrue);
  });

  test('clearing the point returns to the device location', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents();
    final quests = _provider(places, events);
    quests.setSearchPoint(47.61, -122.2, 'Bellevue, King County');
    quests.clearSearchPoint();
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(places.seenLat, 47.6);
    expect(places.seenLon, -122.3);
    expect(quests.searchingElsewhere, isFalse);
  });

  test('gigs light the gigs flag', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents()..items = [_gig];
    final quests = _provider(places, events);
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(quests.liveGigs, isTrue);
    expect(quests.livePlaces, isTrue);
  });

  test('no gigs leaves the gigs flag off', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents();
    final quests = _provider(places, events);
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(quests.liveGigs, isFalse);
  });

  test('refresh narrates its phases and goes quiet', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents()..items = [_gig];
    final quests = _provider(places, events);
    final seen = <String>[];
    quests.addListener(() => seen.add(quests.loadStatus));
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(seen, contains('Reading location…'));
    expect(seen, contains('Looking around…'));
    expect(seen, isNot(contains('Asking Mint…')));
    expect(quests.loadStatus, isEmpty);
  });

  test('brief speaks when quests exist', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents()..items = [_gig];
    final quests = _provider(places, events);
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(await quests.brief(UserProfile()), 'Speaking your brief.');
  });

  test('brief text names three in order', () {
    final text = buildBrief([
      const ScoredQuest(quest: _gig, score: 90, reason: 'On Saturday.'),
    ]);
    expect(text, "Here's your brief. First, Riverside Gig. On Saturday.");
    expect(buildBrief([]), 'Nothing to brief yet.');
  });

  test('explain reads one quest aloud', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents()..items = [_gig];
    final quests = _provider(places, events);
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(
      await quests.explainQuest(_gig, UserProfile()),
      'Mint is explaining it.',
    );
  });

  test('quest speech covers the essentials', () {
    final text = buildQuestSpeech(_gig);
    expect(text, startsWith('Riverside Gig.'));
    expect(text, contains('Pier Hall'));
    expect(text, contains('On Saturday.'));
    expect(text, contains('Best Saturday.'));
  });

  test('refresh stamps when it finished', () async {
    final places = _RecordingPlaces();
    final events = _RecordingEvents();
    final quests = _provider(places, events);
    expect(quests.refreshedAt, isNull);
    await quests.refresh(UserProfile(), autoNudge: false);
    expect(quests.refreshedAt, isNotNull);
    expect(DateTime.now().difference(quests.refreshedAt!),
        lessThan(const Duration(minutes: 1)));
  });
}
