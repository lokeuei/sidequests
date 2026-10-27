import 'package:flutter_test/flutter_test.dart';
import 'package:sidequests/models/quest.dart';
import 'package:sidequests/models/user_profile.dart';

const _quest = Quest(
  id: 'q-1',
  title: 'Harbor Lookout',
  blurb: 'A view worth the walk.',
  category: QuestCategory.outdoors,
  minutes: 30,
  meters: 800,
  tags: ['viewpoints', 'outdoors'],
  why: 'The view does the work.',
  bestWindow: 'Sunset',
);

void main() {
  test('top learned tags come best first', () {
    final profile = UserProfile(
      learnedWeights: {'museums': 4, 'cafes': 7, 'quiet': 1, 'rain': -3},
    );
    expect(profile.topLearned(), ['cafes', 'museums', 'quiet']);
    expect(profile.topLearned(2), ['cafes', 'museums']);
  });

  test('top skipped tags come worst first', () {
    final profile = UserProfile(
      learnedWeights: {'museums': 4, 'night walks': -2, 'crowds': -5},
    );
    expect(profile.topSkipped(), ['crowds', 'night walks']);
  });

  test('feedback lands with stronger deltas than taps', () {
    final profile = UserProfile();
    profile.noteWent(_quest);
    expect(profile.weightFor('viewpoints'), 3);
    profile.noteLoved(_quest);
    expect(profile.weightFor('viewpoints'), 8);
    profile.noteNotForMe(_quest);
    expect(profile.weightFor('viewpoints'), 4);
  });
}
