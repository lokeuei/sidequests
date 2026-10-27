import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sidequests/services/geocode_service.dart';

const _fixture = '''
[
  {"lat": "47.6062", "lon": "-122.3321",
   "display_name": "Seattle, King County, Washington, USA"},
  {"lat": "47.6101", "lon": "-122.2015",
   "display_name": "Bellevue, King County, Washington, USA"},
  {"lat": "", "lon": "", "display_name": "Nowhere"}
]
''';

void main() {
  test('parses hits and skips junk', () {
    final hits = parseGeocode(_fixture);
    expect(hits.length, 2);
    expect(hits.first.label, 'Seattle, King County');
    expect(hits.first.latitude, closeTo(47.6062, 0.0001));
    expect(hits.first.longitude, closeTo(-122.3321, 0.0001));
    expect(hits[1].label, 'Bellevue, King County');
  });

  test('bad payloads yield no hits, never a crash', () {
    expect(parseGeocode('nope'), isEmpty);
    expect(parseGeocode('{}'), isEmpty);
  });

  test('empty query means no network', () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('[]', 200);
    });
    expect(await GeocodeService().search('  ', client: client), isEmpty);
    expect(called, isFalse);
  });

  test('search hits Nominatim and parses', () async {
    String? seenHost;
    String? seenQuery;
    final client = MockClient((request) async {
      seenHost = request.url.host;
      seenQuery = request.url.queryParameters['q'];
      return http.Response(_fixture, 200);
    });
    final hits = await GeocodeService().search('Seattle', client: client);
    expect(seenHost, 'nominatim.openstreetmap.org');
    expect(seenQuery, 'Seattle');
    expect(hits.length, 2);
  });
}
