import 'package:flutter/material.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/context_service.dart';
import 'package:sidequests/services/suggestion_engine.dart';

/// The automatic inputs, at a glance: daylight, temperature, place, travel.
class ContextRow extends StatelessWidget {
  const ContextRow({
    super.key,
    required this.device,
    required this.hour,
    this.tempUnit = 'c',
  });

  final DeviceContext device;
  final int hour;
  final String tempUnit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(context, Icons.wb_twilight, daylightLabel(hour)),
        if (device.temperatureC != null)
          _chip(
            context,
            Icons.thermostat,
            tempLabel(device.temperatureC!, tempUnit),
          ),
        _chip(context, Icons.place_outlined, device.placeLabel),
        if (device.traveling)
          _chip(context, Icons.flight_takeoff, 'Away from home', highlight: true),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, {bool highlight = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? scheme.secondary.withValues(alpha: 0.15) : scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlight
                ? scheme.secondary
                : scheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
