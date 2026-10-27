import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sidequests/services/map_pins.dart';
import 'package:sidequests/widgets/quest_art.dart';

/// OpenStreetMap view with photo pins and a you-are-here dot.
/// Needs no API key; tiles load over the network.
class QuestMap extends StatelessWidget {
  const QuestMap({
    super.key,
    required this.center,
    required this.pins,
    this.userPoint,
    this.searchPoint,
    this.onPinTap,
    this.onMapTap,
    this.height = 200,
    this.zoom = 14,
    this.fill = false,
  });

  final LatLng center;
  final List<MapPin> pins;

  /// Where the user dot goes. Defaults to the center.
  final LatLng? userPoint;

  /// Dropped search pin. Null hides it.
  final LatLng? searchPoint;

  /// Fires with the tapped pin. Null leaves pins still.
  final void Function(MapPin pin)? onPinTap;

  /// Fires with the tapped map point. Null leaves the map still.
  final void Function(LatLng point)? onMapTap;
  final double height;
  final double zoom;

  /// Edge-to-edge map with floating attribution, for map-first screens.
  final bool fill;

  static const _dotBlue = Color(0xFF2E7CF6);

  @override
  Widget build(BuildContext context) {
    if (fill) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _map(context),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ),
        ],
      );
    }
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
            child: _map(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          onMapTap == null
              ? 'Map data: OpenStreetMap contributors.'
              : 'Tap the map to search there. Map: OpenStreetMap.',
          style: text.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _map(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: onMapTap == null ? null : (_, point) => onMapTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sidequests.sidequests',
        ),
        MarkerLayer(
          markers: [
            for (final pin in pins)
              Marker(
                point: pin.point,
                width: 58,
                height: 58,
                child: GestureDetector(
                  onTap: onPinTap == null ? null : () => onPinTap!(pin),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(16)),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(13)),
                      child: QuestArt(
                        category: pin.category,
                        height: 58,
                      ),
                    ),
                  ),
                ),
              ),
            if (searchPoint != null)
              Marker(
                point: searchPoint!,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surface,
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    Icons.search,
                    color: scheme.onTertiary,
                    size: 22,
                  ),
                ),
              ),
            Marker(
              point: userPoint ?? center,
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _dotBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _dotBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
