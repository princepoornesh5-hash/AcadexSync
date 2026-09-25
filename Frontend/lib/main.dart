import 'core/firebase/firebase_config.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/presentation/screens/firebase_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app/theme/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'core/observability/logger.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/domain/models/auth_state.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}






final bootStopwatch = Stopwatch()..start();

void main() async {
  debugPrint('[BOOT_START]');
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
      AcadexLogger.error('Flutter Framework Error', error: details.exception, stackTrace: details.stack);
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
    debugPrint('[FIREBASE_INIT_START]');
    final fbSw = Stopwatch()..start();
    await FirebaseInitializer.initialize(FirebaseEnv.production);
    debugPrint('[FIREBASE_INIT_END] (${fbSw.elapsedMilliseconds}ms)');

    // Pre-initialize icon font definitions to prevent DDC call stack recursion during initial widget build
    final _ = LucideIcons.user;

    if (!FirebaseInitializer.shouldUseMock && !kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    debugPrint('[FIRST_UI] (${bootStopwatch.elapsedMilliseconds}ms)');
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
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCM();
      _setupTokenRegistration();
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _messageOpenedSub?.cancel();
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  void _setupFCM() async {
    if (FirebaseInitializer.shouldUseMock) return;

    try {
      // 1. Foreground message handler
      _messageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground notification received: ${message.messageId}');

        // Invalidate notification caches so unread badge and notification center update
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationCountProvider);
        ref.invalidate(announcementsProvider);
        ref.invalidate(adminAnnouncementsProvider);

        final notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? 'New Notification';
        final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
        final deepLink = message.data['deepLink'] ?? message.data['navigationTarget'];

        // Display in-app SnackBar banner with navigation action
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                if (body.isNotEmpty)
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: deepLink != null
                ? SnackBarAction(
                    label: 'VIEW',
                    textColor: const Color(0xFF38BDF8),
                    onPressed: () {
                      final router = ref.read(appRouterProvider);
                      router.push(deepLink.toString());
                    },
                  )
                : null,
          ),
        );
      });

      // 2. Background message opened app
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] User tapped notification from background: ${message.data}');
        final deepLink = message.data['deepLink'] ?? message.data['navigationTarget'];
        if (deepLink != null) {
          final router = ref.read(appRouterProvider);
          router.push(deepLink.toString());
        }
      });

      // 3. Terminated app opened from notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App launched from terminated state via notification: ${initialMessage.data}');
        final deepLink = initialMessage.data['deepLink'] ?? initialMessage.data['navigationTarget'];
        if (deepLink != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final router = ref.read(appRouterProvider);
            router.push(deepLink.toString());
          });
        }
      }
    } catch (e) {
      debugPrint('[FCM] Error setting up FCM listeners: $e');
    }
  }

  void _setupTokenRegistration() {
    if (FirebaseInitializer.shouldUseMock) return;

    // Listen to auth state to register device token when authenticated
    ref.listenManual(authProvider, (previous, next) async {
      if (next is AuthAuthenticated) {
        try {
          final messaging = FirebaseMessaging.instance;
          final settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            final token = await messaging.getToken();
            if (token != null && token.isNotEmpty) {
              await ref.read(apiNotificationRepositoryProvider).registerDeviceToken(
                deviceToken: token,
                platform: defaultTargetPlatform.name,
              );
            }
          }
        } catch (e) {
          debugPrint('[FCM] Device token registration skipped: $e');
        }
      }
    });

    // Also listen to token refresh
    try {
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final auth = ref.read(authProvider);
        if (auth is AuthAuthenticated && newToken.isNotEmpty) {
          await ref.read(apiNotificationRepositoryProvider).registerDeviceToken(
            deviceToken: newToken,
            platform: defaultTargetPlatform.name,
          );
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Campus Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }
}
