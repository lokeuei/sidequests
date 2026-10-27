import 'dart:convert';

import 'package:http/http.dart' as http;

/// Keyless place lookup via Nominatim (OpenStreetMap). Handles "Seattle",
/// "Bellevue", even "near the Seatac airport".
class GeocodeService {
  Future<List<GeocodeHit>> search(String query, {http.Client? client}) async {
    if (query.trim().isEmpty) return [];
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query.trim())}'
        '&format=jsonv2&limit=5&addressdetails=0',
      );
      final response = await httpClient
          .get(uri, headers: {'User-Agent': 'sidequests-app/1.0'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      return parseGeocode(response.body);
    } catch (_) {
      return [];
    } finally {
      if (client == null) httpClient.close();
    }
  }
}

class GeocodeHit {
  const GeocodeHit({
    required this.label,
    required this.detail,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String detail;
  final double latitude;
  final double longitude;
}

/// Pure Nominatim parser. Short label is the first two name parts.
List<GeocodeHit> parseGeocode(String body) {
  final hits = <GeocodeHit>[];
  try {
    final decoded = jsonDecode(body) as List?;
    for (final entry in decoded ?? []) {
      if (hits.length >= 5) break;
      final map = entry as Map<String, dynamic>?;
      if (map == null) continue;
      final lat = double.tryParse((map['lat'] ?? '').toString());
      final lon = double.tryParse((map['lon'] ?? '').toString());
      final display = (map['display_name'] ?? '').toString().trim();
      if (lat == null || lon == null || display.isEmpty) continue;
      final parts = display.split(',').map((p) => p.trim()).toList();
      hits.add(GeocodeHit(
        label: parts.take(2).join(', '),
        detail: display,
        latitude: lat,
        longitude: lon,
      ));
    }
  } catch (_) {
    return hits;
  }
  return hits;
}
