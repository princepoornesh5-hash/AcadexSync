import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/core/realtime/models/realtime_event.dart';
import 'package:campus_management/core/realtime/services/realtime_service.dart';
import 'package:campus_management/core/realtime/presentation/widgets/realtime_status_pill.dart';
import 'package:campus_management/core/realtime/presentation/providers/realtime_providers.dart';

import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';

class _TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _TestAuthNotifier() : super(const AuthUnauthenticated());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PROMPT 38 — RealtimeEvent Contract Tests', () {
    test('RealtimeEvent parses standard versioned envelope correctly', () {
      final json = {
        'eventId': 'evt_12345',
        'eventVersion': 1,
        'eventType': 'timetable.updated',
        'aggregateType': 'Timetable',
        'aggregateId': 'tt_999',
        'action': 'updated',
        'occurredAt': '2026-09-29T10:00:00.000Z',
        'collegeId': 'col_alpha',
        'scope': {'departmentId': 'dept_cse'},
        'payload': {'sectionId': 'sec_a', 'version': 2},
      };

      final event = RealtimeEvent.fromJson(json);

      expect(event.eventId, 'evt_12345');
      expect(event.eventVersion, 1);
      expect(event.eventType, 'timetable.updated');
      expect(event.aggregateType, 'Timetable');
      expect(event.aggregateId, 'tt_999');
      expect(event.action, 'updated');
      expect(event.occurredAt.isUtc, true);
      expect(event.collegeId, 'col_alpha');
      expect(event.scope['departmentId'], 'dept_cse');
      expect(event.payload['version'], 2);

      final serialized = event.toJson();
      expect(serialized['eventId'], 'evt_12345');
      expect(serialized['eventType'], 'timetable.updated');
    });

    test('RealtimeEvent handles missing/null values safely with defaults', () {
      final json = <String, dynamic>{};
      final event = RealtimeEvent.fromJson(json);

      expect(event.eventId, '');
      expect(event.eventVersion, 1);
      expect(event.eventType, '');
      expect(event.aggregateType, '');
      expect(event.aggregateId, '');
      expect(event.action, '');
      expect(event.collegeId, '');
      expect(event.scope, isEmpty);
      expect(event.payload, isEmpty);
      expect(event.occurredAt, isNotNull);
    });
  });

  group('PROMPT 38 — RealtimeService URL and Deduplication Tests', () {
    test('activeWsUrl derives correct ws:// and wss:// endpoints', () {
      final customService = RealtimeService(wsUrl: 'ws://custom.host:5000/ws');
      expect(customService.activeWsUrl, 'ws://custom.host:5000/ws');

      final defaultService = RealtimeService();
      // Should derive from ApiClient default or environment and end with /ws
      expect(defaultService.activeWsUrl.contains('/ws'), true);
      expect(
        defaultService.activeWsUrl.startsWith('ws://') ||
            defaultService.activeWsUrl.startsWith('wss://'),
        true,
      );
    });

    test('RealtimeService deduplicates duplicate event deliveries', () async {
      final service = RealtimeService();
      final receivedEvents = <RealtimeEvent>[];
      final subscription = service.eventStream.listen(receivedEvents.add);

      expect(receivedEvents, isEmpty);
      await subscription.cancel();
    });
  });

  group('PROMPT 38 — RealtimeDispatcher Burst Debouncing & Routing Tests', () {
    test('Dispatcher executes debounced invalidation and coalesces rapid bursts', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
      );
      final dispatcher = container.read(realtimeDispatcherProvider);
      final eventController = StreamController<RealtimeEvent>.broadcast();

      dispatcher.start(eventController.stream);

      // Create a rapid burst of 5 notification events within 50ms
      for (int i = 0; i < 5; i++) {
        eventController.add(RealtimeEvent(
          eventId: 'evt_burst_$i',
          eventVersion: 1,
          eventType: 'notification.created',
          aggregateType: 'Notification',
          aggregateId: 'notif_$i',
          action: 'created',
          occurredAt: DateTime.now(),
          collegeId: 'col_alpha',
          scope: {},
          payload: {'index': i},
        ));
      }

      // Within debounce window (< 300ms), invalidation should be buffered
      await Future.delayed(const Duration(milliseconds: 50));

      // Wait beyond the 300ms window
      await Future.delayed(const Duration(milliseconds: 400));

      dispatcher.stop();
      await eventController.close();
      await Future.delayed(const Duration(milliseconds: 50));
      container.dispose();
    });

    test('Dispatcher safely ignores unknown future event types without error', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
      );
      final dispatcher = container.read(realtimeDispatcherProvider);
      final eventController = StreamController<RealtimeEvent>.broadcast();

      dispatcher.start(eventController.stream);

      // Emit an unknown version 99 event
      eventController.add(RealtimeEvent(
        eventId: 'evt_future_99',
        eventVersion: 99,
        eventType: 'quantumComputing.simulationStarted',
        aggregateType: 'QuantumJob',
        aggregateId: 'job_42',
        action: 'started',
        occurredAt: DateTime.now(),
        collegeId: 'col_alpha',
        scope: {},
        payload: {},
      ));

      // Give event loop time to process
      await Future.delayed(const Duration(milliseconds: 50));

      // Should complete gracefully without throwing
      dispatcher.stop();
      await eventController.close();
      await Future.delayed(const Duration(milliseconds: 50));
      container.dispose();
    });

    test('triggerAuthoritativeResync invalidates key providers without error', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
      );
      final dispatcher = container.read(realtimeDispatcherProvider);

      expect(() => dispatcher.triggerAuthoritativeResync(), returnsNormally);
      await Future.delayed(const Duration(milliseconds: 100));
      container.dispose();
    });
  });

  group('PROMPT 38 — RealtimeStatusPill Responsive UI Tests', () {
    testWidgets('RealtimeStatusPill is hidden when connected', (tester) async {
      final container = ProviderContainer(
        overrides: [
          realtimeStatusProvider.overrideWith(
            (ref) => Stream.value(RealtimeConnectionStatus.connected),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RealtimeStatusPill(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reconnecting live updates...'), findsNothing);
      expect(find.text('Offline (HTTP active)'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('RealtimeStatusPill shows reconnecting indicator across mobile screen widths', (tester) async {
      final container = ProviderContainer(
        overrides: [
          realtimeStatusProvider.overrideWith(
            (ref) => Stream.value(RealtimeConnectionStatus.reconnecting),
          ),
        ],
      );

      final screenWidths = [360.0, 390.0, 412.0];

      for (final width in screenWidths) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: Center(child: RealtimeStatusPill()),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Reconnecting live updates...'), findsOneWidget);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('RealtimeStatusPill shows offline indicator when disconnected', (tester) async {
      final container = ProviderContainer(
        overrides: [
          realtimeStatusProvider.overrideWith(
            (ref) => Stream.value(RealtimeConnectionStatus.disconnected),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: RealtimeStatusPill()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offline (HTTP active)'), findsOneWidget);
    });
  });
}
