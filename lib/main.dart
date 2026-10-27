import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidequests/screens/splash_screen.dart';
import 'package:sidequests/services/context_service.dart';
import 'package:sidequests/services/notification_service.dart';
import 'package:sidequests/services/nudge_scheduler.dart';
import 'package:sidequests/services/preferences_service.dart';
import 'package:sidequests/state/profile_provider.dart';
import 'package:sidequests/state/quest_provider.dart';
import 'package:sidequests/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final profiles = ProfileProvider(prefs: PreferencesService.device());
  await profiles.load();

  final notifications = NotificationService.device();
  try {
    await notifications.init();
  } catch (_) {
    // Notifications are a bonus; the app works without them.
  }

  try {
    await NudgeScheduler.apply(profiles.profile.skillEnabled);
  } catch (_) {
    // Background checks are a bonus; the app works without them.
  }

  runApp(
    SidequestsApp(
      profiles: profiles,
      contextService: ContextService(useDeviceSensors: true),
      notifications: notifications,
    ),
  );
}

class SidequestsApp extends StatelessWidget {
  const SidequestsApp({
    super.key,
    required this.profiles,
    required this.contextService,
    required this.notifications,
  });

  final ProfileProvider profiles;
  final ContextService contextService;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profiles),
        ChangeNotifierProvider(
          create: (_) => QuestProvider(
            contextService: contextService,
            notifications: notifications,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Sidequests',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
