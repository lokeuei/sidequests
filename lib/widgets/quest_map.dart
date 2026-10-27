import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sidequests/services/map_pins.dart';

/// OpenStreetMap view with quest pins and a you-are-here dot.
/// Needs no API key; tiles load over the network.
class QuestMap extends StatelessWidget {
  const QuestMap({
    super.key,
    required this.center,
    required this.pins,
    this.userPoint,
    this.height = 200,
    this.zoom = 14,
  });

  final LatLng center;
  final List<MapPin> pins;

  /// Where the user dot goes. Defaults to the center.
  final LatLng? userPoint;
  final double height;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sidequests.sidequests',
                ),
                MarkerLayer(
                  markers: [
                    for (final pin in pins)
                      Marker(
                        point: pin.point,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.surface,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: scheme.onSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    Marker(
                      point: userPoint ?? center,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.surface,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Map data: OpenStreetMap contributors.',
          style: text.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
