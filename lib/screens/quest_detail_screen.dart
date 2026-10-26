import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/services/suggestion_engine.dart';
import 'package:sidequests/state/profile_provider.dart';
import 'package:sidequests/state/quest_provider.dart';

class QuestDetailScreen extends StatelessWidget {
  const QuestDetailScreen({super.key, required this.scored});

  final ScoredQuest scored;

  @override
  Widget build(BuildContext context) {
    final quest = scored.quest;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final profiles = context.watch<ProfileProvider>();
    final quests = context.read<QuestProvider>();
    final saved = profiles.profile.savedQuestIds.contains(quest.id);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            '${quest.category.label} · ${quest.bestWindow}',
            style: text.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 6),
          Text(quest.title, style: text.displayMedium),
          const SizedBox(height: 10),
          Text(quest.blurb, style: text.bodyLarge),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.tertiary.withValues(alpha: 0.16),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: scheme.tertiary),
                    const SizedBox(width: 8),
                    Text('Why now', style: text.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  scored.reason,
                  style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 6),
                Text(quest.why, style: text.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metaTile(context, 'Distance', quest.distanceLabel),
              const SizedBox(width: 10),
              _metaTile(context, 'Duration', quest.durationLabel),
              const SizedBox(width: 10),
              _metaTile(context, 'Best for', quest.bestWindow),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.35),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.map_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live maps plug in here — for now, follow your feet.',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await profiles.update((p) => p.noteEngagement(quest.tags, 3));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Have fun out there.')),
                );
              },
              icon: const Icon(Icons.directions_walk),
              label: const Text("Let's go"),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => profiles.toggleSave(quest),
                  icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                  label: Text(saved ? 'Saved' : 'Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    await profiles.update(
                      (p) => p.noteEngagement(quest.tags, -2),
                    );
                    quests.dismiss(quest.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(scored);
                  },
                  child: const Text('Not now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaTile(BuildContext context, String label, String value) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: text.titleMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
