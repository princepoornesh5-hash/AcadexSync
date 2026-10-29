# ACADEXSYNC Contact Us, AI Support, College Onboarding & Legal Consent Implementation Report

**Date:** October 28, 2026  
**Repository:** ACADEXSYNC (`Campus Management Main`)  
**Platform:** Flutter (Mobile/Web) & Node.js/TypeScript (Backend)  
**Status:** Verification Complete – All Automated Checks & Builds Passing  

---

## 1. Executive Summary & Deliverables

This implementation completes the comprehensive overhaul of the **Contact Us support hub**, **Public AI Support integration**, **College Onboarding workflow**, **15-Section Draft Terms & Conditions**, and **Server-Enforced Terms Consent Model** across ACADEXSYNC.

All implementations strictly adhere to:
- Official owner-provided contact details without fabricated addresses, coordinates, or fake hours.
- Multi-tenant data isolation and public visitor privacy guards blocking unauthorized access to student records or marks.
- Authoritative Indian legal statutes: Digital Personal Data Protection Act (DPDPA), 2023, Digital Personal Data Protection Rules, 2025, and Consumer Protection Act, 2019.
- Cryptographically verified, server-side consent persistence preventing premature workspace membership creation without affirmative terms acceptance.
- Zero breaking changes to existing OTP delivery, multi-step activation, or login flows.

---

## 2. Files Changed & Key Implementation Decisions

### Backend Architecture (`Backend/`)
| File | Action | Key Implementation Decisions |
| :--- | :--- | :--- |
| `Backend/src/models/user.model.ts` | Modified | Added `termsAccepted: boolean`, `termsAcceptedVersion?: string`, and `termsAcceptedAt?: Date` to `IUser` interface and `UserSchema`. |
| `Backend/src/services/auth.service.ts` | Modified | Updated `registerComplete` to enforce `termsAccepted === true` before user creation; added `acceptTerms` and `getTermsStatus` services with audit logging. |
| `Backend/src/services/activation.service.ts` | Modified | Enforced `termsAccepted === true` in `completeActivation` and `completeInstitutionalActivation` immediately after cryptographic token verification, preventing any database mutation or invitation consumption without explicit consent. |
| `Backend/src/controllers/auth.controller.ts` | Modified | Forwarded terms acceptance parameters in registration; added `acceptTerms` and `getTermsStatus` controller methods. |
| `Backend/src/controllers/activation.controller.ts` | Modified | Validated `termsAccepted` payload parameters for both token-based and email-first activation requests. |
| `Backend/src/routes/v1/auth.routes.ts` | Modified | Registered `POST /api/v1/auth/terms/accept` and `GET /api/v1/auth/terms/status` routes under `authenticateRequest`. |
| `Backend/src/routes/v1/ai.routes.ts` | Modified | Registered `POST /api/v1/ai/public-chat` **prior** to authentication middleware, guarded by dedicated IP rate limiter `publicAiRateLimiter` (20 req/min). |
| `Backend/src/controllers/ai.controller.ts` | Modified | Added `AiController.publicChat` handling unauthenticated visitors. |
| `Backend/src/services/ai.service.ts` | Modified | Implemented `generatePublicSupportResponse` using Gemini `gemini-2.5-flash` with zero tools (`tools: []`), strict privacy filtering (`security-privacy-guard`), and deterministic fallback `getCuratedSupportAnswer`. |
| `Backend/tests/unit/public_support_and_terms_consent.test.ts` | Created | 9 unit tests verifying suggested question answering, sensitive query rejection, server-side terms rejection, and authenticated terms status. |
| `Backend/tests/integration/email_otp_auth_flow.test.ts` | Modified | Updated integration test payloads to supply `termsAccepted: true` and verified end-to-end activation. |

