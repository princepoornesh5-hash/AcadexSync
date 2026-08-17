import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

import 'core/firebase/firebase_config.dart';
import 'core/firebase/firebase_initializer.dart';

import 'core/presentation/screens/firebase_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase predictably before building UI or Riverpod providers
  // PRODUCTION BOUNDARY: Force production initialization by default
  await FirebaseInitializer.initialize(FirebaseEnv.production);

  runApp(
    const ProviderScope(
      child: AcadexAppWrapper(),
    ),
  );
}

class AcadexAppWrapper extends StatefulWidget {
  const AcadexAppWrapper({super.key});

  @override
  State<AcadexAppWrapper> createState() => _AcadexAppWrapperState();
}

class _AcadexAppWrapperState extends State<AcadexAppWrapper> {
  @override
  Widget build(BuildContext context) {
    if (FirebaseInitializer.state == FirebaseInitializationState.failed) {
      return FirebaseErrorScreen(
        onRetry: () {
          setState(() {}); // Rebuild after retry attempt
        },
      );
    }
    
    // Proceed to real application
    return const CampusManagementApp();
  }
}

class CampusManagementApp extends ConsumerWidget {
  const CampusManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    // Default to dark theme while loading or error
    final themeMode = settingsAsync.maybeWhen(
      data: (settings) => settings.themeMode,
      orElse: () => ThemeMode.dark,
    );

    return MaterialApp.router(
      title: 'Campus Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
