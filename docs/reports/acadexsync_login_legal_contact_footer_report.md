# ACADEXSYNC: Login Footer, Terms & Conditions and Contact Us Implementation Report

## Executive Summary

A compact, accessible footer has been implemented on the initial ACADEXSYNC login screen (`LoginStep.welcome`), linking to dedicated in-app **Terms & Conditions** (`/terms`) and **Contact Us** (`/contact-us`) screens. 

All existing authentication, password recovery, email OTP verification, registration, and institutional activation flows remain fully functional and unaffected. The implementation reuses approved institutional notices present in the repository, honestly presents pending documentation/channel states without inventing fictitious legal text or dummy contact details, respects system navigation and keyboard insets, and includes 10 comprehensive automated widget/routing tests alongside a successful Android debug APK build.

---

## 1. Files Changed & Created

| File | Status | Description |
|---|---|---|
| [`Frontend/lib/features/auth/presentation/screens/login_screen.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/presentation/screens/login_screen.dart) | Modified | Added compact `_buildLoginFooter` rendered exclusively on `LoginStep.welcome`; wrapped header/activation text in `FittedBox` to prevent small viewport overflows. |
| [`Frontend/lib/features/auth/presentation/screens/terms_and_conditions_screen.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/presentation/screens/terms_and_conditions_screen.dart) | Created | Dedicated in-app page reusing existing institutional notices, displaying honest legal review pending status, owner requirements checklist, and safe back navigation. |
| [`Frontend/lib/features/auth/presentation/screens/contact_us_screen.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/presentation/screens/contact_us_screen.dart) | Created | Dedicated in-app page disclosing unconfigured support channels, on-campus escalation guidance, owner configuration requirements, and setting disclosure. |
| [`Frontend/lib/app/router/app_router.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/app/router/app_router.dart) | Modified | Registered public routes `/terms`, `/terms-and-conditions`, `/contact-us`, and `/contact`; added public route exemptions in router redirect guards for unauthenticated access. |
| [`Frontend/test/auth_login_legal_contact_footer_test.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/test/auth_login_legal_contact_footer_test.dart) | Created | 10 comprehensive automated tests verifying footer presence, step visibility isolation, navigation, content reuse, honest placeholders, safe back navigation, deep linking, and responsive insets. |
| [`docs/reports/acadexsync_login_legal_contact_footer_report.md`](file:///Users/poornesh/Campus%20Management%20Main/docs/reports/acadexsync_login_legal_contact_footer_report.md) | Created | Detailed audit and verification report. |

---

## 2. Footer Layout & Route Implementation

### 2.1 Login Footer Layout
- **Visual Typography & Tokens:** Restrained typography using `AcadexTypography.caption` with `AcadexColors.inkMuted` (light mode) and `AcadexColors.darkInkMuted` (dark mode). Centred dot separator (`·`) styled with `AcadexColors.inkFaint` / `AcadexColors.darkInkFaint`.
- **Placement & Visual Hierarchy:** Positioned below the authentication card and debug drawer within the primary `SingleChildScrollView`. Visually secondary to the login form, ensuring it does not distract from primary sign-in actions.
- **Touch Targets & Accessibility:** Both links are wrapped in `ConstrainedBox` with minimum dimensions of `44x44 dp`, wrapped in `Semantics(container: true, label: ...)` and `InkWell` with rounded hover highlights for full accessibility compliance.
- **Scroll & Viewport Constraints:** Responsive `Wrap` layout ensures zero `RenderFlex` overflow even on narrow 360dp mobile viewports and elevated text scaling factors (up to 1.25x). Positioned inside the scroll view so it never collides with or obscures the virtual keyboard when active (tested at 300dp bottom viewInsets).
- **Step Isolation:** Rendered strictly on `_currentStep == LoginStep.welcome`. When users enter their email and proceed to `LoginStep.passwordLogin` or `LoginStep.otpLogin`, the footer is hidden to maintain a focused input interface. If the user clicks "Change" to return to the welcome step, the footer re-appears.

### 2.2 Route Architecture & Public Access
- **Canonical Routes:**
  - `/terms`: Displays `TermsAndConditionsScreen`
  - `/contact-us`: Displays `ContactUsScreen`
- **Aliases & Redirects:**
  - `/terms-and-conditions` -> redirects to `/terms`
  - `/contact` -> redirects to `/contact-us`
- **Unauthenticated Route Protection Guards:**
  In [`Frontend/lib/app/router/app_router.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/app/router/app_router.dart), `isPublicInfoRoute` was defined to exempt `/terms`, `/terms-and-conditions`, `/contact-us`, and `/contact` from being redirected to `/login` when users are unauthenticated.
