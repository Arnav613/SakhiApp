import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'providers/providers.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/settings/main_nav.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive before app launches
  await StorageService.init();
  await NotificationService.init();
  await BackgroundService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            SakhiColors.deep,
    statusBarIconBrightness:   Brightness.light,
    systemNavigationBarColor:  SakhiColors.deep,
  ));
  runApp(const ProviderScope(child: SakhiApp()));
}

class SakhiApp extends ConsumerWidget {
  const SakhiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingCompleteProvider);

    return MaterialApp(
      title:          'Sakhi',
      debugShowCheckedModeBanner: false,
      theme:          SakhiTheme.theme,
      home:           onboardingDone ? const MainNav() : const OnboardingScreen(),
    );
  }
}