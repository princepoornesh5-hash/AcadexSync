import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/realtime_event.dart';
import '../../services/realtime_service.dart';
import '../../services/realtime_dispatcher.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/models/auth_state.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final realtimeStatusProvider = StreamProvider<RealtimeConnectionStatus>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.statusStream;
});

final realtimeDispatcherProvider = Provider<RealtimeDispatcher>((ref) {
  final dispatcher = RealtimeDispatcher(ref);
  final service = ref.watch(realtimeServiceProvider);

  dispatcher.start(service.eventStream);

  // Monitor connection status to trigger authoritative resync upon reconnection
  RealtimeConnectionStatus? previousStatus;
  final sub = service.statusStream.listen((status) {
    if (previousStatus == RealtimeConnectionStatus.reconnecting &&
        status == RealtimeConnectionStatus.connected) {
      debugPrint('[Realtime] Socket reconnected. Triggering authoritative resync.');
      dispatcher.triggerAuthoritativeResync();
    }
    previousStatus = status;
  });

  ref.onDispose(() {
    sub.cancel();
    dispatcher.stop();
  });

  return dispatcher;
});

/// Orchestrator provider that binds the RealtimeService connection to AuthState.
final realtimeConnectionCoordinatorProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  // Ensure dispatcher is alive and listening
  ref.watch(realtimeDispatcherProvider);

  if (authState is AuthAuthenticated) {
    debugPrint('[Realtime Coordinator] User authenticated (${authState.user.id}). Connecting realtime socket.');
    realtimeService.connect();
  } else {
    debugPrint('[Realtime Coordinator] User logged out or unauthenticated. Disconnecting socket.');
    realtimeService.disconnect(isLogout: true);
  }
});
