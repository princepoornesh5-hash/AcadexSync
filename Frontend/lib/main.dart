import 'core/firebase/firebase_config.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/presentation/screens/firebase_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/observability/logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}






void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Setup Global Error Handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      AcadexLogger.error('Flutter Framework Error', error: details.exception, stackTrace: details.stack);
      if (kReleaseMode) {
        // In production, prevent the default gray screen of death dump to console
        // We've logged it above.
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AcadexLogger.error('Unhandled Async Error (PlatformDispatcher)', error: error, stackTrace: stack);
      return true; // Prevent app crash if possible
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Component Load Error',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode ? details.exceptionAsString() : 'An unexpected error occurred while rendering this component. Our team has been notified.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };

    // 2. Initialize Firebase predictably before building UI or Riverpod providers
    // PRODUCTION BOUNDARY: Force production initialization by default
    await FirebaseInitializer.initialize(FirebaseEnv.production);

    if (!FirebaseInitializer.shouldUseMock && !kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    runApp(
      const ProviderScope(
        child: AcadexAppWrapper(),
      ),
    );
  }, (error, stack) {
    AcadexLogger.error('ZonedGuarded Error', error: error, stackTrace: stack);
  });
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

class CampusManagementApp extends ConsumerStatefulWidget {
  const CampusManagementApp({super.key});

  @override
  ConsumerState<CampusManagementApp> createState() => _CampusManagementAppState();
}

class _CampusManagementAppState extends ConsumerState<CampusManagementApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() {
    if (FirebaseInitializer.shouldUseMock) return;
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
