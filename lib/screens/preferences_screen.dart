import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/screens/quest_detail_screen.dart';
import 'package:sidequests/services/nudge_scheduler.dart';
import 'package:sidequests/services/suggestion_engine.dart';
import 'package:sidequests/state/profile_provider.dart';
import 'package:sidequests/widgets/enter_animation.dart';
import 'package:sidequests/widgets/section_header.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<ProfileProvider>().profile.displayName,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileProvider>();
    final profile = profiles.profile;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final saved = profile.savedQuests;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('You', style: text.displayMedium).enter(context),
        const SizedBox(height: 6),
        Text(
          'Muse learns from your taps, saves, and strolls. '
          'The more you tell it, the better its picks.',
          style: text.bodyMedium,
        ).enter(context, delayMs: 60),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Name'),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'What should Muse call you?',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) =>
              profiles.update((p) => p.displayName = value.trim()),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Love', note: 'tap to toggle'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final interest in kAllInterests)
              FilterChip(
                label: Text(interest),
                selected: profile.interests.contains(interest),
                onSelected: (selected) => profiles.update((p) {
                  if (selected) {
                    p.interests.add(interest);
                    p.avoid.remove(interest);
                  } else {
                    p.interests.remove(interest);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Less of'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final interest in kAllInterests)
              FilterChip(
                label: Text(interest),
                selected: profile.avoid.contains(interest),
                onSelected: (selected) => profiles.update((p) {
                  if (selected) {
                    p.avoid.add(interest);
                    p.interests.remove(interest);
                  } else {
                    p.avoid.remove(interest);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Temperature'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'c', label: Text('°C')),
            ButtonSegment(value: 'f', label: Text('°F')),
          ],
          selected: {profile.tempUnit},
          onSelectionChanged: (selection) =>
              profiles.update((p) => p.tempUnit = selection.first),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Nudges'),
        const SizedBox(height: 8),
        SegmentedButton<NudgeStyle>(
          segments: const [
            ButtonSegment(
              value: NudgeStyle.gentle,
              icon: Icon(Icons.volume_down_outlined),
              label: Text('Gentle'),
            ),
            ButtonSegment(
              value: NudgeStyle.bold,
              icon: Icon(Icons.volume_up_outlined),
              label: Text('Bold'),
            ),
          ],
          selected: {profile.nudgeStyle},
          onSelectionChanged: (selection) =>
              profiles.update((p) => p.nudgeStyle = selection.first),
        ),
        SwitchListTile(
          title: const Text('Sidequests skill'),
          subtitle: const Text('Let Muse watch for moments worth a nudge.'),
          value: profile.skillEnabled,
          onChanged: (value) async {
            await profiles.update((p) => p.skillEnabled = value);
            await NudgeScheduler.apply(value);
          },
        ),
        SwitchListTile(
          title: const Text('Audio cues'),
          subtitle: const Text('The voice reads nudges out loud.'),
          value: profile.audioCues,
          onChanged: (value) => profiles.update((p) => p.audioCues = value),
        ),
        SwitchListTile(
          title: const Text('Travel mode'),
          subtitle: const Text('Prefer local gems and first-time sights.'),
          value: profile.travelMode,
          onChanged: (value) => profiles.update((p) => p.travelMode = value),
        ),
        SwitchListTile(
          title: const Text('Suggest when traveling'),
          subtitle: const Text('Muse offers to switch modes when you are away.'),
          value: profile.suggestWhenTraveling,
          onChanged: (value) =>
              profiles.update((p) => p.suggestWhenTraveling = value),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                final result = await runNudgeCheck();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result)),
                );
              },
              child: const Text('Run nudge check now'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'How learning works'),
        const SizedBox(height: 8),
        _learnRow(context, Icons.favorite_border, 'Save what you love. Muse notices.'),
        _learnRow(context, Icons.close, "Dismiss what you don't. It adapts."),
        _learnRow(
          context,
          Icons.directions_walk,
          'Press "Let\'s go". It learns fastest.',
        ),
        const SizedBox(height: 20),
        SectionHeader(title: 'Saved', note: '${saved.length}'),
        const SizedBox(height: 8),
        if (saved.isEmpty)
          Text(
            'Nothing saved yet. Tap the heart on anything you like.',
            style: text.bodyMedium,
          )
        else
          ...saved.map(
            (quest) => Card(
              elevation: 0,
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                side: BorderSide(
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: ListTile(
                title: Text(quest.title),
                subtitle: Text(quest.category.label),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => profiles.toggleSave(quest),
                ),
                onTap: () => Navigator.of(context).push(
                  softRoute(
                    QuestDetailScreen(
                      scored: ScoredQuest(
                        quest: quest,
                        score: 0,
                        reason: quest.why,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => _confirmReset(context),
            child: const Text('Reset everything'),
          ),
        ),
      ],
    );
  }

  Widget _learnRow(BuildContext context, IconData icon, String label) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: text.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final profiles = context.read<ProfileProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text(
          'This clears your name, interests, saved quests, '
          'and everything Muse learned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await profiles.reset();
      _name.clear();
    }
  }
}
