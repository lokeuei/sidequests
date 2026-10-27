// ignore_for_file: avoid_print
// One-line outcomes print to the dev console so Muse failures
// (bad status, parse miss) can be diagnosed from `flutter run` output.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/suggestion_engine.dart';

/// Asks Muse to rank live candidates. Takes the key in (stored in the
/// profile), or bake one in with --dart-define=MUSE_API_KEY=.... Returns
/// null without a key or on any failure, and the app falls back to the
/// local ranker.
class MuseBrain {
  Future<MuseSuggestion?> suggest({
    required UserProfile profile,
    required DateTime now,
    required bool traveling,
    required WeatherInfo? weather,
    required List<Quest> candidates,
    String? apiKey,
    http.Client? client,
  }) async {
    const envKey = String.fromEnvironment('MUSE_API_KEY');
    const model = String.fromEnvironment('MUSE_MODEL', defaultValue: 'muse-spark-1.1');
    final key = envKey.isNotEmpty
        ? envKey
        : (apiKey != null && apiKey.trim().isNotEmpty ? apiKey.trim() : '');
    if (key.isEmpty || candidates.isEmpty) return null;
    final httpClient = client ?? http.Client();
    final stopwatch = Stopwatch()..start();
    try {
      final response = await httpClient
          .post(
            Uri.parse('https://api.meta.ai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'user',
                  'content': buildPrompt(
                    profile: profile,
                    now: now,
                    traveling: traveling,
                    weather: weather,
                    candidates: candidates.take(12).toList(),
                  ),
                },
              ],
              'temperature': 0.7,
              'max_tokens': 800,
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        print('muse: api said ${response.statusCode} (model $model)');
        return null;
      }
      final suggestion = parseMuseResponse(response.body, candidates);
      if (suggestion == null) {
        final snippet = response.body.length > 600
            ? response.body.substring(0, 600)
            : response.body;
        print('muse: reply did not parse: $snippet');
        return null;
      }
      print('muse: ranked ${suggestion.picks.length} in ${stopwatch.elapsedMilliseconds}ms');
      return suggestion;
    } catch (e) {
      print('muse: call failed ($e)');
      return null;
    } finally {
      if (client == null) httpClient.close();
    }
  }
}

class MuseSuggestion {
  const MuseSuggestion({required this.picks, required this.reasoning});

  final List<ScoredQuest> picks;
  final String reasoning;
}

/// The exact context Muse sees: date, time, weather, prefs, candidates.
String buildPrompt({
  required UserProfile profile,
  required DateTime now,
  required bool traveling,
  required WeatherInfo? weather,
  required List<Quest> candidates,
}) {
  const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final stamp =
      '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}, '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  final weatherLine = weather == null
      ? 'Unknown.'
      : '${weatherLabel(weather.code)}, ${weather.temperatureC.round()}C, '
        'high ${weather.highC.round()}C, low ${weather.lowC.round()}C.'
        '${weather.sunset.isNotEmpty ? ' Sunset ${timeLabel(weather.sunset)}.' : ''}';

  final learned = profile.learnedWeights.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final loved = learned.where((e) => e.value > 0).take(5).map((e) => e.key).join(', ');
  final lines = candidates.map((q) {
    final bits = [
      q.id, q.title, q.category.label, q.tags.join('/'),
      q.distanceLabel, q.durationLabel, q.bestWindow,
    ];
    if (q.startsAt.isNotEmpty) bits.add('starts ${q.startsAt}');
    return bits.join(' | ');
  }).join('\n');

  return '''
You pick real-world outings for one person. Reply with JSON only, no other text.

Person: ${profile.displayName.isEmpty ? 'unnamed' : profile.displayName}
Loves: ${profile.interests.join(', ')}
Avoids: ${profile.avoid.join(', ')}
Learned likes: ${loved.isEmpty ? 'none yet' : loved}
Now: $stamp. Traveling: ${traveling ? 'yes' : 'no'}
Weather: $weatherLine

Candidates (id | title | kind | tags | distance | duration | best window | starts):
$lines

Rules: pick up to 5, best first. Skip anything that clashes with Avoids.
Each reason is one short sentence in plain words. No em dashes.
reasoning is one line starting with the strongest factor.
{"picks": [{"id": "...", "reason": "..."}], "reasoning": "..."}''';
}

/// Turns the model reply into ranked quests. Null when unusable.
MuseSuggestion? parseMuseResponse(String body, List<Quest> candidates) {
  try {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List?;
    final message = (choices != null && choices.isNotEmpty)
        ? choices.first as Map<String, dynamic>?
        : null;
    var content = ((message?['message'] as Map<String, dynamic>?)?['content'] ?? '').toString();
    content = content.trim();
    if (content.startsWith('```')) {
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    }
    if (content.isEmpty) return null;
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final picks = (parsed['picks'] as List?) ?? [];

    final byId = {for (final q in candidates) q.id: q};
    final seen = <String>{};
    final scored = <ScoredQuest>[];
    for (final pick in picks) {
      if (scored.length >= 5) break;
      final map = pick as Map<String, dynamic>?;
      final id = (map?['id'] ?? '').toString();
      final quest = byId[id];
      if (quest == null || !seen.add(id)) continue;
      final reason = (map?['reason'] ?? '').toString().trim();
      scored.add(ScoredQuest(
        quest: quest,
        score: 90 - scored.length * 5,
        reason: reason.isEmpty ? quest.why : reason,
      ));
    }
    if (scored.isEmpty) return null;
    return MuseSuggestion(
      picks: scored,
      reasoning: (parsed['reasoning'] ?? '').toString().trim(),
    );
  } catch (_) {
    return null;
  }
}
