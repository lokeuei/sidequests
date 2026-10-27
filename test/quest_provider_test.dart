import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/services/context_service.dart';
import 'package:sidequests/services/events_service.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/places_service.dart';
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
  Future<List<Quest>> nearby(double latitude, double longitude) async {
    seenLat = latitude;
    seenLon = longitude;
    return [];
  }
}

class _RecordingEvents extends EventsService {
  double? seenLat;
  double? seenLon;

  @override
  Future<List<Quest>> upcoming(
    double latitude,
    double longitude, {
    String? apiKey,
    http.Client? client,
  }) async {
    seenLat = latitude;
    seenLon = longitude;
    return [];
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
}
