import 'package:flutter_test/flutter_test.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/services/events_service.dart';

const _fixture = '''
{
  "_embedded": {
    "events": [
      {"id": "1", "name": "Harbor Jazz Night",
       "dates": {"start": {"dateTime": "2026-11-02T19:00:00Z"}},
       "classifications": [{"segment": {"name": "Music"}}],
       "_embedded": {"venues": [{"name": "Pier Hall",
         "location": {"latitude": "59.901", "longitude": "10.701"}}]}},
      {"id": "2", "name": "Old Year Show",
       "dates": {"start": {"dateTime": "2026-01-02T19:00:00Z"}},
       "_embedded": {"venues": [{"name": "Pier Hall",
         "location": {"latitude": "59.901", "longitude": "10.701"}}]}},
      {"id": "3", "name": "",
       "dates": {"start": {"dateTime": "2026-11-03T19:00:00Z"}}}
    ]
  }
}
''';

void main() {
  test('parses upcoming events and skips the rest', () {
    final quests = parseTicketmaster(_fixture, DateTime.utc(2026, 10, 27), 59.9, 10.7);
    expect(quests.length, 1);

    final gig = quests.first;
    expect(gig.title, 'Harbor Jazz Night');
    expect(gig.category, QuestCategory.social);
    expect(gig.tags, contains('events'));
    expect(gig.tags, contains('live music'));
    expect(gig.latitude, 59.901);
    expect(gig.meters, greaterThan(0));
    expect(gig.startsAt, '2026-11-02T19:00:00Z');
    expect(gig.bestWindow, isNotEmpty);
  });

  test('bad payloads yield no events, never a crash', () {
    expect(parseTicketmaster('nope', DateTime.utc(2026, 10, 27), 59.9, 10.7), isEmpty);
    expect(parseTicketmaster('{}', DateTime.utc(2026, 10, 27), 59.9, 10.7), isEmpty);
  });

  test('no key means no events and no network', () async {
    final service = EventsService();
    expect(await service.upcoming(59.9, 10.7), isEmpty);
  });
}
