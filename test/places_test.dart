import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/places_service.dart';

const _fixture = '''
{
  "elements": [
    {"type": "node", "id": 1, "lat": 59.901, "lon": 10.701,
     "tags": {"name": "Harbor Lookout", "tourism": "viewpoint"}},
    {"type": "way", "id": 2,
     "center": {"lat": 59.899, "lon": 10.699},
     "tags": {"name": "Corner Grind", "amenity": "cafe"}},
    {"type": "node", "id": 3, "lat": 59.9, "lon": 10.7, "tags": {}},
    {"type": "node", "id": 4, "tags": {"name": "Nowhere", "tourism": "museum"}}
  ]
}
''';

void main() {
  test('parses live places and skips junk entries', () {
    final quests = parseOverpass(_fixture, 59.9, 10.7);
    expect(quests.length, 2);

    final lookout = quests.firstWhere((q) => q.title == 'Harbor Lookout');
    expect(lookout.category, QuestCategory.outdoors);
    expect(lookout.tags, contains('viewpoints'));
    expect(lookout.latitude, 59.901);
    expect(lookout.meters, greaterThan(0));
    expect(lookout.minutes, greaterThan(0));

    final cafe = quests.firstWhere((q) => q.title == 'Corner Grind');
    expect(cafe.category, QuestCategory.food);
    expect(cafe.tags, contains('cafes'));
    expect(cafe.latitude, 59.899);
  });

  test('bad payloads yield no places, never a crash', () {
    expect(parseOverpass('nope', 59.9, 10.7), isEmpty);
    expect(parseOverpass('{"elements": []}', 59.9, 10.7), isEmpty);
  });

  test('time labels keep minutes', () {
    expect(timeLabel('2026-10-27T06:42'), '6:42 AM');
    expect(timeLabel('2026-10-27T19:05'), '7:05 PM');
    expect(timeLabel('2026-10-27T12:00'), '12:00 PM');
    expect(timeLabel('nope'), '');
  });

  test('first answering endpoint wins the race', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'overpass-api.de') {
        return http.Response('busy', 429);
      }
      return http.Response(_fixture, 200);
    });
    final outcome = await PlacesService().nearby(59.9, 10.7, client: client);
    expect(outcome.failed, isFalse);
    expect(outcome.quests.length, 2);
  });

  test('all endpoints failing is reported, not silent', () async {
    final client = MockClient((request) async => http.Response('down', 500));
    final outcome = await PlacesService().nearby(59.9, 10.7, client: client);
    expect(outcome.failed, isTrue);
    expect(outcome.quests, isEmpty);
  });

  test('answered but bare ground is not a failure', () async {
    final client = MockClient(
      (request) async => http.Response('{"elements": []}', 200),
    );
    final outcome = await PlacesService().nearby(59.9, 10.7, client: client);
    expect(outcome.failed, isFalse);
    expect(outcome.quests, isEmpty);
  });
}
