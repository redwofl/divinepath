import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/mantra_provider.dart';
import 'providers/stories_provider.dart';
import 'providers/gita_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/tap_sound_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'services/firebase_service.dart';
import 'services/gemini_service.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'utils/helpers.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Helpers.setNavigatorKey(Helpers.navigatorKey);

  // Load saved haptics preference before the UI builds
  await Helpers.loadHapticsSetting();

  // Try to initialize Firebase (handles missing config gracefully)
  try {
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase not available: $e');
    FirebaseService.instance.markAsUnavailable();
  }

  // Initialize Gemini AI with API key from config
  try {
    if (AppConfig.geminiApiKey.isNotEmpty) {
      await GeminiService.instance.initialize(AppConfig.geminiApiKey);
    }
  } catch (e) {
    debugPrint('Gemini AI not available: $e');
  }

  // Initialize services with graceful fallback
  try {
    await AudioService.instance.initialize();
  } catch (e) {
    debugPrint('Audio service not available: $e');
  }

  try {
    await NotificationService.instance.initialize();
    // Ask for notification permission at startup (Android 13+)
    await NotificationService.instance.requestPermissions();
    // Make sure daily reminders are scheduled if notifications are enabled
    if (await NotificationService.instance.isNotificationsEnabled()) {
      await NotificationService.instance.scheduleMorningReminder();
      await NotificationService.instance.scheduleEveningReminder();
    }
  } catch (e) {
    debugPrint('Notifications not available: $e');
  }

  // Initialize AdMob (rewarded ads for the mala bonus; no-ops off mobile)
  try {
    await AdmobService.instance.initialize();
  } catch (e) {
    debugPrint('AdMob not available: $e');
  }

  // Initialize providers
  final userProvider = UserProvider();
  await userProvider.initialize();

  final localeProvider = LocaleProvider();
  try {
    await localeProvider.initialize();
  } catch (e) {
    debugPrint('Locale provider error: $e');
  }

  final themeProvider = ThemeProvider();
  try {
    await themeProvider.initialize();
  } catch (e) {
    debugPrint('Theme provider error: $e');
  }

  final mantraProvider = MantraProvider();
  try {
    await mantraProvider.initialize();
  } catch (e) {
    debugPrint('Mantra provider error: $e');
  }

  final storiesProvider = StoriesProvider();
  try {
    await storiesProvider.initialize();
  } catch (e) {
    debugPrint('Stories provider error: $e');
  }

  final gitaProvider = GitaProvider();
  try {
    await gitaProvider.initialize();
  } catch (e) {
    debugPrint('Gita provider error: $e');
  }

  final chatProvider = ChatProvider(localeProvider: localeProvider);
  try {
    await chatProvider.initialize();
  } catch (e) {
    debugPrint('Chat provider error: $e');
  }

  final tapSoundProvider = TapSoundProvider();
  try {
    await tapSoundProvider.initialize();
  } catch (e) {
    debugPrint('TapSound provider error: $e');
  }

  runApp(DivinePathApp(
    userProvider: userProvider,
    localeProvider: localeProvider,
    themeProvider: themeProvider,
    mantraProvider: mantraProvider,
    storiesProvider: storiesProvider,
    gitaProvider: gitaProvider,
    chatProvider: chatProvider,
    tapSoundProvider: tapSoundProvider,
  ));
}

class DivinePathApp extends StatelessWidget {
  final UserProvider userProvider;
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;
  final MantraProvider mantraProvider;
  final StoriesProvider storiesProvider;
  final GitaProvider gitaProvider;
  final ChatProvider chatProvider;
  final TapSoundProvider tapSoundProvider;

  const DivinePathApp({
    super.key,
    required this.userProvider,
    required this.localeProvider,
    required this.themeProvider,
    required this.mantraProvider,
    required this.storiesProvider,
    required this.gitaProvider,
    required this.chatProvider,
    required this.tapSoundProvider,
  });

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(userProvider: userProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: mantraProvider),
        ChangeNotifierProvider.value(value: storiesProvider),
        ChangeNotifierProvider.value(value: gitaProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider.value(value: tapSoundProvider),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp.router(
            title: 'DivinePath',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('mr'),
              Locale('gu'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
