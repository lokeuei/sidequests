import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:sidequests/models/quest.dart';

/// Real nearby places from OpenStreetMap via the Overpass API. Keyless.
/// Falls back to an empty list (the app then shows an empty state).
class PlacesService {
  /// Public Overpass instances, tried in order. Single instances flap
  /// often enough that failover is worth it.
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  Future<List<Quest>> nearby(double latitude, double longitude) async {
    final query = '''
[out:json][timeout:15];
(
  nwr(around:2500,$latitude,$longitude)["name"]["tourism"~"viewpoint|museum|attraction|artwork|gallery"];
  nwr(around:2500,$latitude,$longitude)["name"]["leisure"~"park|garden|nature_reserve"];
  nwr(around:2500,$latitude,$longitude)["name"]["historic"];
  nwr(around:2000,$latitude,$longitude)["name"]["amenity"~"marketplace|cafe"];
);
out center 30;
''';
    for (final endpoint in _endpoints) {
      try {
        final uri = Uri.parse(
          '$endpoint?data=${Uri.encodeQueryComponent(query)}',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) continue;
        final quests = parseOverpass(response.body, latitude, longitude);
        if (quests.isNotEmpty) return quests;
      } catch (_) {
        continue;
      }
    }
    return [];
  }
}

/// Pure Overpass JSON parser, so tests can pin the mapping down.
List<Quest> parseOverpass(String body, double latitude, double longitude) {
  final quests = <Quest>[];
  final seen = <String>{};
  try {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List?) ?? [];
    for (final element in elements) {
      if (quests.length >= 12) break;
      final item = element as Map<String, dynamic>?;
      if (item == null) continue;
      final tags = (item['tags'] as Map?) ?? {};
      final name = (tags['name'] ?? '').toString().trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;

      final point = _pointOf(item);
      if (point == null) continue;
      final kind = _kindOf(tags);
      if (kind == null) continue;

      final meters = _meters(latitude, longitude, point.$1, point.$2).round();
      quests.add(Quest(
        id: 'osm-${item['type']}-${item['id']}',
        title: name,
        blurb: kind.blurb,
        category: kind.category,
        minutes: (15 + meters ~/ 80).clamp(10, 120),
        meters: meters,
        tags: kind.tags,
        why: kind.why,
        bestWindow: kind.bestWindow,
        latitude: point.$1,
        longitude: point.$2,
      ));
    }
  } catch (_) {
    return quests;
  }
  return quests;
}

(double, double)? _pointOf(Map<String, dynamic> item) {
  final lat = (item['lat'] as num?)?.toDouble();
  final lon = (item['lon'] as num?)?.toDouble();
  if (lat != null && lon != null) return (lat, lon);
  final center = item['center'] as Map<String, dynamic>?;
  final cLat = (center?['lat'] as num?)?.toDouble();
  final cLon = (center?['lon'] as num?)?.toDouble();
  if (cLat != null && cLon != null) return (cLat, cLon);
  return null;
}

_Kind? _kindOf(Map tags) {
  String value(Object? key) => (tags[key] ?? '').toString();
  final tourism = value('tourism');
  final leisure = value('leisure');
  final amenity = value('amenity');
  final historic = value('historic');

  if (tourism == 'viewpoint') {
    return const _Kind(QuestCategory.outdoors, ['viewpoints', 'outdoors', 'evenings'],
        'A view worth the walk.', 'The view does the work.', 'Sunset');
  }
  if (tourism == 'museum' || tourism == 'gallery') {
    return const _Kind(QuestCategory.culture, ['museums', 'history', 'quiet'],
        'Worth an hour inside.', 'Someone curated this for you.', 'Anytime');
  }
  if (tourism == 'attraction') {
    return const _Kind(QuestCategory.culture, ['local gems', 'history'],
        'People come here on purpose.', 'Worth seeing once.', 'Anytime');
  }
  if (tourism == 'artwork') {
    return const _Kind(QuestCategory.culture, ['street art', 'local gems'],
        'Public art, free to see.', 'It changes the street.', 'Daylight');
  }
  if (leisure == 'park' || leisure == 'garden') {
    return const _Kind(QuestCategory.quiet, ['quiet', 'outdoors', 'mornings'],
        'Green space, free entry.', 'The city is loud. Parks are not.', 'Mornings');
  }
  if (leisure == 'nature_reserve') {
    return const _Kind(QuestCategory.outdoors, ['outdoors', 'quiet'],
        'Wild edges close to home.', 'Proper quiet.', 'Daylight');
  }
  if (amenity == 'marketplace') {
    return const _Kind(QuestCategory.food, ['food markets', 'social'],
        'Stalls, snacks, and noise.', 'Go hungry.', 'Weekends');
  }
  if (amenity == 'cafe') {
    return const _Kind(QuestCategory.food, ['cafes', 'mornings'],
        'Good coffee near you.', 'Worth the detour.', 'Mornings');
  }
  if (historic.isNotEmpty) {
    return const _Kind(QuestCategory.culture, ['history', 'architecture', 'local gems'],
        'Older than everything around it.', 'Built before everything around it.', 'Anytime');
  }
  return null;
}

class _Kind {
  const _Kind(this.category, this.tags, this.blurb, this.why, this.bestWindow);

  final QuestCategory category;
  final List<String> tags;
  final String blurb;
  final String why;
  final String bestWindow;
}

double _meters(double lat1, double lng1, double lat2, double lng2) {
  const earth = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * earth * asin(sqrt(a));
}
