import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/screens/preferences_screen.dart';
import 'package:sidequests/screens/quest_detail_screen.dart';
import 'package:sidequests/services/geocode_service.dart';
import 'package:sidequests/services/map_pins.dart';
import 'package:sidequests/services/suggestion_engine.dart';
import 'package:sidequests/state/profile_provider.dart';
import 'package:sidequests/state/quest_provider.dart';
import 'package:sidequests/widgets/app_logo.dart';
import 'package:sidequests/widgets/context_row.dart';
import 'package:sidequests/widgets/enter_animation.dart';
import 'package:sidequests/widgets/muse_avatar.dart';
import 'package:sidequests/widgets/quest_art.dart';
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
  int _cardIndex = 0;
  bool _searching = false;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
    if (mounted) setState(() => _cardIndex = 0);
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

  Future<void> _applySearch(double lat, double lon, String label) async {
    FocusScope.of(context).unfocus();
    context.read<QuestProvider>().setSearchPoint(lat, lon, label);
    await _refresh(autoNudge: false);
  }

  Future<void> _clearSearch() async {
    _search.clear();
    context.read<QuestProvider>().clearSearchPoint();
    await _refresh(autoNudge: false);
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty || _searching) return;
    setState(() => _searching = true);
    final hits = await GeocodeService().search(query);
    if (!mounted) return;
    setState(() => _searching = false);
    if (hits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No match for that place.')),
      );
      return;
    }
    if (hits.length == 1) {
      final hit = hits.first;
      await _applySearch(hit.latitude, hit.longitude, hit.label);
      return;
    }
    final picked = await showDialog<GeocodeHit>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Which place?'),
        children: [
          for (final hit in hits)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(hit),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(hit.detail),
              ),
            ),
        ],
      ),
    );
    if (picked != null && mounted) {
      await _applySearch(picked.latitude, picked.longitude, picked.label);
    }
  }

  Future<void> _speakBrief() async {
    final quests = context.read<QuestProvider>();
    final message = await quests.brief();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 12),
        action: SnackBarAction(
          label: 'Stop',
          onPressed: () => quests.stopSpeaking(),
        ),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final profiles = sheetContext.watch<ProfileProvider>();
        final profile = profiles.profile;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show me more of',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final interest in kAllInterests)
                      FilterChip(
                        label: Text(interest),
                        selected: profile.interests.contains(interest),
                        onSelected: profile.avoid.contains(interest)
                            ? null
                            : (selected) => profiles.update((p) {
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Travel mode'),
                  subtitle:
                      const Text('Prefer local gems and first-time sights.'),
                  value: profile.travelMode,
                  onChanged: (value) =>
                      profiles.update((p) => p.travelMode = value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openWeather() {
    final quests = context.read<QuestProvider>();
    final profiles = context.read<ProfileProvider>();
    final weather = quests.device.weather;
    if (weather == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No weather yet.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: WeatherCard(
            weather: weather,
            tempUnit: profiles.profile.tempUnit,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quests = context.watch<QuestProvider>();
    final showStatus =
        _tab != 0 && quests.loading && quests.loadStatus.isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: _tab == 0,
      appBar: _tab == 0
          ? null
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 30),
                  const SizedBox(width: 10),
                  Text(
                    _tab == 1 ? 'For you' : 'Mint',
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
                    final questState = context.read<QuestProvider>();
                    await questState.sendNudge(profiles.profile);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Nudge sent. Check your notifications.'),
                      ),
                    );
                  },
                ),
              ],
              bottom: showStatus
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              quests.loadStatus,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const LinearProgressIndicator(),
                        ],
                      ),
                    )
                  : null,
            ),
      body: switch (_tab) {
        0 => _buildNearby(context),
        1 => _buildForYou(context),
        2 => _buildMuse(context),
        _ => const PreferencesScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() => _tab = index);
          if ((index == 0 || index == 1) &&
              context.read<ProfileProvider>().revision != _seenRevision) {
            _refresh(autoNudge: false);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'For You',
          ),
          NavigationDestination(
            icon: MuseAvatar(size: 26),
            selectedIcon: MuseAvatar(size: 26),
            label: 'Mint',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildNearby(BuildContext context) {
    final quests = context.watch<QuestProvider>();
    final profiles = context.watch<ProfileProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final name = profiles.profile.displayName.trim();
    final weather = quests.device.weather;
    final deviceLat = quests.device.latitude;
    final deviceLng = quests.device.longitude;
    final lat = quests.searchLat ?? deviceLat;
    final lng = quests.searchLon ?? deviceLng;
    final away = quests.searchingElsewhere;
    final hasMap = lat != null && lng != null;

    final tempUnit = profiles.profile.tempUnit;
    final weatherLine = weather == null
        ? 'No weather yet'
        : '${tempLabel(weather.temperatureC, tempUnit)} · ${weatherLabel(weather.code)}'
            '${quests.device.traveling || profiles.profile.travelMode ? ' · Away' : ''}';

    return Stack(
      children: [
        if (hasMap)
          Positioned.fill(
            child: QuestMap(
              key: ValueKey('map-$lat-$lng'),
              center: LatLng(lat, lng),
              pins: pinsForQuests(
                lat,
                lng,
                quests.quests.map((q) => q.quest).toList(),
              ),
              userPoint: deviceLat != null && deviceLng != null
                  ? LatLng(deviceLat, deviceLng)
                  : null,
              searchPoint: away ? LatLng(lat, lng) : null,
              onPinTap: _openPin,
              onMapTap: (point) => _applySearch(
                point.latitude,
                point.longitude,
                'dropped pin',
              ),
              zoom: 14,
              fill: true,
            ),
          )
        else
          Positioned.fill(
            child: Container(color: scheme.surface),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openWeather,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _skyIcon(
                                  weather?.code ?? 0,
                                  now.hour,
                                ),
                                color: scheme.tertiary,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      key: const Key('greeting'),
                                      '${_greeting(now.hour)}${name.isEmpty ? '' : ', $name'}',
                                      style: text.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      weatherLine,
                                      style: text.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _tab = 3),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: name.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: scheme.onPrimary,
                                )
                              : Text(
                                  name[0].toUpperCase(),
                                  style: text.titleLarge?.copyWith(
                                    color: scheme.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Enter location, or tap the map…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: _searchPlace,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _openFilters,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tune,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (away) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      label: Text('Near ${quests.searchLabel}'),
                      onDeleted: _clearSearch,
                    ),
                  ),
                ],
                if (quests.loading && quests.loadStatus.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            quests.loadStatus,
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: quests.quests.isEmpty
              ? _nearbyEmpty(context)
              : SizedBox(
                  height: 292,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: quests.quests.length,
                        onPageChanged: (i) =>
                            setState(() => _cardIndex = i),
                        itemBuilder: (pageContext, i) =>
                            _featureCard(context, quests.quests[i]),
                      ),
                      if (quests.quests.length > 1)
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              '${_cardIndex + 1} of ${quests.quests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _featureCard(BuildContext context, ScoredQuest scored) {
    final quest = scored.quest;
    final profiles = context.watch<ProfileProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final saved = profiles.profile.isSaved(quest.id);
    return GestureDetector(
      onTap: () => _openDetail(scored),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.all(Radius.circular(16)),
                    child: SizedBox(
                      width: 108,
                      child: QuestArt(
                        category: quest.category,
                        height: 150,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                quest.title,
                                style: text.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => profiles.toggleSave(quest),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  saved
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: saved
                                      ? scheme.secondary
                                      : scheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_walk,
                              size: 14,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${quest.durationLabel} · ${quest.distanceLabel}',
                                style: text.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quest.blurb,
                          style: text.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in quest.tags.take(3))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.secondary
                                      .withValues(alpha: 0.14),
                                  borderRadius:
                                      const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: text.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await profiles
                      .update((p) => p.noteEngagement(quest.tags, 3));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Have fun out there.'),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Let's go"),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_upward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nearbyEmpty(BuildContext context) {
    final quests = context.read<QuestProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final failed = quests.placesFailed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            failed ? 'The map lookup failed.' : 'Nothing live nearby.',
            style: text.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            failed
                ? 'The map servers did not answer. Check your internet and try again.'
                : 'Search another spot above, or tap Try again.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
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

  Widget _buildForYou(BuildContext context) {
    final quests = context.watch<QuestProvider>();
    final profiles = context.watch<ProfileProvider>();
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final weather = quests.device.weather;

    return RefreshIndicator(
      onRefresh: () => _refresh(autoNudge: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (quests.reasoning.isNotEmpty)
            Text(
              quests.reasoning,
              style: GoogleFonts.fraunces(
                textStyle: text.bodyLarge,
                fontStyle: FontStyle.italic,
              ),
            ).enter(context),
          const SizedBox(height: 14),
          ContextRow(
            device: quests.device,
            hour: now.hour,
            tempUnit: profiles.profile.tempUnit,
          ).enter(context, delayMs: 60),
          if (quests.device.traveling || profiles.profile.travelMode) ...[
            const SizedBox(height: 12),
            _travelBanner(context),
          ],
          if (weather != null) ...[
            const SizedBox(height: 14),
            WeatherCard(
              weather: weather,
              tempUnit: profiles.profile.tempUnit,
            ).enter(context, delayMs: 80),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Right now',
            note:
                '${quests.quests.length} ideas${quests.livePlaces ? ' · live' : ''}${quests.liveGigs ? ' · gigs' : ''}${quests.museUsed ? ' · mint' : ''}',
          ).enter(context, delayMs: 100),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed:
                    quests.quests.isEmpty ? null : _speakBrief,
                icon: const Icon(Icons.campaign),
                label: const Text('Brief me'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed:
                    quests.quests.isEmpty ? null : () => quests.shuffle(),
                icon: const Icon(Icons.shuffle),
                label: const Text('Surprise me'),
              ),
            ],
          ).enter(context, delayMs: 140),
        ],
      ),
    );
  }

  Widget _buildMuse(BuildContext context) {
    final quests = context.watch<QuestProvider>();
    final profiles = context.watch<ProfileProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final profile = profiles.profile;
    const envKey = String.fromEnvironment('MUSE_API_KEY');
    final keySet =
        profile.museApiKey.trim().isNotEmpty || envKey.isNotEmpty;
    final loved = profile.topLearned();
    final skipped = profile.topSkipped();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            const MuseAvatar(size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mint', style: text.displayMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Mint here. Your taste, in one place.',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ).enter(context),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius:
                const BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keySet ? 'Ranking with Mint' : 'Ranking on-device',
                      style: text.titleMedium,
                    ),
                    Text(
                      keySet
                          ? 'Live picks from Spark.'
                          : 'Add a key to switch on live picks.',
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _tab = 3),
                child: Text(keySet ? 'Keys' : 'Add key'),
              ),
            ],
          ),
        ).enter(context, delayMs: 100),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Briefing'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius:
                const BorderRadius.all(Radius.circular(20)),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Hear your top three, out loud.',
                  style: text.bodyMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    quests.quests.isEmpty ? null : _speakBrief,
                icon: const Icon(Icons.campaign),
                label: const Text('Brief me'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'What Mint knows',
          note: 'updates as you tap',
        ),
        const SizedBox(height: 8),
        if (loved.isEmpty && skipped.isEmpty)
          Text(
            'Nothing noticed yet. Open, save, or dismiss ideas and check back.',
            style: text.bodyMedium,
          )
        else ...[
          if (loved.isNotEmpty)
            _knowRow(
              context,
              Icons.favorite_border,
              'Loves ${loved.join(', ')}.',
            ),
          if (skipped.isNotEmpty)
            _knowRow(
              context,
              Icons.close,
              'Skips ${skipped.join(', ')}.',
            ),
        ],
        if (quests.reasoning.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader(title: 'Last refresh'),
          const SizedBox(height: 8),
          Text(
            quests.reasoning,
            style: GoogleFonts.fraunces(
              textStyle: text.bodyLarge,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _knowRow(BuildContext context, IconData icon, String label) {
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
    final failed = quests.placesFailed;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            failed ? 'The map lookup failed.' : 'Nothing live nearby.',
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            failed
                ? 'The map servers did not answer. Check your internet and try again.'
                : 'Sidequests needs location and internet for live ideas. '
                    'Pull to refresh, or look around the Nearby tab.',
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

  IconData _skyIcon(int code, int hour) {
    if (hour >= 20 || hour < 6) return Icons.nights_stay;
    if (code >= 95) return Icons.thunderstorm;
    if (code >= 71 && code <= 77 || code == 85 || code == 86) {
      return Icons.ac_unit;
    }
    if (code >= 51 && code <= 82) return Icons.umbrella;
    if (code == 45 || code == 48) return Icons.foggy;
    return Icons.wb_sunny;
  }

  String _greeting(int hour) {
    if (hour < 5) return 'Up late';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