- **Session & Consent Continuity:**
  Opening either route does not create an authentication token, mutate `authProvider` state, or advance OTP/activation flows.
- **Back Navigation:**
  Both screens integrate `AcadexPageHeader` with back navigation using `context.safePop(fallbackRoute: fallback)`. For unauthenticated visitors, back navigation returns cleanly to `/login`. For authenticated users who navigate to these pages from internal settings, back navigation returns to the originating dashboard.

---

## 3. Existing Legal & Support Content Reused

An audit across the entire frontend and backend identified the following authoritative strings, which have been preserved and reused verbatim:

1. **Institutional Licensing & Accreditation Notice:**
   - *Source Location:* [`Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L356-L360`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L356-L360)
   - *Reused Text:* 
     > *"ACADEXSYNC Campus Management System is licensed for accredited institutional operations. All academic data, student records, and attendance logs are governed by institutional policy and applicable data privacy standards."*
2. **Multi-Tenant Isolation Notice:**
   - *Source Location:* [`Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L380-L384`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L380-L384)
   - *Reused Text:* 
     > *"ACADEXSYNC enforces strict multi-tenant isolation and role-based access control. Personal data, profile images, and academic evaluations are restricted to authorized campus staff and never shared across tenant boundaries."*
3. **Legal Copyright & Platform Build Notice:**
   - *Source Location:* [`Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L336`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L336) and [`Frontend/windows/runner/Runner.rc#L96`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/windows/runner/Runner.rc#L96)
   - *Reused Text:*
     > *"Copyright © 2026 com.campusmanagement / ACADEXSYNC Platform. All rights reserved. Version 1.0.0 (Build 42)"*
4. **Settings Placeholder Email Disclosure:**
   - *Source Location:* [`Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L472-L490`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart#L472-L490)
   - *Disclosure:* Disclosed that `support@acadex.edu` and `helpdesk@acadex.edu` in settings are mock defaults and do not connect to an active external mailbox.

---

## 4. Missing Information Requiring Project Owner Input

To uphold complete institutional honesty and avoid misrepresenting legal clearance or operational readiness, the following components are designated as **Pending Project Owner Configuration**:

### 4.1 Legal & Regulatory Requirements
1. **Master Service Agreement (MSA):** Formal commercial contract detailing uptime Service Level Agreements (SLAs), scheduled maintenance policies, and institutional covenants.
2. **Campus Acceptable Use Policy (AUP):** Specific student and faculty conduct rules governing laboratory computers, campus Wi-Fi authentication, and permissible device access.
3. **Academic Records Retention Schedule:** Statutory data retention guidelines under educational regulatory authorities (e.g. archiving schedules for marks, attendance registers, and official certificates).
4. **Governing Law & Legal Jurisdiction:** Designated arbitration venue, legal counsel of record, and state/national court jurisdiction.

### 4.2 Support Channel Configuration
1. **Authoritative Helpdesk Email:** Dedicated institutional email address (e.g. `support@yourinstitution.edu` or `it-helpdesk@college.ac.in`) backed by verified DNS MX records and staff routing.
2. **Helpdesk Telephone & Operating Hours:** Dedicated campus phone extension and active operating hours (e.g. Monday–Friday 9:00 AM – 5:00 PM IST).
3. **Physical Support Office Location:** Precise campus building, floor, and room number where students and faculty can obtain in-person technical support.
4. **Online Ticketing / Helpdesk Portal URL:** Link to the institution's student grievance redressal system or IT ticketing portal.

> [!NOTE]
> No fake telephone numbers, addresses, email accounts, or automated action buttons (`mailto:`, `tel:`) have been fabricated.

---

## 5. Automated Verification Results

### 5.1 Dart Formatting
- **Command:** `dart format lib/features/auth/presentation/screens/login_screen.dart lib/features/auth/presentation/screens/terms_and_conditions_screen.dart lib/features/auth/presentation/screens/contact_us_screen.dart lib/app/router/app_router.dart test/auth_login_legal_contact_footer_test.dart`
- **Result:** Exit code `0` (Formatted cleanly in 0.13s).

### 5.2 Flutter Static Analysis
- **Command:** `flutter analyze`
- **Result:** Zero errors found (`error • 0`). 410 pre-existing lint notices (`info • curly_braces_in_flow_control_structures` in legacy modules) retained without modification. All new and edited files have zero issues.

### 5.3 Automated Flutter Tests
- **Command:** `flutter test test/auth_login_vertical_slice_test.dart test/auth_activation_vertical_slice_test.dart test/auth_registration_screen_test.dart test/auth_password_recovery_vertical_slice_test.dart test/auth_login_legal_contact_footer_test.dart`
- **Result:** Exit code `0` — **All 63 tests passed!**

#### Detailed Test Case Summary:
1. `auth_login_legal_contact_footer_test.dart`:
   - ✓ 1. Both footer links render on initial login screen with middle dot separator (>= 44dp tap target).
   - ✓ 2. Footer links are hidden on secondary auth steps and reappear on change email.
   - ✓ 3. Terms & Conditions link navigates to dedicated in-app page with honest legal review pending status and reused content.
   - ✓ 4. Back navigation from Terms & Conditions returns to Login screen.
   - ✓ 5. Contact Us link navigates to dedicated in-app page disclosing unconfigured support channels honestly.
   - ✓ 6. Back navigation from Contact Us returns to Login screen.
   - ✓ 7. Deep links `/terms`, `/terms-and-conditions`, `/contact-us`, and `/contact` are accessible without authentication in `app_router`.
   - ✓ 8. Responsive layout renders without overflow on 360dp, 390dp, and 412dp with text scaling (1.0x, 1.15x, 1.25x).
   - ✓ 9. Virtual keyboard bottom inset (300dp) scrolls cleanly without RenderFlex overflow.
   - ✓ 10. Existing registration and activation routes remain fully functional from login.
2. `auth_login_vertical_slice_test.dart` (21 tests passed)
3. `auth_activation_vertical_slice_test.dart` (9 tests passed)
4. `auth_registration_screen_test.dart` (10 tests passed)
5. `auth_password_recovery_vertical_slice_test.dart` (13 tests passed)

### 5.4 Android Debug APK Build
- **Command:** `flutter build apk --debug`
- **Result:** Exit code `0` (`Running Gradle task 'assembleDebug'... 16.4s ✓ Built build/app/outputs/flutter-apk/app-debug.apk`).

---

## 6. Numbered Manual Checks for User

Please execute the following manual tests in your local environment or device when desired:

1. **Initial Login Footer Visibility:**
   - Launch the application: `flutter run`
   - On the initial sign-in screen, observe the footer: **Terms & Conditions · Contact Us**.
   - Verify that both links are horizontally centred and styled in muted caption typography.
2. **Navigation to Terms & Conditions:**
   - Tap **Terms & Conditions**.
   - Verify that the app transitions to `/terms` without requiring login.
   - Verify the presence of the header, the "STATUS: UNDER INSTITUTIONAL REVIEW" badge, the reused institutional notices, and the pending legal specifications list.
   - Tap the back button in the header and verify you return to the initial login screen.
3. **Navigation to Contact Us:**
   - Tap **Contact Us**.
   - Verify that the app transitions to `/contact-us` without requiring login.
   - Verify the "STATUS: SUPPORT CHANNELS UNCONFIGURED" badge and on-campus guidance for students, faculty, and administrators.
   - Confirm that no fake telephone or email links trigger unexpected action sheets.
   - Tap the back button in the header and verify you return to the initial login screen.
4. **Step-Isolated Footer Behavior:**
   - On the initial sign-in screen, enter a valid email address (e.g. `faculty@acadex.com`) and tap **Continue**.
   - Verify that on the password screen, the footer links are hidden.
   - Tap **Change** next to the email header chip.
   - Verify that returning to the welcome screen restores the footer links.
5. **Mobile Virtual Keyboard Behavior:**
   - Focus on the email input field to bring up the on-screen keyboard.
   - Verify that the layout adjusts without any `RenderFlex` overflow errors and that the footer can be scrolled to underneath the card.

---

## Status Summary

- **Implemented Functionality:**
  - Compact, accessible, responsive footer on the initial login screen.
  - Dedicated in-app `/terms` screen with full back navigation and page header.
  - Dedicated in-app `/contact-us` screen with full back navigation and page header.
  - Router integration supporting `/terms`, `/terms-and-conditions`, `/contact-us`, and `/contact` as public routes.
  - Verification test suite (10 dedicated tests, 63 total auth tests passing).
  - Verified Android debug APK build.
- **Pending Project Owner Content:**
  - Formal Master Service Agreement and Acceptable Use Policy text.
  - Verified institutional support email address, phone hotline, and campus physical office room number.
