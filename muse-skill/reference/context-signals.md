# Context signals

Everything the skill may use, where it comes from, and what it costs.

## Signal catalog

| Signal | Source (v1) | Freshness | Battery/privacy cost |
|---|---|---|---|
| Location (lat/lng) | Geolocator, `medium` accuracy, 8 s timeout | On refresh only | Low; runtime permission |
| Place label | Stub (`Nearby` / `Somewhere new` / `Your neighborhood`) | n/a | None (no reverse-geocode yet) |
| Temperature + WMO code | Open-Meteo `current=temperature_2m,weather_code`, keyless | On refresh, 8 s timeout | One HTTPS GET |
| Time of day / weekday | Device clock | Always | None |
| Travel heuristic | >80 km from home anchor via `distanceBetween` | On refresh | None (computed) |
| Home anchor | Not learned yet; manual toggle only | n/a | None |
| App events | view/save/go/unsave/dismiss with tag deltas | Immediate | None |
| Explicit profile | love/avoid lists, nudge style, toggles | Immediate | None |

## Not yet wired (roadmap)

Reverse-geocoding (BigDataCloud/Nominatim), sunset/sunrise API
(Open-Meteo `daily=sunrise,sunset`, same keyless call), events feeds
(Ticketmaster/Eventbrite), calendar access, learned home anchor,
significant-location-change background refresh.

## Polling guidance

- v1 refreshes on: app open, pull-to-refresh, Explore tab revisit (if the
  profile changed), and "Show everything again".
- No background polling in v1. Nudges fire from foreground refreshes and
  the manual "Nudge me" button. Background work (WorkManager + quiet hours)
  is the first post-hackathon milestone.
- Location is single-shot per refresh, never a stream. Keep it that way
  until background mode lands with a proper battery budget.

## WMO weather codes (Open-Meteo, abridged)

- `0–1`: clear → `isClear`
- `2–3`: partly cloudy / overcast (neutral)
- `45, 48`: fog (neutral; demote viewpoints in live skill)
- `51–82`: drizzle/rain/showers → `isRainy`
- `95–99`: thunderstorm → suppress outdoors (live skill)
