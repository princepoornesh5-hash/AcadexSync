import { EmailService } from '../../src/services/email.service';
import { renderOtpEmail } from '../../src/services/emailTemplates';
import { EmailDeliveryAdapter, OtpDeliveryService } from '../../src/services/otpDelivery.service';
import { OtpPurpose, OtpDeliveryMethod } from '../../src/constants/status';
import { Logger } from '../../src/utils/logger';
import { env } from '../../src/config/env';

describe('ACADEXSYNC Phase 1: Resend Email Delivery Service Unit Tests', () => {
  const originalApiKey = env.RESEND_API_KEY;

  beforeEach(() => {
    // Reset client instance and API key to default state before each test
    EmailService.setClient(null);
  });

  afterAll(() => {
    // Restore original config
    (env as any).RESEND_API_KEY = originalApiKey;
    EmailService.setClient(null);
  });

  describe('1. Configuration & Safe Fallback', () => {
    it('1.1 isConfigured() returns false when RESEND_API_KEY is not set', () => {
      (env as any).RESEND_API_KEY = undefined;
      EmailService.setClient(null);
      expect(EmailService.isConfigured()).toBe(false);
    });

    it('1.2 sendEmail returns clear operational error without pretending email was sent when unconfigured', async () => {
      (env as any).RESEND_API_KEY = '';
      EmailService.setClient(null);

      const result = await EmailService.sendEmail({
        to: 'student@example.edu',
        subject: 'Test Subject',
        text: 'Test message body',
      });

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('PROVIDER_NOT_CONFIGURED');
      expect(result.error).toContain('RESEND_API_KEY is missing');
      expect(result.messageId).toBeUndefined();
    });

    it('1.3 isConfigured() returns true when client is injected or RESEND_API_KEY is provided', () => {
      (env as any).RESEND_API_KEY = 're_test_mock_api_key_1234567890';
      EmailService.setClient(null);
      expect(EmailService.isConfigured()).toBe(true);

      // Also true when mock client is set
      (env as any).RESEND_API_KEY = undefined;
      const mockClient = { emails: { send: jest.fn() } } as any;
      EmailService.setClient(mockClient);
      expect(EmailService.isConfigured()).toBe(true);
    });
  });

  describe('2. Delivery Handling with Mocked Resend Provider', () => {
    it('2.1 Successfully dispatches email and returns messageId', async () => {
      const mockSend = jest.fn().mockResolvedValue({
        data: { id: 'msg_resend_mock_success_123' },
        error: null,
      });
      const mockClient = { emails: { send: mockSend } } as any;
      EmailService.setClient(mockClient);

      const result = await EmailService.sendEmail({
        to: 'recipient@test.edu',
        subject: 'Welcome to ACADEXSYNC',
        html: '<p>Welcome</p>',
        text: 'Welcome',
      });

      expect(result.success).toBe(true);
      expect(result.messageId).toBe('msg_resend_mock_success_123');
      expect(result.error).toBeUndefined();

      expect(mockSend).toHaveBeenCalledTimes(1);
      const callArg = mockSend.mock.calls[0][0];
      expect(callArg.to).toEqual(['recipient@test.edu']);
      expect(callArg.subject).toBe('Welcome to ACADEXSYNC');
      expect(callArg.html).toBe('<p>Welcome</p>');
      expect(callArg.text).toBe('Welcome');
      expect(callArg.from).toContain('onboarding@resend.dev');
    });

    it('2.2 Handles provider validation error safely', async () => {
      const mockSend = jest.fn().mockResolvedValue({
        data: null,
        error: {
          name: 'validation_error',
          message: 'The recipient address is not allowed on free test plan',
        },
      });
      const mockClient = { emails: { send: mockSend } } as any;
      EmailService.setClient(mockClient);

      const result = await EmailService.sendEmail({
        to: 'unverified@example.com',
        subject: 'Verification Code',
        text: 'Code: 123456',
      });

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('validation_error');
      expect(result.error).toContain('The recipient address is not allowed on free test plan');
      expect(result.messageId).toBeUndefined();
    });

    it('2.3 Handles provider network timeout or unexpected exception safely', async () => {
      const mockSend = jest.fn().mockRejectedValue(new Error('Resend email delivery timed out after 10000ms'));
      const mockClient = { emails: { send: mockSend } } as any;
      EmailService.setClient(mockClient);

      const result = await EmailService.sendEmail({
        to: 'student@test.edu',
        subject: 'OTP Verification',
        text: 'Code: 654321',
      });

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('PROVIDER_DISPATCH_ERROR');
      expect(result.error).toContain('timed out');
    });
  });

  describe('3. Sender Address & Input Validation', () => {
    it('3.1 Rejects sender address containing CRLF header injection', async () => {
      const mockSend = jest.fn();
      EmailService.setClient({ emails: { send: mockSend } } as any);

      const result = await EmailService.sendEmail({
        to: 'victim@test.edu',
        from: 'attacker@resend.dev\r\nBcc: spy@evil.com',
        subject: 'Spoofed Header',
        text: 'Message',
      });

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('INVALID_SENDER');
      expect(result.error).toContain('Header injection characters');
      expect(mockSend).not.toHaveBeenCalled();
    });

    it('3.2 Rejects unauthorized sender domain that does not match configured sender domain', async () => {
      const mockSend = jest.fn();
      EmailService.setClient({ emails: { send: mockSend } } as any);

      const result = await EmailService.sendEmail({
        to: 'student@test.edu',
        from: 'admin@unauthorized-spoofed-domain.com',
        subject: 'Unauthorized Domain Test',
        text: 'Message',
      });

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('INVALID_SENDER');
      expect(result.error).toContain('Unauthorized sender domain');
      expect(mockSend).not.toHaveBeenCalled();
    });

    it('3.3 Rejects empty recipient address', async () => {
      const mockSend = jest.fn();
      EmailService.setClient({ emails: { send: mockSend } } as any);

      const result = await EmailService.sendEmail({
        to: '',
        subject: 'Subject',
        text: 'Message',
      });

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('EMPTY_RECIPIENT');
      expect(mockSend).not.toHaveBeenCalled();
    });

    it('3.4 Rejects empty subject or empty email body', async () => {
      const mockSend = jest.fn();
      EmailService.setClient({ emails: { send: mockSend } } as any);

      const emptySubjectResult = await EmailService.sendEmail({
        to: 'user@test.edu',
        subject: '   ',
        text: 'Message',
      });
      expect(emptySubjectResult.errorCode).toBe('EMPTY_SUBJECT');

      const emptyBodyResult = await EmailService.sendEmail({
        to: 'user@test.edu',
        subject: 'Valid Subject',
      });
      expect(emptyBodyResult.errorCode).toBe('EMPTY_BODY');
      expect(mockSend).not.toHaveBeenCalled();
    });
  });

  describe('4. ACADEXSYNC-Branded OTP Email Template', () => {
    it('4.1 Renders clean responsive HTML and plain text for ACCOUNT_ACTIVATION', () => {
      const rendered = renderOtpEmail({
        otp: '849201',
        purpose: OtpPurpose.ACCOUNT_ACTIVATION,
        recipientEmail: 'newuser@college.edu',
        expiryMinutes: 10,
      });

      expect(rendered.subject).toBe('ACADEXSYNC - Verification Code for Account Activation');
      expect(rendered.html).toContain('849201');
      expect(rendered.html).toContain('Activate Your Account');
      expect(rendered.html).toContain('Expires in 10 minutes');
      expect(rendered.html).toContain('Security Notice');
      expect(rendered.html).toContain('ignore this email');
      expect(rendered.html).toContain('ACADEXSYNC');

      expect(rendered.text).toContain('849201');
      expect(rendered.text).toContain('Valid for: 10 minutes');
      expect(rendered.text).toContain('SECURITY NOTICE');
      expect(rendered.text).toContain('ignore this');
    });

    it('4.2 Renders template for PASSWORD_RESET with appropriate context', () => {
      const rendered = renderOtpEmail({
        otp: '123456',
        purpose: OtpPurpose.PASSWORD_RESET,
        expiryMinutes: 5,
      });

      expect(rendered.subject).toBe('ACADEXSYNC - Password Reset Verification Code');
      expect(rendered.html).toContain('Reset Your Password');
      expect(rendered.html).toContain('123456');
      expect(rendered.html).toContain('Expires in 5 minutes');
    });

    it('4.3 sendOtpEmail dispatches correctly through EmailService', async () => {
      const mockSend = jest.fn().mockResolvedValue({
        data: { id: 'msg_otp_sent_789' },
        error: null,
      });
      EmailService.setClient({ emails: { send: mockSend } } as any);

      const result = await EmailService.sendOtpEmail({
        to: 'student@college.edu',
        otp: '998877',
        purpose: OtpPurpose.ACCOUNT_ACTIVATION,
      });

      expect(result.success).toBe(true);
      expect(result.messageId).toBe('msg_otp_sent_789');
      expect(mockSend).toHaveBeenCalledTimes(1);
      const call = mockSend.mock.calls[0][0];
      expect(call.html).toContain('998877');
      expect(call.text).toContain('998877');
    });
  });

  describe('5. Sensitive Data Protection & Logger Sanitization', () => {
    it('5.1 Logger.maskEmail masks local part of recipient address', () => {
      expect(Logger.maskEmail('poornesh@example.com')).toBe('p***h@example.com');
      expect(Logger.maskEmail('ab@college.edu')).toBe('a***@college.edu');
      expect(Logger.maskEmail('')).toBe('***');
      expect(Logger.maskEmail('invalid-email')).toBe('***');
    });

    it('5.2 Logger.sanitize redacts Resend API keys from log strings and objects', () => {
      const sampleLog = 'Connecting with apiKey: re_1234567890abcdef12345678 and RESEND_API_KEY=re_abcdefghij123456789012';
      const sanitized = Logger.sanitize(sampleLog);

      expect(sanitized).not.toContain('re_1234567890abcdef12345678');
      expect(sanitized).not.toContain('re_abcdefghij123456789012');
      expect(sanitized).toContain('***');
    });
  });

  describe('6. EmailDeliveryAdapter & OtpDeliveryService Integration', () => {
    it('6.1 EmailDeliveryAdapter fails safely when EmailService is not configured', async () => {
      (env as any).RESEND_API_KEY = '';
      EmailService.setClient(null);

      const adapter = new EmailDeliveryAdapter();
      const delivered = await adapter.sendOtp({
        destination: 'test@college.edu',
        otp: '112233',
        purpose: OtpPurpose.ACCOUNT_ACTIVATION,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
      });

      expect(delivered).toBe(false);
    });

    it('6.2 EmailDeliveryAdapter succeeds when EmailService dispatches successfully', async () => {
      const mockSend = jest.fn().mockResolvedValue({
        data: { id: 'msg_adapter_ok' },
        error: null,
      });
      EmailService.setClient({ emails: { send: mockSend } } as any);

      const adapter = new EmailDeliveryAdapter();
      const delivered = await adapter.sendOtp({
        destination: 'test@college.edu',
        otp: '654321',
        purpose: OtpPurpose.PASSWORD_RESET,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
      });

      expect(delivered).toBe(true);
      expect(mockSend).toHaveBeenCalledTimes(1);
    });

    it('6.3 OtpDeliveryService.isConfigured checks EmailService when EmailDeliveryAdapter is active', () => {
      const adapter = new EmailDeliveryAdapter();
      OtpDeliveryService.setAdapter(adapter);

      (env as any).RESEND_API_KEY = '';
      EmailService.setClient(null);
      expect(OtpDeliveryService.isConfigured(OtpDeliveryMethod.EMAIL)).toBe(false);

      (env as any).RESEND_API_KEY = 're_test_configured';
      expect(OtpDeliveryService.isConfigured(OtpDeliveryMethod.EMAIL)).toBe(true);
    });

    it('6.4 OtpDeliveryService.assertConfigured throws operational error when unconfigured in production', () => {
      const adapter = new EmailDeliveryAdapter();
      OtpDeliveryService.setAdapter(adapter);

      (env as any).RESEND_API_KEY = '';
      EmailService.setClient(null);

      expect(() => {
        OtpDeliveryService.assertConfigured(OtpDeliveryMethod.EMAIL);
      }).toThrow(/Contact delivery service for email is not configured/);
    });
  });
});
