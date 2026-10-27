import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:sidequests/models/quest.dart';

/// A pin to draw on the map.
class MapPin {
  const MapPin({required this.point, required this.label});

  final LatLng point;
  final String label;
}

/// Preview positions for sample quests: deterministic offsets around the
/// user, so pins sit still between refreshes. Live places will carry
/// real coordinates and replace this.
List<MapPin> pinsForQuests(double centerLat, double centerLng, List<Quest> quests) {
  final pins = <MapPin>[];
  for (var i = 0; i < quests.length; i++) {
    pins.add(MapPin(
      point: previewPin(centerLat, centerLng, quests[i].id, i),
      label: quests[i].title,
    ));
  }
  return pins;
}

/// Deterministic pseudo-position for one quest id. Same input, same pin.
LatLng previewPin(double centerLat, double centerLng, String questId, int index) {
  var hash = 0;
  for (final unit in questId.codeUnits) {
    hash = (hash * 31 + unit) % 100000;
  }
  final angle = (hash % 360) * pi / 180 + index * 0.7;
  final meters = 250 + (hash % 900);
  final latDegree = meters * sin(angle) / 111320;
  final lngDegree = meters * cos(angle) / (111320 * cos(centerLat * pi / 180));
  return LatLng(centerLat + latDegree, centerLng + lngDegree);
}
