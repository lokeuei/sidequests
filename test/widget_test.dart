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
  testWidgets('home shows greeting and quest cards', (tester) async {
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

    expect(find.byKey(const Key('greeting')), findsOneWidget);
    expect(find.byType(WeatherCard), findsOneWidget);
    // Cards sit below the weather block, so scroll the outer list
    // until the lazy ListView builds them.
    await tester.scrollUntilVisible(
      find.byType(QuestCard),
      400,
      scrollable: find.byType(ListView).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(QuestCard), findsWidgets);
  });
}
