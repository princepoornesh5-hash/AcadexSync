import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/acadex_avatar.dart';
import 'package:campus_management/core/presentation/widgets/acadex_button.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_chip.dart';
import 'package:campus_management/core/presentation/widgets/acadex_search_bar.dart';
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
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit Action',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      ));

      expect(find.text('Submit Action'), findsOneWidget);
      await tester.tap(find.text('Submit Action'));
      expect(pressed, isTrue);
    });

    testWidgets('AcadexButton renders label, icon, and responds to click', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AcadexButton(
              label: 'Save Changes',
              icon: Icons.check,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      ));

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.text('Save Changes'));
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

    testWidgets('AcadexAvatar renders initials and handles online indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AcadexAvatar(
            name: 'Sarah Connor',
            isOnline: true,
          ),
        ),
      ));

      expect(find.text('SC'), findsOneWidget);
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

    testWidgets('AcadexStatCard renders correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AcadexStatCard(
            title: 'Total Students',
            value: '1,200',
            subtitle: 'Enrolled this year',
            icon: Icons.school,
          ),
        ),
      ));

      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('1,200'), findsOneWidget);
      expect(find.text('Enrolled this year'), findsOneWidget);
    });

    testWidgets('AppEmptyState renders title and action', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              title: 'No Data Found',
              description: 'Please add a new record to proceed.',
              actionLabel: 'Create New',
              onAction: () => actionTriggered = true,
            ),
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
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              message: 'Server connection timeout',
              onRetry: () => retryTriggered = true,
            ),
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

    testWidgets('AcadexBadge renders label with custom colors and icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AcadexBadge(
            label: 'VERIFIED',
            icon: Icons.check_circle,
            variant: AcadexBadgeVariant.success,
          ),
        ),
      ));

      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
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

    testWidgets('AcadexSearchBar handles controller and clear action', (tester) async {
      final controller = TextEditingController(text: 'Initial Text');
      String query = 'Initial Text';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AcadexSearchBar(
            controller: controller,
            hintText: 'Search here...',
            onChanged: (val) => query = val,
          ),
        ),
      ));

      expect(find.text('Initial Text'), findsOneWidget);
      expect(find.byIcon(Icons.clear, skipOffstage: false), findsNothing);
      expect(find.byType(IconButton), findsOneWidget); // Clear icon

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.text, '');
      expect(query, '');
    });
  });
}
