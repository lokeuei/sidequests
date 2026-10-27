import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sidequests/screens/preferences_screen.dart';
import 'package:sidequests/screens/quest_detail_screen.dart';
import 'package:sidequests/services/map_pins.dart';
import 'package:sidequests/services/suggestion_engine.dart';
import 'package:sidequests/state/profile_provider.dart';
import 'package:sidequests/state/quest_provider.dart';
import 'package:sidequests/widgets/app_logo.dart';
import 'package:sidequests/widgets/context_row.dart';
import 'package:sidequests/widgets/enter_animation.dart';
import 'package:sidequests/widgets/quest_card.dart';
import 'package:sidequests/widgets/quest_map.dart';
import 'package:sidequests/widgets/section_header.dart';
import 'package:sidequests/widgets/weather_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _seenRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh({bool autoNudge = true}) async {
    final profiles = context.read<ProfileProvider>();
    final quests = context.read<QuestProvider>();
    await quests.refresh(profiles.profile, autoNudge: autoNudge);
    final sunset = quests.device.weather?.sunset ?? '';
    if (sunset.isNotEmpty) {
      await profiles.noteSunset(sunset);
    }
    _seenRevision = profiles.revision;
  }

  Future<void> _openDetail(ScoredQuest quest) async {
    final profiles = context.read<ProfileProvider>();
    final quests = context.read<QuestProvider>();
    await profiles.update((p) => p.noteEngagement(quest.quest.tags, 1));
    if (!mounted) return;
    final result = await Navigator.of(context).push(
      softRoute(QuestDetailScreen(scored: quest)),
    );
    if (!mounted) return;
    // Detail pops the quest back only when it was dismissed there.
    if (result is ScoredQuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dismissed "${result.quest.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => quests.undoDismiss(result),
          ),
        ),
      );
    }
  }

  void _openPin(MapPin pin) {
    final quests = context.read<QuestProvider>();
    for (final scored in quests.quests) {
      if (scored.quest.id == pin.questId) {
        _openDetail(scored);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 30),
            const SizedBox(width: 10),
            Text(
              'sidequests',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Send a nudge',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () async {
              final profiles = context.read<ProfileProvider>();
              final quests = context.read<QuestProvider>();
              await quests.sendNudge(profiles.profile);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nudge sent. Check your notifications.'),
                ),
              );
            },
          ),
        ],
      ),
      body: _tab == 0 ? _buildExplore(context) : const PreferencesScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() => _tab = index);
          if (index == 0 &&
              context.read<ProfileProvider>().revision != _seenRevision) {
            _refresh(autoNudge: false);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }

  Widget _buildExplore(BuildContext context) {
    final quests = context.watch<QuestProvider>();
    final profiles = context.watch<ProfileProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final name = profiles.profile.displayName.trim();
    final weather = quests.device.weather;
    final lat = quests.device.latitude;
    final lng = quests.device.longitude;

    if (quests.loading && quests.quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Reading the sky…', style: text.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(autoNudge: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            _dateLine(now),
            style: text.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ).enter(context),
          const SizedBox(height: 4),
          Text(
            key: const Key('greeting'),
            '${_greeting(now.hour)}${name.isEmpty ? '' : ', $name'}',
            style: text.displayMedium,
          ).enter(context, delayMs: 60),
          const SizedBox(height: 10),
          if (quests.reasoning.isNotEmpty)
            Text(
              quests.reasoning,
              style: GoogleFonts.fraunces(
                textStyle: text.bodyLarge,
                fontStyle: FontStyle.italic,
              ),
            ).enter(context, delayMs: 120),
          const SizedBox(height: 14),
          ContextRow(
            device: quests.device,
            hour: now.hour,
            tempUnit: profiles.profile.tempUnit,
          ).enter(context, delayMs: 160),
          if (quests.device.traveling || profiles.profile.travelMode) ...[
            const SizedBox(height: 12),
            _travelBanner(context),
          ],
          if (weather != null) ...[
            const SizedBox(height: 14),
            WeatherCard(
              weather: weather,
              tempUnit: profiles.profile.tempUnit,
            ).enter(context, delayMs: 180),
          ],
          if (lat != null && lng != null) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Around you')
                .enter(context, delayMs: 200),
            const SizedBox(height: 12),
            QuestMap(
              center: LatLng(lat, lng),
              pins: pinsForQuests(
                lat,
                lng,
                quests.quests.map((q) => q.quest).toList(),
              ),
              onPinTap: _openPin,
              height: 190,
            ).enter(context, delayMs: 220),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Right now',
            note:
                '${quests.quests.length} ideas${quests.livePlaces ? ' · live' : ''}${quests.museUsed ? ' · muse' : ''}',
          ).enter(context, delayMs: 240),
          const SizedBox(height: 12),
          if (quests.quests.isEmpty)
            _emptyState(context)
          else
            ...quests.quests.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QuestCard(
                  scored: q,
                  index: i,
                  saved: profiles.profile.isSaved(q.quest.id),
                  onTap: () => _openDetail(q),
                  onSave: () => profiles.toggleSave(q.quest),
                ),
              );
            }),
          const SizedBox(height: 8),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: quests.quests.isEmpty ? null : () => quests.shuffle(),
              icon: const Icon(Icons.shuffle),
              label: const Text('Surprise me'),
            ),
          ).enter(context, delayMs: 320),
        ],
      ),
    );
  }

  Widget _travelBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Travel mode is on. Showing local gems first.',
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    ).enter(context, delayMs: 180);
  }

  Widget _emptyState(BuildContext context) {
    final quests = context.read<QuestProvider>();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text('Nothing live nearby.', style: text.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Sidequests needs location and internet for live ideas. '
            'Pull to refresh to try again.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              quests.clearDismissed();
              _refresh(autoNudge: false);
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 5) return 'Up late';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateLine(DateTime now) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
