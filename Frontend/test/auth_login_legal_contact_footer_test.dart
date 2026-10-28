import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_management/features/auth/presentation/screens/terms_and_conditions_screen.dart';
import 'package:campus_management/features/auth/presentation/screens/contact_us_screen.dart';
import 'package:campus_management/app/router/app_router.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier() : super(const AuthUnauthenticated());

  @override
  Future<void> login(String identifier, String password) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestableApp({
  required GoRouter router,
  Size screenSize = const Size(800, 1000),
  double textScale = 1.0,
  double bottomInset = 0.0,
  AuthState? initialAuthState,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) {
        final notifier = _FakeAuthNotifier();
        if (initialAuthState != null) {
          notifier.state = initialAuthState;
        }
        return notifier;
      }),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: TextScaler.linear(textScale),
        viewInsets: EdgeInsets.only(bottom: bottomInset),
      ),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

GoRouter _createMockRouter({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/terms-and-conditions',
        redirect: (context, state) => '/terms',
      ),
      GoRoute(
        path: '/contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(path: '/contact', redirect: (context, state) => '/contact-us'),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const Scaffold(body: Text('Register Screen Target')),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) =>
            const Scaffold(body: Text('Activate Screen Target')),
      ),
    ],
  );
}

void main() {
  group('ACADEXSYNC Login Footer & Legal/Support Pages Verification', () {
    testWidgets(
      '1. Both footer links render on initial login screen with middle dot separator',
      (tester) async {
        final router = _createMockRouter();
        await tester.pumpWidget(_buildTestableApp(router: router));
        await tester.pumpAndSettle();

        // Verify presence of footer text
        expect(find.text('Terms & Conditions'), findsOneWidget);
        expect(find.text('·'), findsOneWidget);
        expect(find.text('Contact Us'), findsOneWidget);

        // Verify tap target keys
        final termsKey = find.byKey(const Key('login_terms_link'));
        final contactKey = find.byKey(const Key('login_contact_link'));
        expect(termsKey, findsOneWidget);
        expect(contactKey, findsOneWidget);

        // Verify accessible touch target size (>= 44x44 dp)
        final termsSize = tester.getSize(termsKey);
        expect(termsSize.height, greaterThanOrEqualTo(44.0));
        final contactSize = tester.getSize(contactKey);
        expect(contactSize.height, greaterThanOrEqualTo(44.0));
      },
    );

    testWidgets(
      '2. Footer links are hidden on secondary auth steps and reappear on change email',
      (tester) async {
        final router = _createMockRouter();
        await tester.pumpWidget(_buildTestableApp(router: router));
        await tester.pumpAndSettle();

        // Enter email and continue to password step
        await tester.enterText(
          find.byKey(const Key('welcome_email_field')),
          'faculty@acadex.com',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('welcome_continue_button')));
        await tester.pumpAndSettle();

        // Verify we are on Step 2 (password login)
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);

        // Footer must NOT be rendered on secondary password step
        expect(find.byKey(const Key('login_terms_link')), findsNothing);
        expect(find.byKey(const Key('login_contact_link')), findsNothing);

        // Tap Change email button to return to Step 1
        await tester.tap(find.byKey(const Key('change_email_button')));
        await tester.pumpAndSettle();

        // Verify footer reappears on Step 1
        expect(find.byKey(const Key('login_terms_link')), findsOneWidget);
        expect(find.byKey(const Key('login_contact_link')), findsOneWidget);
      },
    );

    testWidgets(
      '3. Terms & Conditions link navigates to dedicated in-app page with honest legal review pending status and reused content',
      (tester) async {
        final router = _createMockRouter();
        await tester.pumpWidget(_buildTestableApp(router: router));
        await tester.pumpAndSettle();

        // Scroll footer into view if needed and tap Terms & Conditions
        await tester.ensureVisible(find.byKey(const Key('login_terms_link')));
        await tester.tap(find.byKey(const Key('login_terms_link')));
        await tester.pumpAndSettle();

        // Verify Terms & Conditions screen loaded
        expect(
          find.byKey(const Key('terms_and_conditions_screen')),
          findsOneWidget,
        );
        expect(find.text('Terms & Conditions'), findsWidgets);

        // Verify honest status badge and pending documentation disclosure
        expect(find.text('STATUS: UNDER INSTITUTIONAL REVIEW'), findsOneWidget);
        expect(
          find.text('Legal Disclosure & Pending Documentation'),
          findsOneWidget,
        );

        // Verify reused approved text from settings
        expect(
          find.textContaining(
            'ACADEXSYNC Campus Management System is licensed for accredited institutional operations',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'ACADEXSYNC enforces strict multi-tenant isolation and role-based access control',
          ),
          findsOneWidget,
        );

        // Verify structured checklist of pending owner specifications
        expect(find.text('Master Service Agreement (MSA)'), findsOneWidget);
        expect(find.text('Campus Acceptable Use Policy (AUP)'), findsOneWidget);
        expect(find.text('Academic Data Retention Schedule'), findsOneWidget);
        expect(
          find.text('Dispute Resolution & Legal Jurisdiction'),
          findsOneWidget,
        );

        // Verify explicit notice that viewing page does NOT grant consent or active privileges
        expect(
          find.textContaining(
            'Navigating to or reading this page does not constitute institutional consent',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '4. Back navigation from Terms & Conditions returns to Login screen',
      (tester) async {
        final router = _createMockRouter();
        await tester.pumpWidget(_buildTestableApp(router: router));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('login_terms_link')));
        await tester.tap(find.byKey(const Key('login_terms_link')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('terms_and_conditions_screen')),
          findsOneWidget,
        );

        // Tap back button
        final backButton = find.widgetWithIcon(IconButton, Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        } else {
          // Fallback to finding back icon in page header
          await tester.tap(find.byType(IconButton).first);
        }
        await tester.pumpAndSettle();

        // Verify we returned to the login screen
        expect(find.byKey(const Key('welcome_email_field')), findsOneWidget);
        expect(find.byKey(const Key('login_terms_link')), findsOneWidget);
      },
    );

    testWidgets(
      '5. Contact Us link navigates to dedicated in-app page disclosing unconfigured support channels honestly',
      (tester) async {
        final router = _createMockRouter();
        await tester.pumpWidget(_buildTestableApp(router: router));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('login_contact_link')));
        await tester.tap(find.byKey(const Key('login_contact_link')));
        await tester.pumpAndSettle();

        // Verify Contact Us screen loaded
        expect(find.byKey(const Key('contact_us_screen')), findsOneWidget);
        expect(find.text('Contact Us'), findsWidgets);

        // Verify honest unconfigured status
        expect(
          find.text('STATUS: SUPPORT CHANNELS UNCONFIGURED'),
          findsOneWidget,
        );
        expect(
          find.text('Support Contact Information Pending Configuration'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Official direct support channels, campus helpdesk hotlines, and operational email endpoints have not yet been configured',
          ),
          findsOneWidget,
        );

        // Verify on-campus guidance for students, faculty, and administrators
        expect(find.text('Enrolled Students'), findsOneWidget);
        expect(find.text('Faculty & Academic Staff'), findsOneWidget);
        expect(find.text('College Administrators'), findsOneWidget);

        // Verify required configuration items for project owner
        expect(find.text('Institutional Support Email'), findsOneWidget);
        expect(
          find.text('Campus IT Helpdesk Phone & Working Hours'),
          findsOneWidget,
        );
        expect(find.text('Physical Helpdesk Location'), findsOneWidget);
        expect(
          find.text('Support Portal & Ticket Management URL'),
          findsOneWidget,
        );

        // Verify disclosure regarding default repository mock settings
        expect(find.textContaining('support@acadex.edu'), findsOneWidget);
      },
    );

    testWidgets('6. Back navigation from Contact Us returns to Login screen', (
      tester,
    ) async {
      final router = _createMockRouter();
      await tester.pumpWidget(_buildTestableApp(router: router));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('login_contact_link')));
      await tester.tap(find.byKey(const Key('login_contact_link')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('contact_us_screen')), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      // Verify returned to login screen
      expect(find.byKey(const Key('welcome_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_contact_link')), findsOneWidget);
    });

    testWidgets(
      '7. Deep links /terms and /contact-us are accessible without authentication in app_router',
      (tester) async {
        final container = ProviderContainer(
          overrides: [authProvider.overrideWith((ref) => _FakeAuthNotifier())],
        );
        addTearDown(container.dispose);

        final router = container.read(appRouterProvider);

        // Deep link to /terms directly
        router.go('/terms');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('terms_and_conditions_screen')),
          findsOneWidget,
        );

        // Deep link to /contact-us directly
        router.go('/contact-us');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('contact_us_screen')), findsOneWidget);

        // Deep link alias /terms-and-conditions redirects to /terms
        router.go('/terms-and-conditions');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('terms_and_conditions_screen')),
          findsOneWidget,
        );

        // Deep link alias /contact redirects to /contact-us
        router.go('/contact');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('contact_us_screen')), findsOneWidget);
      },
    );

    testWidgets(
      '8. Responsive layout renders without overflow on 360dp, 390dp, and 412dp with text scaling',
      (tester) async {
        final router = _createMockRouter();
        final widths = [360.0, 390.0, 412.0];
        final scales = [1.0, 1.15, 1.25];

        for (final w in widths) {
          for (final s in scales) {
            tester.view.physicalSize = Size(w, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() => tester.view.resetPhysicalSize());

            await tester.pumpWidget(
              _buildTestableApp(
                router: router,
                screenSize: Size(w, 800),
                textScale: s,
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byKey(const Key('login_terms_link')), findsOneWidget);
            expect(find.byKey(const Key('login_contact_link')), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets(
      '9. Virtual keyboard bottom inset (300dp) scrolls cleanly without RenderFlex overflow',
      (tester) async {
        final router = _createMockRouter();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          _buildTestableApp(
            router: router,
            screenSize: const Size(390, 844),
            bottomInset: 300.0,
          ),
        );
        await tester.pumpAndSettle();

        // Ensure form controls and footer can be scrolled into view cleanly
        await tester.ensureVisible(find.byKey(const Key('login_terms_link')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('login_terms_link')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '10. Existing registration and activation routes remain fully functional from login',
      (tester) async {
        final router = _createMockRouter();
        await tester.pumpWidget(_buildTestableApp(router: router));
        await tester.pumpAndSettle();

        // Tap Create an Account
        await tester.ensureVisible(
          find.byKey(const Key('link_create_account')),
        );
        await tester.tap(find.byKey(const Key('link_create_account')));
        await tester.pumpAndSettle();
        expect(find.text('Register Screen Target'), findsOneWidget);

        // Return to login
        router.go('/login');
        await tester.pumpAndSettle();

        // Tap Activate Account
        await tester.ensureVisible(
          find.byKey(const Key('link_activate_account')),
        );
        await tester.tap(find.byKey(const Key('link_activate_account')));
        await tester.pumpAndSettle();
        expect(find.text('Activate Screen Target'), findsOneWidget);
      },
    );
  });
}
