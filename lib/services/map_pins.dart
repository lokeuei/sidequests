import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:sidequests/models/quest.dart';

/// A pin to draw on the map.
class MapPin {
  const MapPin({
    required this.point,
    required this.label,
    required this.questId,
    required this.category,
  });

  final LatLng point;
  final String label;
  final String questId;
  final QuestCategory category;
}

/// Pins for quests. Live quests carry true coordinates; the rare one
/// without gets a deterministic preview offset around the user.
List<MapPin> pinsForQuests(double centerLat, double centerLng, List<Quest> quests) {
  final pins = <MapPin>[];
  for (var i = 0; i < quests.length; i++) {
    final quest = quests[i];
    pins.add(MapPin(
      point: questPoint(centerLat, centerLng, quest, i),
      label: quest.title,
      questId: quest.id,
      category: quest.category,
    ));
  }
  return pins;
}

/// True coordinates when the quest has them, else a stable preview offset.
LatLng questPoint(double centerLat, double centerLng, Quest quest, int index) {
  if (quest.latitude != null && quest.longitude != null) {
    return LatLng(quest.latitude!, quest.longitude!);
  }
  return previewPin(centerLat, centerLng, quest.id, index);
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
