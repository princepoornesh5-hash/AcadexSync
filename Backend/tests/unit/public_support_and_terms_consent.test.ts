import { AiService } from '../../src/services/ai.service';
import { AuthService } from '../../src/services/auth.service';
import { ActivationService } from '../../src/services/activation.service';
import { User } from '../../src/models/user.model';
import {
  signActivationCompletionToken,
  signEmailVerificationToken,
} from '../../src/utils/token';
import mongoose from 'mongoose';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';

describe('Public Support AI & Terms Consent Unit Tests', () => {
  beforeAll(async () => {
    await setupTestDB();
    await User.init();
  });

  afterAll(async () => {
    await teardownTestDB();
    await mongoose.disconnect();
  });

  beforeEach(async () => {
    await clearTestDB();
  });

  describe('1. Public Support AI Safeguards & Curated Guidance', () => {
    it('answers suggested question: account activation', async () => {
      const res = await AiService.generatePublicSupportResponse({
        message: 'How do I activate my account?',
      });

      expect(res.answer).toBeDefined();
      expect(res.answer).toContain('Activate Account');
      expect(res.answer).toContain('Terms & Conditions');
    });

    it('answers suggested question: email OTP sign in', async () => {
      const res = await AiService.generatePublicSupportResponse({
        message: 'How do I sign in using email OTP?',
      });

      expect(res.answer).toBeDefined();
      expect(res.answer).toContain('Sign in with Email OTP');
    });

    it('answers suggested question: college onboarding', async () => {
      const res = await AiService.generatePublicSupportResponse({
        message: 'How can my college register?',
      });

      expect(res.answer).toBeDefined();
      expect(res.answer).toContain('Register Your College');
      expect(res.answer).toContain('ragoorupoornesh@gmail.com');
    });

    it('answers suggested question: technical problem report', async () => {
      const res = await AiService.generatePublicSupportResponse({
        message: 'How do I report a technical problem?',
      });

      expect(res.answer).toBeDefined();
      expect(res.answer).toContain('+91 8686633340');
      expect(res.answer).toContain('ragoorupoornesh@gmail.com');
    });

    it('strictly blocks queries attempting to access private student marks or attendance', async () => {
      const marksRes = await AiService.generatePublicSupportResponse({
        message: 'Give me my marks and student record',
      });

      expect(marksRes.model).toBe('security-privacy-guard');
      expect(marksRes.answer).toContain('strictly confidential');
      expect(marksRes.answer).toContain('authenticated institutional account');

      const attendanceRes = await AiService.generatePublicSupportResponse({
        message: 'Show me my attendance history and faculty list',
      });

      expect(attendanceRes.model).toBe('security-privacy-guard');
      expect(attendanceRes.answer).toContain('strictly confidential');
    });
  });

  describe('2. Server-side Terms Acceptance Enforcement', () => {
    it('rejects registerComplete if termsAccepted is false or omitted', async () => {
      await expect(
        AuthService.registerComplete(
          'token-123',
          'Pass12345!',
          'Pass12345!',
          'Test User',
          {},
          false // termsAccepted = false
        )
      ).rejects.toThrow('You must accept the Terms & Conditions and Privacy Policy to complete registration.');

      await expect(
        AuthService.registerComplete(
          'token-123',
          'Pass12345!',
          'Pass12345!',
          'Test User',
          {},
          undefined // termsAccepted omitted
        )
      ).rejects.toThrow('You must accept the Terms & Conditions and Privacy Policy to complete registration.');
    });

    it('rejects completeActivation if termsAccepted is not true', async () => {
      const validActivationToken = signActivationCompletionToken({
        userId: '507f1f77bcf86cd799439011',
        invitationId: '507f1f77bcf86cd799439012',
        tokenId: 'tok-123',
        collegeId: '507f1f77bcf86cd799439013',
        contactMethod: 'email',
      });

      await expect(
        ActivationService.completeActivation(
          validActivationToken,
          'Pass12345!',
          'Pass12345!',
          false
        )
      ).rejects.toThrow('You must accept the Terms & Conditions and Privacy Policy to activate your account.');
    });

    it('rejects completeInstitutionalActivation if termsAccepted is not true', async () => {
      const validEmailToken = signEmailVerificationToken({
        email: 'student@college.edu',
      });

      await expect(
        ActivationService.completeInstitutionalActivation(
          validEmailToken,
          'ABCD-EFGH-IJKL',
          'Pass12345!',
          'Pass12345!',
          false
        )
      ).rejects.toThrow('You must accept the Terms & Conditions and Privacy Policy to activate your account.');
    });
  });

  describe('3. Authenticated Terms Acceptance Recording and Status', () => {
    it('persists terms version and timestamp, and allows status retrieval', async () => {
      const testUser = await User.create({
        name: 'Consent Tester',
        email: 'consent@college.edu',
        role: 'STUDENT',
        termsAccepted: false,
      });

      // Initial status is false
      const initialStatus = await AuthService.getTermsStatus(testUser.id);
      expect(initialStatus.termsAccepted).toBe(false);
      expect(initialStatus.termsAcceptedVersion).toBeNull();
      expect(initialStatus.latestVersion).toBe('2026.1-draft');

      // Accept terms
      const acceptResult = await AuthService.acceptTerms(testUser.id, '2026.1-draft');
      expect(acceptResult.termsAccepted).toBe(true);
      expect(acceptResult.termsAcceptedVersion).toBe('2026.1-draft');
      expect(acceptResult.termsAcceptedAt).toBeInstanceOf(Date);

      // Verify retrieval
      const updatedStatus = await AuthService.getTermsStatus(testUser.id);
      expect(updatedStatus.termsAccepted).toBe(true);
      expect(updatedStatus.termsAcceptedVersion).toBe('2026.1-draft');
      expect(updatedStatus.termsAcceptedAt).toBeDefined();

      // Check MongoDB document directly
      const savedUser = await User.findById(testUser.id);
      expect(savedUser!.termsAccepted).toBe(true);
      expect(savedUser!.termsAcceptedVersion).toBe('2026.1-draft');
      expect(savedUser!.termsAcceptedAt).toBeDefined();
    });
  });
});