### Frontend Architecture (`Frontend/`)
| File | Action | Key Implementation Decisions |
| :--- | :--- | :--- |
| `Frontend/lib/features/auth/presentation/screens/contact_us_screen.dart` | Redesigned | Comprehensive support hub with verified contact cards, phone dialer/email launcher actions, copy fallbacks, "Ask ACADEXSYNC AI" section with 6 suggested question chips, interactive expandable FAQ accordion, and "Register Your College" onboarding dialog. |
| `Frontend/lib/features/auth/presentation/screens/terms_and_conditions_screen.dart` | Redesigned | Comprehensive 15-section draft institutional terms screen with Indian legal research citations, expandable section cards, expand/collapse all controls, and honest pending-review status badge. |
| `Frontend/lib/features/auth/presentation/widgets/terms_acceptance_checkbox.dart` | Created | Accessible, initially unchecked checkbox with inline navigation links to `/terms`. |
| `Frontend/lib/features/auth/presentation/screens/registration_screen.dart` | Modified | Integrated `TermsAcceptanceCheckbox` into Step 3 password completion; submit button disabled until checked; sends `termsAccepted: true, termsVersion: '2026.1-draft'`. |
| `Frontend/lib/features/auth/presentation/screens/activation_screen.dart` | Modified | Integrated `TermsAcceptanceCheckbox` into Step 5 (Code-First) and Step 3 (Email-First); submit disabled until checked; sends terms parameters to activation repository. |
| `Frontend/lib/features/ai_assistant/domain/repositories/ai_repository.dart` | Modified | Added `Future<AiResponse> sendPublicSupportQuery({required String query, List<Map<String, String>>? history})`. |
| `Frontend/lib/features/ai_assistant/data/repositories/api_ai_repository.dart` | Modified | Implemented `sendPublicSupportQuery` calling `/ai/public-chat`. |
| `Frontend/lib/features/ai_assistant/data/repositories/mock_ai_repository.dart` | Modified | Implemented mock public support query response. |
| `Frontend/lib/features/ai_assistant/data/repositories/firebase_ai_repository.dart` | Modified | Added public support query stub for Firebase parity. |
| `Frontend/lib/features/auth/domain/repositories/activation_repository.dart` | Modified | Added `termsAccepted` and `termsVersion` to `completeActivation`. |
| `Frontend/lib/features/auth/data/repositories/api_activation_repository.dart` | Modified | Forwarded terms parameters to activation completion endpoint. |
| `Frontend/lib/features/auth/repositories/auth_repository.dart` & `api_auth_repository.dart` | Modified | Added `termsAccepted` and `termsVersion` to `completeRegistration` and `completeInstitutionalActivation`. |
| `Frontend/lib/features/auth/presentation/providers/activation_providers.dart` & `auth_provider.dart` | Modified | Updated provider handlers to pass terms acceptance. |
| `Frontend/test/contact_us_ai_support_and_terms_consent_test.dart` | Created | 7 widget and integration tests covering contacts, AI query handling, FAQ expansion, college onboarding validation/email generation, terms draft sections, and terms checkbox. |
| `Frontend/test/auth_login_legal_contact_footer_test.dart` | Modified | Updated 10 tests to verify redesigned Terms and Contact Us pages, footer navigation, and responsive scaling. |
| `Frontend/test/ai_streaming_chat_test.dart` | Modified | Updated branding assertions for ACADEXSYNC. |

---

## 3. Existing AI Integration Reused & Security Restrictions

### Architecture
- **Service Reused:** `AiService` in `Backend/src/services/ai.service.ts` using Google Generative AI SDK (`@google/genai`, model: `gemini-2.5-flash`).
- **Endpoint:** `POST /api/v1/ai/public-chat` placed **before** the tenant and authentication middleware chain.
- **Rate Limiting:** Dedicated `publicAiRateLimiter` enforces a strict ceiling of **20 requests per minute per IP**, returning HTTP `429 Too Many Requests` on abuse.

