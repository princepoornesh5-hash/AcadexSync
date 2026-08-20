import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/app_avatar.dart';
import 'package:campus_management/core/presentation/widgets/app_badge.dart';
import 'package:campus_management/core/presentation/widgets/app_button.dart';
import 'package:campus_management/core/presentation/widgets/app_card.dart';
import 'package:campus_management/core/presentation/widgets/app_empty_state.dart';
import 'package:campus_management/core/presentation/widgets/app_error_state.dart';
import 'package:campus_management/core/presentation/widgets/app_search_field.dart';
import 'package:campus_management/core/presentation/widgets/app_stat_card.dart';

void main() {
  group('ACADEX Design System Widgets', () {
    testWidgets('AppCard renders child and handles onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('Card Content'),
          ),
        ),
      ));

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton renders label and triggers callback', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Submit Action',
            onPressed: () => pressed = true,
          ),
        ),
      ));

      expect(find.text('Submit Action'), findsOneWidget);
      await tester.tap(find.text('Submit Action'));
      expect(pressed, isTrue);
    });

    testWidgets('AppAvatar renders initials when no image provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppAvatar(name: 'John Doe'),
        ),
      ));

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('AppStatCard renders title, value and icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppStatCard(
            title: 'Attendance',
            value: '92.4%',
            subtitle: 'This semester',
            icon: Icons.check_circle,
          ),
        ),
      ));

      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('92.4%'), findsOneWidget);
      expect(find.text('This semester'), findsOneWidget);
    });

    testWidgets('AppEmptyState renders title and action', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'No Data Found',
            description: 'Please add a new record to proceed.',
            actionLabel: 'Create New',
            onAction: () => actionTriggered = true,
          ),
        ),
      ));

      expect(find.text('No Data Found'), findsOneWidget);
      expect(find.text('Please add a new record to proceed.'), findsOneWidget);
      await tester.tap(find.text('Create New'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorState renders message and retry', (tester) async {
      bool retryTriggered = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            message: 'Server connection timeout',
            onRetry: () => retryTriggered = true,
          ),
        ),
      ));

      expect(find.text('Server connection timeout'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retryTriggered, isTrue);
    });

    testWidgets('AppBadge renders label correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppBadge(
            label: 'ACTIVE',
            variant: AppBadgeVariant.success,
          ),
        ),
      ));

      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('AppSearchField text change triggers callback', (tester) async {
      String query = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            hintText: 'Search departments...',
            onChanged: (val) => query = val,
          ),
        ),
      ));

      expect(find.text('Search departments...'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Computer Science');
      expect(query, 'Computer Science');
    });
  });
}
