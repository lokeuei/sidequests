# Sidequests: less scrolling, more living

We spend too much time staring at our phones, missing the interesting things
happening right around us. Sidequests flips that: it learns what you love,
watches your location, the weather, and the time of day, then nudges you
toward little adventures worth putting the phone down for. A sunset viewpoint.
A historic facade you have walked past a hundred times. A night market you
never knew existed.

AI that reconnects you with the real world instead of pulling you away from it.

## What v1 does (Pixel 9 / Android)

- **Explore tab**: a short, ranked list of live quests "right now", with a
  plain-language reason for each ("golden hour light, made for tonight").
- **Automatic context**: device location (with permission), keyless weather
  from Open-Meteo, time of day, and travel detection. No weather API key needed.
- **Nudges**: local notifications for the top quest; a louder style when
  "Bold" is on. Turn on Audio cues and the system voice reads them aloud.
- **You tab**: name, interests ("love" / "less of"), temperature unit, nudge
  style, travel mode, saved quests, and a reset. By default Muse learns from
  taps, saves, dismissals, and "Let's go" presses. Explicit settings improve
  its picks.
- **Travel mode**: when you're >80 km from home (or toggle it manually),
  rankings lean into local gems. Muse can suggest turning it on.
- **Muse skill spec**: `muse-skill/` defines the ongoing-skill contract the
  ranker implements, so live Muse reasoning can slot in later.
- **Painted cover art**: every quest gets in-code cover art, no downloads.
- **Maps + weather**: OpenStreetMap pins around you (no API key) and a classic
  weather block with hourly and daily rows. Pins open quest details on tap.
- **Live data only**: real nearby spots from OpenStreetMap, gigs from
  Ticketmaster with a free key, no samples anywhere.
- **Background nudges**: a periodic check sends a golden-hour nudge even with
  the app closed. Quiet hours are 10 PM to 8 AM.
- **Events (needs key)**: Ticketmaster gigs near you when you pass a free API
  key. See the setup guide.

## Quickstart

Full steps for a Pixel 9: [docs/SETUP_PIXEL9.md](docs/SETUP_PIXEL9.md).

```sh
git clone https://github.com/lokeuei/sidequests.git
cd sidequests
flutter create --platforms=android,ios .   # completes native shells (icons, wrapper)
flutter pub get
flutter run                                # pick your Pixel 9
```

Checks:

```sh
flutter analyze
flutter test
```

## How it fits together

```text
lib/
  main.dart                 App boot: prefs → notifications → scheduler → splash
  theme/app_theme.dart      "Golden-hour explorer" Material 3 theme (Fraunces + Outfit)
  models/                   Quest, UserProfile, WeatherInfo (JSON-persisted)
  services/
    suggestion_engine.dart  Pure-Dart ranker behind the muse-skill contract
    places_service.dart     Live OpenStreetMap POIs via Overpass (keyless)
    events_service.dart     Ticketmaster gigs (needs free API key)
    context_service.dart    Geolocator + Open-Meteo + place names, honest stubs
    notification_service.dart  Local nudges plus system-voice spoken cues
    nudge_scheduler.dart    Periodic background golden-hour check (Android)
    nudge_policy.dart       Quiet hours + golden-hour window (pure, tested)
    preferences_service.dart   SharedPreferences, in-memory variant for tests
  state/                    ProfileProvider (revision-tracked), QuestProvider
  widgets/                  Art, cards, maps, weather, logo, reduced-motion entrances
  screens/                  Splash, Explore+You home, quest detail, preferences
muse-skill/                 Ongoing-skill contract for Muse (triggers, signals,
                            quest JSON, learning deltas, safety)
test/                       Unit + widget tests with sample fixtures
```

The UI never talks to Muse directly. It talks to `rankQuests()`. When the
live skill lands, only `suggestion_engine.dart` (and its tests) change.

## Design notes

- Warm paper + deep pine + persimmon; Fraunces display serif with Outfit body.
- Cards enter with a staggered rise-and-fade; detail opens with a soft
  fade-and-settle. All motion yields to the OS reduced-motion setting.
- Radii, shapes, and headers vary on purpose. No template-grid look.

## Roadmap

- Live Muse reasoning behind `rankQuests()` (see `muse-skill/SKILL.md`)
- iOS shell polish + TestFlight (`flutter create` already scaffolds it)
- Release build with signing, store listing, screenshots
- Opening hours + sunset countdown per quest
- Home anchor that learns where "home" is

## License

MIT, see [LICENSE](LICENSE).
