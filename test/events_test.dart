import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  test('stored key fetches events', () async {
    final start = DateTime.now()
        .toUtc()
        .add(const Duration(days: 3))
        .toIso8601String();
    final body = jsonEncode({
      '_embedded': {
        'events': [
          {
            'id': '9',
            'name': 'Riverside Gig',
            'dates': {
              'start': {'dateTime': start},
            },
            'classifications': [
              {
                'segment': {'name': 'Music'},
              },
            ],
            '_embedded': {
              'venues': [
                {
                  'name': 'Pier Hall',
                  'location': {'latitude': '59.901', 'longitude': '10.701'},
                },
              ],
            },
          },
        ],
      },
    });
    String? seenKey;
    final client = MockClient((request) async {
      seenKey = request.url.queryParameters['apikey'];
      return http.Response(body, 200);
    });
    final quests =
        await EventsService().upcoming(59.9, 10.7, apiKey: 'tm-key', client: client);
    expect(seenKey, 'tm-key');
    expect(quests.length, 1);
    expect(quests.first.title, 'Riverside Gig');
  });

  test('event lookup asks for nearby gigs from now on', () async {
    Uri? seenUri;
    final client = MockClient((request) async {
      seenUri = request.url;
      return http.Response('{"_embedded": {"events": []}}', 200);
    });
    await EventsService()
        .upcoming(47.6, -122.3, apiKey: 'tm-key', client: client);
    final params = seenUri!.queryParameters;
    expect(seenUri!.host, 'app.ticketmaster.com');
    expect(params['latlong'], '47.6,-122.3');
    expect(params['radius'], '25');
    expect(params['unit'], 'km');
    expect(params['size'], '20');
    expect(params['sort'], 'date,asc');
    expect(
      params['startDateTime'],
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')),
    );
  });
}
