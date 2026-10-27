import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/weather.dart';

/// Ticketmaster events near the user. Needs a free key passed as
/// --dart-define=TICKETMASTER_KEY=.... Without a key it returns [] and
/// the app simply ranks places and samples.
class EventsService {
  Future<List<Quest>> upcoming(double latitude, double longitude) async {
    const key = String.fromEnvironment('TICKETMASTER_KEY');
    if (key.isEmpty) return [];
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final uri = Uri.parse(
        'https://app.ticketmaster.com/discovery/v2/events.json'
        '?apikey=$key&latlong=$latitude,$longitude&radius=25&unit=km'
        '&size=20&sort=date,asc&startDateTime=$now',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      return parseTicketmaster(response.body, DateTime.now(), latitude, longitude);
    } catch (_) {
      return [];
    }
  }
}

/// Pure Ticketmaster parser. Keeps events starting within 14 days.
List<Quest> parseTicketmaster(String body, DateTime now, double userLat, double userLng) {
  final quests = <Quest>[];
  try {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final embedded = decoded['_embedded'] as Map<String, dynamic>?;
    final events = (embedded?['events'] as List?) ?? [];
    for (final event in events) {
      if (quests.length >= 10) break;
      final item = event as Map<String, dynamic>?;
      if (item == null) continue;
      final name = (item['name'] ?? '').toString().trim();
      final dates = item['dates'] as Map<String, dynamic>?;
      final start = dates?['start'] as Map<String, dynamic>?;
      final startIso = (start?['dateTime'] ?? '').toString();
      if (name.isEmpty || startIso.isEmpty) continue;
      final startsAt = DateTime.tryParse(startIso);
      if (startsAt == null) continue;
      final daysOut = startsAt.difference(now).inDays;
      if (daysOut < 0 || daysOut > 14) continue;

      final venues = (item['_embedded'] as Map<String, dynamic>?)?['venues'] as List?;
      final venue = (venues != null && venues.isNotEmpty)
          ? venues.first as Map<String, dynamic>?
          : null;
      final location = venue?['location'] as Map<String, dynamic>?;
      final vLat = double.tryParse((location?['latitude'] ?? '').toString());
      final vLng = double.tryParse((location?['longitude'] ?? '').toString());
      final venueName = (venue?['name'] ?? '').toString();
      final classifications = item['classifications'] as List?;
      final firstClass = (classifications != null && classifications.isNotEmpty)
          ? classifications.first as Map<String, dynamic>?
          : null;
      final segment = ((firstClass?['segment'] as Map<String, dynamic>?)?['name'] ?? '').toString();
      final day = startIso.length >= 10 ? weekdayLabel(startIso.substring(0, 10)) : '';

      quests.add(Quest(
        id: 'tm-${item['id']}',
        title: name,
        blurb: venueName.isEmpty ? 'Tickets still listed.' : '$venueName. Tickets still listed.',
        category: segment == 'Arts & Theatre' ? QuestCategory.culture : QuestCategory.social,
        minutes: 120,
        meters: vLat != null && vLng != null ? _meters(userLat, userLng, vLat, vLng).round() : 0,
        tags: _tagsFor(segment),
        why: day.isEmpty ? 'Tickets still listed.' : 'On $day.',
        bestWindow: day.isEmpty ? 'See listing' : day,
        latitude: vLat,
        longitude: vLng,
        startsAt: startIso,
      ));
    }
  } catch (_) {
    return quests;
  }
  return quests;
}

List<String> _tagsFor(String segment) {
  if (segment == 'Music') return ['events', 'live music', 'social'];
  if (segment == 'Arts & Theatre') return ['events', 'local gems'];
  if (segment == 'Sports') return ['events', 'social'];
  return ['events', 'social'];
}

double _meters(double lat1, double lng1, double lat2, double lng2) {
  const earth = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * earth * asin(sqrt(a));
}
