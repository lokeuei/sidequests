import 'package:flutter/material.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/services/suggestion_engine.dart';
import 'package:sidequests/widgets/enter_animation.dart';
import 'package:sidequests/widgets/quest_art.dart';

/// A ranked quest with painted cover art. The top pick is bigger and louder;
/// the rest vary in radius so the list never reads as a template grid.
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.scored,
    required this.index,
    required this.saved,
    this.onTap,
    this.onSave,
    this.onExplain,
  });

  final ScoredQuest scored;
  final int index;
  final bool saved;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final quest = scored.quest;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final big = index == 0;
    final radius = big ? 28.0 : (index.isOdd ? 22.0 : 18.0);
    final background = big ? scheme.primary : scheme.surface;
    final onBackground = big ? scheme.onPrimary : scheme.onSurface;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: big
            ? BorderSide.none
            : BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestArt(category: quest.category, height: big ? 150 : 110),
            Padding(
              padding: EdgeInsets.all(big ? 22 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: big ? 44 : 38,
                        height: big ? 44 : 38,
                        decoration: BoxDecoration(
                          color: onBackground.withValues(alpha: big ? 0.16 : 0.08),
                          borderRadius:
                              BorderRadius.circular(big ? 16 : 12),
                        ),
                        child: Icon(
                          _iconFor(quest.category),
                          color: onBackground,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${quest.category.label} · ${quest.bestWindow}',
                          style: text.bodySmall?.copyWith(
                            color: onBackground.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onExplain,
                        icon: const Icon(Icons.volume_up),
                        color: onBackground.withValues(alpha: 0.75),
                        tooltip: 'Mint explains it',
                      ),
                      IconButton(
                        onPressed: onSave,
                        icon: Icon(
                          saved ? Icons.favorite : Icons.favorite_border,
                        ),
                        color: big ? onBackground : scheme.secondary,
                        tooltip: saved ? 'Saved' : 'Save',
                      ),
                    ],
                  ),
                  SizedBox(height: big ? 14 : 10),
                  Text(
                    quest.title,
                    style: (big ? text.displaySmall : text.titleLarge)
                        ?.copyWith(color: onBackground),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quest.blurb,
                    maxLines: big ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: onBackground.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: onBackground.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          scored.reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: onBackground.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 16,
                        color: onBackground.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${quest.distanceLabel} · ${quest.durationLabel}',
                        style: text.bodySmall?.copyWith(
                          color: onBackground.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward,
                        size: 16,
                        color: onBackground.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).enter(context, delayMs: 70 * index);
  }

  IconData _iconFor(QuestCategory category) {
    return switch (category) {
      QuestCategory.outdoors => Icons.landscape,
      QuestCategory.culture => Icons.museum,
      QuestCategory.food => Icons.restaurant,
      QuestCategory.water => Icons.waves,
      QuestCategory.night => Icons.nights_stay,
      QuestCategory.social => Icons.groups,
      QuestCategory.quiet => Icons.spa,
    };
  }
}
