# Sidequests skill for Muse

- **Name:** `sidequests`
- **Version:** 0.1.0 (stub contract; reasoning engine not yet live)
- **Kind:** ongoing skill — always eligible, fires on moments not queries
- **Client:** Sidequests Flutter app (Android now, iOS later)

## Purpose

Nudge the user toward small real-world adventures based on who they are,
where they are, and what the moment offers — so they put the phone down.
The skill never generates feed content; it only ever returns a short list
of quests (see `reference/quest-format.md`) plus one plain-language reason.

## Activation

Developers/users toggle the skill in-app (You → Sidequests skill), which sets
`config.enabled`. Default: **on**. When off, the app shows only the static
catalog with no ranking, no nudges, no learning.

`config.suggest_when_traveling` (default **on**): when the travel heuristic
fires (>80 km from the home anchor, see `reference/context-signals.md`) and
travel mode is off, the skill may send one "switch to travel mode?" nudge per
trip instead of a quest nudge.

## Inputs

Full catalog: `reference/context-signals.md`. In priority order:

1. **Learned profile** — interest weights from taps/saves/dismissals/goes.
   Explicit love/avoid lists override learned weights on conflict.
2. **Travel state** — traveling re-weights toward `local gems`, `history`,
   `viewpoints`, first-time sights.
3. **Daylight** — golden hour (17–19h) boosts `sunsets`/`viewpoints`/`water`;
   night boosts `night`/`stargazing`/`live music` and demotes plain `outdoors`.
4. **Weather** (Open-Meteo WMO) — rain boosts `museums`/`cafes`/`food markets`
   and demotes `outdoors`; clear skies do the reverse.
5. **Calendar-ish cues** — weekend boosts `social`/`food markets`/`live music`;
   morning boosts `mornings`/`cafes`/`quiet`.
6. **Distance** — gentle penalty (~2 points/km, capped at −10). Never exclude
   a perfect quest for distance; rank it lower and say why.

## Ranking contract (mirrors `rankQuests()` in the app)

- Start every candidate at 50 points.
- +12 per matching loved interest · −25 per matching avoided tag.
- Learned weight × 3 per tag, clamped to [−15, +21].
- Context boosts per Inputs above (golden hour +18, rain/indoor +16,
  night/made-for-tonight +14, travel +16, clear/outdoors +10, morning +10,
  clear/stargazing +8, weekend +6; demotions: rainy/outdoors −15,
  stargazing-by-day −12, outdoors-at-night −6).
- Sort descending, return top 5. Reason = top two positive contributors
  joined with ` · `, falling back to the quest's evergreen `why`.

The live skill may use richer signals (events feed, sunset API, calendar)
but MUST keep the same output shape and the "two contributors" reason style.

## Learning deltas (must match the app exactly)

| Event | Delta per tag |
|---|---|
| Quest viewed (detail opened) | +1 |
| Quest saved | +2 |
| "Let's go" pressed | +3 |
| Quest unsaved | −1 |
| Quest dismissed ("Not now") | −2 |

Weights never expire in v1. Explicit avoid always wins over positive weight
at rank time via the −25 penalty.

## Notification policy

- Channel: `sidequests_nudges` ("Adventure nudges").
- **Gentle** (default): high importance, title = quest title, body = `why`.
- **Bold**: max importance, title = `Go now: <title>`.
- Quiet hours 22:00–08:00 local: no auto-nudges except when traveling AND
  style is bold AND the quest is tagged `night`/`stargazing`/`live music`.
- Max 1 auto-nudge per 4 hours; manual "Nudge me" always allowed.
- Audio cues: v1 rides on the notification sound. Spoken cues (TTS) read
  "<title>. <why>" only when `config.audio_cues` is on.

## Safety (non-negotiable)

- No quests on private property, closed venues, or restricted areas.
- After dark, prefer well-lit, populated routes; say so in the reason.
- Severe weather (storms, heat advisories) suppresses outdoor quests.
- Distances assume walking; never route across highways or water without a
  marked crossing. The app shows straight-line distance — the skill must not
  imply a verified route.

## Example

> Context: 18:12, clear, user 120 km from home, loves viewpoints.
> Output: `Sunset Bluff Viewpoint` — "golden hour light · worth it while you
> are here". Travel-mode suggestion suppressed (already traveling-tuned).

## Versioning

Contract changes bump the version here AND in `pubspec.yaml`. Additive quest
fields are fine; removing/renaming fields is a breaking change.
