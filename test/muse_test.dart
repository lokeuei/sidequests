import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sidequests/models/user_profile.dart';
import 'package:sidequests/models/weather.dart';
import 'package:sidequests/services/muse_brain.dart';

import 'fixtures/sample_quests.dart';

String museReply({required List<Map<String, String>> picks, required String reasoning}) {
  return jsonEncode({
    'choices': [
      {
        'message': {
          'content': jsonEncode({'picks': picks, 'reasoning': reasoning}),
        },
      },
    ],
  });
}

void main() {
  test('prompt carries date, weather, prefs, and candidates', () {
    final profile = UserProfile(
      displayName: 'June',
      interests: {'museums'},
      avoid: {'night walks'},
    );
    final prompt = buildPrompt(
      profile: profile,
      now: DateTime(2026, 10, 27, 18, 30),
      traveling: false,
      weather: const WeatherInfo(
        temperatureC: 12,
        code: 61,
        highC: 14,
        lowC: 8,
        hourly: [],
        daily: [],
      ),
      candidates: questCatalog.take(3).toList(),
    );
    expect(prompt, contains('June'));
    expect(prompt, contains('October 27, 2026'));
    expect(prompt, contains('Rain'));
    expect(prompt, contains('museums'));
    expect(prompt, contains('night walks'));
    expect(prompt, contains('Sunset Bluff Viewpoint'));
  });

  test('parser maps picks, drops unknown ids', () {
    final reply = museReply(
      picks: [
        {'id': 'q-small-museum', 'reason': 'Rain is coming, go inside.'},
        {'id': 'q-nope', 'reason': 'Made up.'},
      ],
      reasoning: 'Rain outside, you love museums',
    );
    final suggestion = parseMuseResponse(reply, questCatalog);
    expect(suggestion, isNotNull);
    expect(suggestion!.picks.length, 1);
    expect(suggestion.picks.first.quest.id, 'q-small-museum');
    expect(suggestion.picks.first.reason, 'Rain is coming, go inside.');
    expect(suggestion.reasoning, 'Rain outside, you love museums');
  });

  test('parser rejects garbage', () {
    expect(parseMuseResponse('nope', questCatalog), isNull);
    expect(parseMuseResponse('{"choices": []}', questCatalog), isNull);
    expect(
      parseMuseResponse(
        museReply(picks: [], reasoning: ''),
        questCatalog,
      ),
      isNull,
    );
  });

  test('no key means no call and no network', () async {
    final brain = MuseBrain();
    expect(
      await brain.suggest(
        profile: UserProfile(),
        now: DateTime(2026, 10, 27, 18),
        traveling: false,
        weather: null,
        candidates: questCatalog.take(3).toList(),
      ),
      isNull,
    );
  });

  test('stored key is sent and the reply is ranked', () async {
    String? seenAuth;
    final client = MockClient((request) async {
      seenAuth = request.headers['Authorization'];
      return http.Response(
        museReply(
          picks: [
            {'id': 'q-small-museum', 'reason': 'Rain is coming, go inside.'},
          ],
          reasoning: 'Rain outside',
        ),
        200,
      );
    });
    final suggestion = await MuseBrain().suggest(
      profile: UserProfile(),
      now: DateTime(2026, 10, 27, 18),
      traveling: false,
      weather: null,
      candidates: questCatalog,
      apiKey: 'runtime-key',
      client: client,
    );
    expect(seenAuth, 'Bearer runtime-key');
    expect(suggestion, isNotNull);
    expect(suggestion!.picks.first.quest.id, 'q-small-museum');
  });

  test('api keys survive a profile round trip', () {
    final profile = UserProfile(museApiKey: 'm1', ticketmasterKey: 't1');
    final back = UserProfile.fromJson(profile.toJson());
    expect(back.museApiKey, 'm1');
    expect(back.ticketmasterKey, 't1');
  });
}
