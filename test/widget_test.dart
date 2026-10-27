import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sidequests/screens/home_screen.dart';
import 'package:sidequests/services/context_service.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/preferences_service.dart';
import 'package:sidequests/state/profile_provider.dart';
import 'package:sidequests/state/quest_provider.dart';
import 'package:sidequests/theme/app_theme.dart';
import 'package:sidequests/widgets/quest_card.dart';
import 'package:sidequests/widgets/weather_card.dart';

void main() {
  testWidgets('home without location shows greeting and empty state', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final profiles = ProfileProvider(prefs: PreferencesService.memory());
    await profiles.load();
    final quests = QuestProvider(
      contextService: ContextService(),
      notifications: NotificationService.memory(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profiles),
          ChangeNotifierProvider.value(value: quests),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Live-only app: no location means no quests, no weather, no fakes.
    expect(find.byKey(const Key('greeting')), findsOneWidget);
    expect(find.text('Nothing live nearby.'), findsOneWidget);
    expect(find.byType(QuestCard), findsNothing);
    expect(find.byType(WeatherCard), findsNothing);
  });
}