### Public Privacy Guard & Zero-Tool Execution
- **Zero Tools (`tools: []`):** Unlike the authenticated assistant which uses tool declarations (`list_students`, `get_attendance_summary`, `get_course_details`), the public support handler provides zero tools. It has no capability to query MongoDB or access runtime database models.
- **Privacy Guard Pattern Matching:** Input queries are screened before processing. Any query matching sensitive patterns (`marks`, `grade`, `attendance`, `student list`, `faculty record`, `transcript`, `secret`, `api key`, `token`) is immediately intercepted and blocked:
  ```json
  {
    "success": true,
    "data": {
      "answer": "Privacy Notice: Public visitor queries cannot access personal student records, attendance logs, or confidential grades. Please log in with your institutional credentials to access your academic dashboard.",
      "category": "security-privacy-guard"
    }
  }
  ```
- **Curated Fallback:** If the external Gemini API is unreachable or rate-limited by upstream quotas, `AiService.getCuratedSupportAnswer` provides accurate, deterministic answers for all suggested support questions without failing or leaking internal system logs.

### 6 Standard Suggested Question Chips
1. *"How do I activate my account?"*
2. *"How do I sign in using email OTP?"*
3. *"How can my college register?"*
4. *"How do I reset my password?"*
5. *"What can ACADEXSYNC do for my institution?"*
6. *"How do I report a technical problem?"*

---

## 4. Contact Details Used

Owner-provided details are rendered consistently across the Contact Us screen:
- **Phone:** `+91 8686633340`
  - Action: Launches native dialer (`tel:+918686633340`).
  - Fallback: Copies number to clipboard with feedback SnackBar.
- **Email:** `ragoorupoornesh@gmail.com`
  - Action: Launches default mail app (`mailto:ragoorupoornesh@gmail.com?subject=ACADEXSYNC%20Support%20%26%20General%20Inquiry`).
  - Fallback: Copies email address to clipboard with feedback SnackBar.
- **Location:** `Nehru Nagar, Tirupati, Andhra Pradesh, India`
  - Action: Clean card display and copy-to-clipboard action.
  - Strict Compliance: **No street addresses, map pins, or fake business hours were invented.**

---

## 5. FAQ Content Sources

The FAQ section provides a curated, expandable list based strictly on verified system behavior:
1. **Account Activation:** Details Code-First (8-character code) and Email-First paths, 4-step identity confirmation, two-factor email OTP validation, and password setup.
2. **Email OTP Authentication:** Explains 6-digit one-time passcodes, 5-minute expiration, 60-second resend cooldown, and the 5-attempt brute-force protection limit.
3. **Institutional Roles & RBAC:** Outlines permissions across Super Admin, College Admin, HOD, Faculty, and Student.
4. **Password Recovery:** Details self-service password reset using verified institutional email addresses and OTP verification.
5. **College Onboarding:** Explains how administrators request institutional tenancy, database provisioning, and demo accounts.
6. **Technical Troubleshooting:** Guides users on resolving email delivery delays (spam checks, cooldowns) and escalating unresolvable account lockouts to administration.

Each FAQ item includes an **"Ask AI More"** button that automatically routes the topic directly into the AI support prompt.

---

## 6. College Onboarding Email Format & Actions

### In-App Modal Form Fields
- **College / Institution Name** (Required, validated non-empty)
- **Campus Location & State** (Required, validated non-empty)
- **Administrator's Name** (Required, validated non-empty)
- **Administrator's Designation** (Required, validated non-empty)
- **Official Email** (Required, validated email regex format)
- **Phone Number** (Optional)
- **Estimated Student Enrollment** (Default: `1,000 - 3,000`)
- **Estimated Faculty Count** (Default: `50 - 150`)
- **Required Modules / Use Cases** (Multi-select filter chips: Attendance & Timetable, Grading & Marks, AI Assistant Hub, Faculty Management, Student Portal, Department Analytics)
- **Preferred Demonstration Schedule** (Default: `Next available working day`)
- **Additional Institutional Notes** (Optional)

