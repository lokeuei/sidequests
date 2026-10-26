# Quest JSON format (skill ↔ app contract)

The skill returns quests in this shape. The Flutter `Quest` model mirrors it
1:1 — keep them in sync.

## Schema

```jsonc
{
  "id": "string, stable, kebab-case",       // required, e.g. "q-sunset-bluff"
  "title": "string, <= 40 chars",            // required
  "blurb": "string, <= 140 chars",           // required, no emoji
  "category": "outdoors| culture|food|water|night|social|quiet", // required
  "minutes": "int, door-to-door minutes",    // required, 5..240
  "meters": "int, straight-line distance",   // required, >= 0
  "tags": ["interest vocabulary, 2..6"],     // required, see skill interests
  "why": "string, evergreen reason",         // required, <= 90 chars
  "bestWindow": "string, human hint",        // required, e.g. "5–7 PM"
  "latitude": "number|null",                 // optional, WGS84
  "longitude": "number|null"                 // optional, WGS84
}
```

Ranked response envelope:

```jsonc
{
  "quests": [
    { "<quest...>": null, "score": 99.6, "reason": "golden hour light · you love viewpoints" }
  ],
  "reasoning": "Away from home · Golden-hour light — a few ideas worth looking up for."
}
```

- `score`: number, for ordering only — never shown to the user.
- `reason`: top two positive contributors joined with ` · `, or `why`.
- `reasoning`: one line for the Explore header, same fragment style.

## Example

```json
{
  "id": "q-sunset-bluff",
  "title": "Sunset Bluff Viewpoint",
  "blurb": "A short climb above the rooftops with a west-facing bench.",
  "category": "outdoors",
  "minutes": 45,
  "meters": 1200,
  "tags": ["sunsets", "viewpoints", "outdoors", "evenings"],
  "why": "The sky does something different every evening.",
  "bestWindow": "5–7 PM",
  "latitude": null,
  "longitude": null
}
```

## Rules

- Tags MUST come from the skill interest vocabulary (plus `outdoors`,
  `night`, `evenings`, `mornings`, `bakery`, `bookshops`, `day trips`
  as modifier tags).
- No emoji anywhere. No purple-prose blurbs — one concrete image each.
- `meters` is straight-line; never present it as a routed distance.
