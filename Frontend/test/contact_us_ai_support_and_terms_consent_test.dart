import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/features/ai_assistant/domain/models/ai_response.dart';
import 'package:campus_management/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:campus_management/features/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:campus_management/features/auth/presentation/screens/contact_us_screen.dart';
import 'package:campus_management/features/auth/presentation/screens/terms_and_conditions_screen.dart';
import 'package:campus_management/features/auth/presentation/widgets/terms_acceptance_checkbox.dart';

class _FakeAiRepository implements AiRepository {
  String? lastQuery;
  int queryCount = 0;
  bool shouldThrow = false;
  String returnAnswer =
      'Account activation requires entering your 8-character invitation code and verifying OTP.';

  @override
  Future<AiResponse> sendPublicSupportQuery({
    required String query,
    List<Map<String, String>>? history,
  }) async {
    lastQuery = query;
    queryCount++;
    if (shouldThrow) {
      throw Exception('Network error connecting to AI service');
    }
    return AiResponse(answer: returnAnswer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithApp({required Widget child, _FakeAiRepository? aiRepo}) {
  return ProviderScope(
    overrides: [
      if (aiRepo != null) aiRepositoryProvider.overrideWithValue(aiRepo),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  group('ACADEXSYNC Contact Us Redesign & AI Integration Verification', () {
    testWidgets(
      '1. Displays exact owner contact details and verified contact cards',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final aiRepo = _FakeAiRepository();
        await tester.pumpWidget(
          _wrapWithApp(child: const ContactUsScreen(), aiRepo: aiRepo),
        );
        await tester.pumpAndSettle();

        // Verify header and CTA banner
        expect(find.byKey(const Key('contact_us_screen')), findsOneWidget);
        expect(find.text('Authorised Support Contacts'), findsOneWidget);
        expect(find.text('Bring ACADEXSYNC to Your College'), findsOneWidget);

        // Verify phone card
        expect(find.byKey(const Key('contact_phone_card')), findsOneWidget);
        expect(find.text(ContactUsScreen.ownerPhone), findsOneWidget);
        expect(find.text('Call Now'), findsOneWidget);

        // Verify email card
        expect(find.byKey(const Key('contact_email_card')), findsOneWidget);
        expect(find.text(ContactUsScreen.ownerEmail), findsOneWidget);
        expect(find.text('Send Email'), findsOneWidget);

        // Verify location card
        expect(find.byKey(const Key('contact_location_card')), findsOneWidget);
        expect(find.text(ContactUsScreen.ownerLocation), findsWidgets);
      },
    );

    testWidgets(
      '2. Suggested questions trigger AI assistant with loading and response display',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final aiRepo = _FakeAiRepository();
        await tester.pumpWidget(
          _wrapWithApp(child: const ContactUsScreen(), aiRepo: aiRepo),
        );
        await tester.pumpAndSettle();

        // Scroll to AI section
        await tester.ensureVisible(
          find.byKey(const Key('ask_ai_section_card')),
        );
        await tester.pumpAndSettle();

        // Check chips exist
        expect(find.text('How do I activate my account?'), findsOneWidget);
        expect(find.text('How do I sign in using email OTP?'), findsOneWidget);
        expect(find.text('How can my college register?'), findsOneWidget);

        // Tap suggestion chip
        await tester.tap(find.text('How do I activate my account?'));
        await tester.pump(); // Start async request

        // Verify AI repo was invoked with the exact question
        expect(aiRepo.lastQuery, 'How do I activate my account?');
        expect(aiRepo.queryCount, 1);

        await tester.pumpAndSettle();

        // Verify response card rendered
        expect(find.byKey(const Key('ai_response_card')), findsOneWidget);
        expect(
          find.textContaining(
            'Account activation requires entering your 8-character invitation code',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('3. Custom query input and error retry state work reliably', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(412, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final aiRepo = _FakeAiRepository()..shouldThrow = true;
      await tester.pumpWidget(
        _wrapWithApp(child: const ContactUsScreen(), aiRepo: aiRepo),
      );
      await tester.pumpAndSettle();

      // Scroll to AI section
      await tester.ensureVisible(find.byKey(const Key('ai_query_input_field')));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(
        find.byKey(const Key('ai_query_input_field')),
        'Is there a mobile app for students?',
      );
      await tester.tap(find.byKey(const Key('ai_query_send_button')));
      await tester.pumpAndSettle();

      // Error card displayed
      expect(find.byKey(const Key('ai_error_card')), findsOneWidget);
      expect(find.text('Retry Query'), findsOneWidget);

      // Now fix repo and retry
      aiRepo.shouldThrow = false;
      aiRepo.returnAnswer =
          'Yes, ACADEXSYNC is a responsive PWA and Flutter mobile application.';

      await tester.tap(find.text('Retry Query'));
      await tester.pumpAndSettle();

      // Verify recovery
      expect(find.byKey(const Key('ai_response_card')), findsOneWidget);
      expect(
        find.textContaining('Yes, ACADEXSYNC is a responsive PWA'),
        findsOneWidget,
      );
    });

    testWidgets(
      '4. FAQ cards expand and allow routing question to AI assistant',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final aiRepo = _FakeAiRepository();
        await tester.pumpWidget(
          _wrapWithApp(child: const ContactUsScreen(), aiRepo: aiRepo),
        );
        await tester.pumpAndSettle();

        // Find FAQ item 0
        final faq0 = find.byKey(const Key('faq_item_0'));
        await tester.ensureVisible(faq0);
        await tester.pumpAndSettle();

        // Initially answer is not visible
        expect(
          find.textContaining(
            'Code-First: Enter the unique 8-character invitation code',
          ),
          findsNothing,
        );

        // Tap FAQ header to expand
        await tester.tap(faq0);
        await tester.pumpAndSettle();

        // Now answer is visible
        expect(
          find.textContaining(
            'Code-First: Enter the unique 8-character invitation code',
          ),
          findsOneWidget,
        );
        expect(find.text('Ask AI More'), findsOneWidget);

        // Tap 'Ask AI More'
        await tester.tap(find.text('Ask AI More'));
        await tester.pumpAndSettle();

        expect(aiRepo.queryCount, 1);
        expect(aiRepo.lastQuery, 'How do I activate my institutional account?');
      },
    );

    testWidgets(
      '5. College onboarding dialog enforces validation and formats email draft',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_wrapWithApp(child: const ContactUsScreen()));
        await tester.pumpAndSettle();

        // Open college onboarding dialog
        await tester.tap(find.byKey(const Key('register_college_cta_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('college_onboarding_dialog')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('college_onboarding_dialog')),
            matching: find.text('Register Your College'),
          ),
          findsOneWidget,
        );

        // Try submitting empty form
        await tester.tap(
          find.byKey(const Key('submit_onboarding_form_button')),
        );
        await tester.pumpAndSettle();

        // Validation errors
        expect(find.text('Please enter your institution name'), findsOneWidget);
        expect(find.text('Please specify city and state'), findsOneWidget);

        // Fill in required fields
        await tester.enterText(
          find.byKey(const Key('onboarding_college_name_field')),
          'Tirupati Engineering College',
        );
        await tester.enterText(
          find.byKey(const Key('onboarding_location_field')),
          'Tirupati, Andhra Pradesh',
        );
        await tester.enterText(
          find.byKey(const Key('onboarding_admin_name_field')),
          'Prof. M. Sreenivasulu',
        );
        await tester.enterText(
          find.byKey(const Key('onboarding_designation_field')),
          'Dean of Academic Affairs',
        );
        await tester.enterText(
          find.byKey(const Key('onboarding_email_field')),
          'dean@tec.edu.in',
        );
        await tester.pumpAndSettle();

        // Tap Copy Email Draft
        await tester.tap(find.byKey(const Key('copy_email_draft_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // SnackBar shows copy success
        expect(
          find.textContaining('Formatted email copied to clipboard!'),
          findsOneWidget,
        );
      },
    );
  });

  group('Terms & Conditions and Consent Checkbox Verification', () {
    testWidgets(
      '6. Terms & Conditions displays draft status, legal research citations, and 15 sections',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrapWithApp(child: const TermsAndConditionsScreen()),
        );
        await tester.pumpAndSettle();

        // Verify draft badge and legal citations
        expect(find.text('DRAFT VERSION: 2026.1-draft'), findsOneWidget);
        expect(
          find.text('Subject to Formal Owner & Legal Counsel Review'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Digital Personal Data Protection Act, 2023'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Consumer Protection Act, 2019'),
          findsWidgets,
        );

        // Verify 15 sections
        expect(find.text('15 Agreement Sections'), findsOneWidget);
        expect(find.byKey(const Key('terms_section_1')), findsOneWidget);
        expect(find.byKey(const Key('terms_section_2')), findsOneWidget);
        expect(find.byKey(const Key('terms_section_7')), findsOneWidget);
        expect(find.byKey(const Key('terms_section_10')), findsOneWidget);
        expect(find.byKey(const Key('terms_section_13')), findsOneWidget);
        expect(find.byKey(const Key('terms_section_15')), findsOneWidget);

        // Expand and collapse all buttons work
        await tester.ensureVisible(
          find.byKey(const Key('terms_collapse_all_button')),
        );
        await tester.tap(find.byKey(const Key('terms_collapse_all_button')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('terms_expand_all_button')),
        );
        await tester.tap(find.byKey(const Key('terms_expand_all_button')));
        await tester.pumpAndSettle();

        // Section 10 AI Assistant Limitations verified
        expect(
          find.text('10. AI Assistant Limitations & Mandatory Verification'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. TermsAcceptanceCheckbox is initially unchecked and updates on tap',
      (tester) async {
        bool isChecked = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return TermsAcceptanceCheckbox(
                    value: isChecked,
                    onChanged: (val) {
                      setState(() {
                        isChecked = val ?? false;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(
          find.byKey(const Key('terms_checkbox')),
        );
        expect(checkbox.value, isFalse);

        // Tap checkbox
        await tester.tap(find.byKey(const Key('terms_checkbox')));
        await tester.pumpAndSettle();

        expect(isChecked, isTrue);
      },
    );
  });
}
