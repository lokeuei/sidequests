import 'package:flutter/material.dart';
import 'package:sidequests/models/weather.dart';

/// Classic weather app block: big temp, condition, hourly strip, daily rows.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather, this.tempUnit = 'c'});

  final WeatherInfo weather;
  final String tempUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tempLabel(weather.temperatureC, tempUnit),
                style: text.displayLarge,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _iconFor(weather.code),
                            size: 18,
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              weatherLabel(weather.code),
                              style: text.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'H:${tempLabel(weather.highC, tempUnit)} L:${tempLabel(weather.lowC, tempUnit)}',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (weather.sunrise.isNotEmpty && weather.sunset.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.wb_twilight, size: 16, color: scheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Sunrise ${timeLabel(weather.sunrise)} · Sunset ${timeLabel(weather.sunset)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ],
          if (weather.hourly.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weather.hourly.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, i) {
                  final h = weather.hourly[i];
                  return SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        Text(
                          i == 0 ? 'Now' : hourLabel(h.timeIso),
                          style: text.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Icon(_iconFor(h.code), size: 20),
                        const SizedBox(height: 6),
                        Text(
                          tempLabel(h.temperatureC, tempUnit),
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (weather.daily.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...weather.daily.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        i == 0 ? 'Today' : weekdayLabel(d.dateIso),
                        style: text.bodyMedium,
                      ),
                    ),
                    Icon(_iconFor(d.code), size: 20),
                    const Spacer(),
                    Text(
                      tempLabel(d.minC, tempUnit),
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tempLabel(d.maxC, tempUnit),
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(int code) {
    if (code == 0 || code == 1) return Icons.wb_sunny;
    if (code == 2) return Icons.wb_cloudy;
    if (code == 3 || code == 45 || code == 48) return Icons.cloud;
    if (code >= 51 && code <= 67 || code >= 80 && code <= 82) {
      return Icons.water_drop;
    }
    if (code >= 71 && code <= 77) return Icons.grain;
    if (code >= 95 && code <= 99) return Icons.thunderstorm;
    return Icons.cloud;
  }
}