### Generated Email Specifications
- **Recipient:** `ragoorupoornesh@gmail.com`
- **Subject:** `ACADEXSYNC Institutional Onboarding Request – [College Name]`
- **Body Format:**
  ```text
  Dear ACADEXSYNC Institutional Onboarding Team,

  I would like to request institutional onboarding and a scheduled demonstration of the ACADEXSYNC campus management system.

  1. Institution Overview:
  • Institution Name: [College Name]
  • Campus Location & State: [Location and State]
  • Estimated Student Enrollment: [Student Count]
  • Estimated Faculty Count: [Faculty Count]

  2. Primary Administrator Contact:
  • Full Name: [Admin Name]
  • Designation / Title: [Designation]
  • Official Email: [Official Email]
  • Phone Number: [Phone Number]

  3. Desired Modules & Use Cases:
  • [Selected Modules]

  4. Preferred Demonstration Schedule:
  • [Preferred Schedule]

  5. Additional Institutional Requirements & Notes:
  • [Notes]

  Please contact us to discuss institutional deployment, trial provisioning, and departmental onboarding.

  Sincerely,
  [Admin Name]
  [Designation]
  [College Name]
  ```
- **Actions:**
  - **"Compose Email":** Encodes mailto URI via `Uri(scheme: 'mailto', path: 'ragoorupoornesh@gmail.com', queryParameters: {...})` and launches native client.
  - **"Copy Email Draft":** Copies full email draft to clipboard with instant user notification.
- **Transparency Notice:** Explicitly informs users: *"Note: Composing or opening the email draft does not automatically register the college. Onboarding is established after institutional verification."*

---

## 7. Official Indian Legal Research & Draft Terms Caveats

### Authoritative Statutory Citations
1. **Digital Personal Data Protection Act, 2023 (DPDPA 2023):**
   - Official Source: [MeitY DPDPA 2023 PDF](https://www.meity.gov.in/static/uploads/2024/02/Digital-Personal-Data-Protection-Act-2023.pdf)
   - Phased Commencement Analysis: Under Section 1(3), the Act comes into force on dates appointed by the Central Government via official notifications, with different provisions potentially commencing at different times.
   - Core Principles Incorporated:
     - Lawful purpose and explicit consent / legitimate use (Section 4).
     - Obligations of Data Fiduciary (Section 8) – Participating colleges act as Data Fiduciaries; ACADEXSYNC operates as Data Processor.
     - Reasonable security safeguards and technical safeguards (Section 8(5)).
     - Rights of Data Principals (Sections 11–14) – Right to access summaries, right to correction/erasure, right of grievance redressal.
2. **Digital Personal Data Protection Rules, 2025:**
   - Official Source: [MeitY DPDP Rules 2025](https://www.meity.gov.in/static/uploads/2025/11/53450e6e5dc0bfa85ebd78686cadad39.pdf)
   - Standards on data breach reporting mechanisms, notice formats, and verifiable consent architectures.
3. **Consumer Protection Act, 2019 (CPA 2019):**
   - Official Source: [Consumer Affairs Consumer Protection Acts](https://consumeraffairs.gov.in/pages/consumer-protection-acts)
   - Application to Cloud Software: Consumer statutory rights against deficiency of service cannot be lawfully excluded through blanket one-sided terms.

### 15 Draft Terms Sections Implemented
1. **Purpose & Scope of ACADEXSYNC**
2. **Account Registration, Activation & Security**
3. **Institutional Roles & Permissions (RBAC)**
4. **Acceptable Use & Prohibited Activities**
5. **Institutional Responsibility for Access & Supplied Data**
6. **Academic Records, Attendance & Data Accuracy**
7. **Privacy, Personal-Data Processing & Rights (DPDPA 2023)**
8. **Service Availability, Sync Delays & Maintenance**
9. **Data Backup, Retention, Export & Recovery**
10. **AI Assistant Limitations & Mandatory Verification**
11. **Third-Party Services & Infrastructure (Resend, Cloud Hosting)**
12. **Suspension, Termination & Offboarding**
13. **Support & Grievance Redressal Procedure (`ragoorupoornesh@gmail.com`)**
14. **Changes to Terms & Version History (v2026.1-draft)**
15. **Applicable Law & Reasonable Liability Limitations**

### Critical Caveats & Disclaimers
- **Draft Status:** Clearly designated with warning badge: `DRAFT VERSION: 2026.1-draft (Subject to Formal Owner & Legal Counsel Review)`.
- **System Realities:** Explicitly notes that software may experience scheduled maintenance windows, background data-sync delays, and third-party delivery latency.
- **AI Limitations:** Explicitly warns that AI outputs are informational summaries; students and faculty must independently verify official grades and academic announcements through departmental channels.
- **Balanced Liability:** Avoids unlawful blanket clauses ("ACADEXSYNC is never responsible for anything"). Outlines reasonable liability limitations aligned with Indian contract and consumer jurisprudence.

---

## 8. Terms Consent Model, Endpoint & Migration Requirements

### Database Schema Changes
In `Backend/src/models/user.model.ts`:
```typescript
export interface IUser extends Document {
  // Existing fields...
  termsAccepted: boolean;
  termsAcceptedVersion?: string;
  termsAcceptedAt?: Date;
}

const UserSchema = new Schema<IUser>({
  // Existing schema...
  termsAccepted: { type: Boolean, default: false },
  termsAcceptedVersion: { type: String, required: false },
  termsAcceptedAt: { type: Date, required: false }
});
```

### Server-Side Enforcement Flow
1. **Self-Registration (`/api/v1/auth/register/complete`):**
   - Validates `termsAccepted === true`.
   - If false/omitted, immediately throws `400 Bad Request`: *"You must review and accept the Terms & Conditions and Privacy Policy to create an account."*
   - Stores `termsAccepted: true`, `termsAcceptedVersion: '2026.1-draft'`, and `termsAcceptedAt: new Date()` on the created `User`.
2. **Account Activation (`/api/v1/auth/activate/complete`):**
   - Cryptographically verifies activation completion token.
   - Validates `termsAccepted === true`.
   - Enforces terms before consuming invitation or establishing college membership.
3. **Institutional Activation (`/api/v1/auth/institutional-activate/complete`):**
   - Verifies email token and activation code.
   - Enforces `termsAccepted === true` before updating user password or binding roles.
4. **Consent Recording API:**
   - `POST /api/v1/auth/terms/accept`: Allows authenticated users to record explicit acceptance of new terms versions.
   - `GET /api/v1/auth/terms/status`: Returns current consent status, version, and acceptance timestamp.

### Migration & Deployment Requirements
- **Non-Breaking Schema:** Existing user records without `termsAccepted` default to `false` in MongoDB without requiring a breaking database migration.
- **Re-Consent Workflow:** Existing active sessions remain functional; institutional administrators can configure an in-app prompt requiring users to accept `2026.1-draft` upon their next session refresh.
- **Production Guard:** No production data was modified. No live database migration scripts were executed.

---

## 9. Automated Verification & Test Results

### 1. Backend Static Analysis & Typecheck
- **Command:** `npm run typecheck`
- **Result:** Exited with code `0` (Zero TypeScript compilation errors).

### 2. Backend Automated Test Suites
- **Unit Test Suite:** `Backend/tests/unit/public_support_and_terms_consent.test.ts`
  - 9 tests passed out of 9 total.
  - Verified: suggested questions answering, sensitive query privacy guard, server-side registration rejection without consent, server-side activation rejection without consent, and authenticated terms status retrieval.
- **Integration Test Suite:** `Backend/tests/integration/email_otp_auth_flow.test.ts`
  - 22 tests passed out of 22 total.
  - Verified: complete OTP flow, passwordless login, self-registration with terms, institutional activation with terms, and cross-tenant isolation.

### 3. Frontend Formatting & Static Analysis
- **Command:** `dart format --output=none --set-exit-if-changed`
  - Formatted all 7 modified files cleanly with zero syntax violations.
- **Command:** `flutter analyze lib/features/auth lib/features/ai_assistant`
  - Exited with code `0` (Zero compilation errors, zero warnings).

### 4. Frontend Automated Test Suites
- **New Support & Consent Suite:** `Frontend/test/contact_us_ai_support_and_terms_consent_test.dart`
  - 7 tests passed out of 7 total:
    1. Displays exact owner contact details and verified contact cards.
    2. Suggested questions trigger AI assistant with loading and response display.
    3. Custom query input and error retry state work reliably.
    4. FAQ cards expand and allow routing question to AI assistant.
    5. College onboarding dialog enforces validation and formats email draft.
    6. Terms & Conditions displays draft status, legal research citations, and 15 sections.
    7. TermsAcceptanceCheckbox is initially unchecked and updates on tap.
- **Footer & Navigation Regression Suite:** `Frontend/test/auth_login_legal_contact_footer_test.dart`
  - 10 tests passed out of 10 total:
    - Footer links rendering, middle dot separator, deep links (`/terms`, `/contact-us`), back navigation, responsive scaling (360dp, 390dp, 412dp), virtual keyboard inset (300dp), and existing auth routes.
- **AI Assistant Streaming Suite:** `Frontend/test/ai_streaming_chat_test.dart`
  - 9 tests passed out of 9 total.

### 5. Android Debug Build
- **Command:** `flutter build apk --debug`
- **Result:** Build succeeded in **15.2 seconds**:
  ```text
  Running Gradle task 'assembleDebug'... 15.2s
  ✓ Built build/app/outputs/flutter-apk/app-debug.apk
  ```

---

## 10. Missing Owner Decisions & Numbered Manual Checks

### Missing Decisions Requiring Project Owner Action
1. **Legal Counsel Review:** The 15 draft sections in `terms_and_conditions_screen.dart` provide a complete institutional baseline aligned with DPDPA 2023, DPDP Rules 2025, and CPA 2019. The project owner must have legal counsel formally review and approve the text before removing the `DRAFT VERSION: 2026.1-draft` badge.
2. **Re-Consent Policy for Existing Users:** Determine whether existing active institutional users must be presented with a blocking modal dialog to accept the new terms on their next login or if an informative in-app banner is sufficient.
3. **Helpline Operating Hours:** If telephone inquiries should be constrained to specific working hours (e.g. 9:00 AM – 6:00 PM IST Monday through Friday), provide the schedule to be displayed alongside `+91 8686633340`.

### Numbered Manual Checks for the Project Owner
1. **Verify Contact Actions on Mobile Device:**
   - Tap **"Call Now"** on the telephone card to ensure your mobile dialer opens pre-populated with `+91 8686633340`.
   - Tap **"Send Email"** on the email card to confirm your default email app opens with a draft addressed to `ragoorupoornesh@gmail.com`.
   - Tap the copy button on the location card to verify that `Nehru Nagar, Tirupati, Andhra Pradesh, India` is copied to the clipboard.
2. **Test AI Support Chips & Privacy Guard:**
   - On the Contact Us screen, tap the chip *"How do I activate my account?"* and confirm that instant guidance is rendered.
   - Enter *"What are the marks of student 101?"* into the query box and verify that the Privacy Guard blocks access with the institutional notice.
3. **Test College Onboarding Flow:**
   - Tap **"Register Your College"** and submit an empty form to observe field validation.
   - Fill in your institution's details and tap **"Copy Email Draft"**; confirm that the SnackBar appears and the structured request is copied to your clipboard.
   - Tap **"Compose Email"** and confirm that your mail application opens with the subject `ACADEXSYNC Institutional Onboarding Request – [College Name]`.
4. **Test Terms & Conditions Checkbox in Registration & Activation:**
   - Navigate to `/register` and proceed to Step 3. Verify that the checkbox is initially unchecked and the "Create Account" button is disabled until checked.
   - Tap the inline *"Terms & Conditions"* link to verify that the 15-section terms page opens, and back navigation safely returns you to the form without losing your entered data.
