import { Resend, CreateEmailOptions } from 'resend';
import { env } from '../config/env';
import { Logger } from '../utils/logger';
import { renderOtpEmail } from './emailTemplates';
import { OtpPurpose } from '../constants/status';

export interface SendEmailOptions {
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  from?: string;
  replyTo?: string;
  tags?: Array<{ name: string; value: string }>;
}

export interface SendEmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
  errorCode?: string;
}

export interface SendOtpEmailOptions {
  to: string;
  otp: string;
  purpose: OtpPurpose | string;
  expiryMinutes?: number;
}

export class EmailService {
  private static clientInstance: Resend | null = null;

  /**
   * Override or inject the Resend client instance (primarily for automated testing).
   */
  public static setClient(client: Resend | null): void {
    this.clientInstance = client;
  }

  /**
   * Lazily initializes or returns the configured Resend SDK client.
   * Returns null if RESEND_API_KEY is not configured.
   */
  public static getClient(): Resend | null {
    if (this.clientInstance) {
      return this.clientInstance;
    }

    const apiKey = env.RESEND_API_KEY?.trim();
    if (!apiKey) {
      return null;
    }

    this.clientInstance = new Resend(apiKey);
    return this.clientInstance;
  }

  /**
   * Checks whether the Resend email provider is configured with an API key.
   */
  public static isConfigured(): boolean {
    if (this.clientInstance) return true;
    const apiKey = env.RESEND_API_KEY?.trim();
    return Boolean(apiKey && apiKey.length > 0);
  }

  /**
   * Validates and resolves the sender address to prevent arbitrary sender injection.
   * Sender addresses must either match the configured sender domain or default to RESEND_FROM_EMAIL.
   */
  private static resolveSender(customFrom?: string): { valid: boolean; sender: string; error?: string } {
    const configuredSender = env.RESEND_FROM_EMAIL.trim();

    if (!customFrom || customFrom.trim() === '') {
      // Format display name if not already formatted
      const formatted = configuredSender.includes('<')
        ? configuredSender
        : `ACADEXSYNC <${configuredSender}>`;
      return { valid: true, sender: formatted };
    }

    const trimmed = customFrom.trim();

    // Prevent CRLF injection in email headers
    if (/[\r\n\0]/.test(trimmed)) {
      return { valid: false, sender: '', error: 'Header injection characters detected in sender address.' };
    }

    // Extract bare email address from potential "Name <email@domain>" format
    const match = trimmed.match(/<([^>]+)>/) || [null, trimmed];
    const emailAddress = (match[1] || '').trim();

    // Basic email format check
    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;
    if (!emailRegex.test(emailAddress)) {
      return { valid: false, sender: '', error: 'Invalid sender email address format.' };
    }

    // Extract domain from configured sender
    const configuredMatch = configuredSender.match(/<([^>]+)>/) || [null, configuredSender];
    const configuredAddress = (configuredMatch[1] || '').trim().toLowerCase();
    const configuredDomain = configuredAddress.split('@')[1];

    const requestedDomain = emailAddress.split('@')[1]?.toLowerCase();

    // Enforce that sender domain must match the configured provider domain
    if (configuredDomain && requestedDomain !== configuredDomain) {
      return {
        valid: false,
        sender: '',
        error: `Unauthorized sender domain "${requestedDomain}". Must match configured domain "${configuredDomain}".`,
      };
    }

    return { valid: true, sender: trimmed };
  }

  /**
   * Dispatches a transactional email via Resend with timeout handling,
   * safe error boundaries, and no leakage of sensitive content or secrets.
   */
  public static async sendEmail(options: SendEmailOptions): Promise<SendEmailResult> {
    // 1. Verify provider configuration
    if (!this.isConfigured()) {
      Logger.error('[EMAIL SERVICE] Email dispatch rejected: RESEND_API_KEY is not configured in environment.');
      return {
        success: false,
        error: 'Email delivery provider is not configured. RESEND_API_KEY is missing.',
        errorCode: 'PROVIDER_NOT_CONFIGURED',
      };
    }

    const client = this.getClient();
    if (!client) {
      return {
        success: false,
        error: 'Failed to initialize Resend client.',
        errorCode: 'CLIENT_INIT_FAILED',
      };
    }

    // 2. Validate and resolve sender address (prevent arbitrary sender injection)
    const senderResolution = this.resolveSender(options.from);
    if (!senderResolution.valid) {
      Logger.error(`[EMAIL SERVICE] Rejected invalid sender address: ${senderResolution.error}`);
      return {
        success: false,
        error: senderResolution.error,
        errorCode: 'INVALID_SENDER',
      };
    }

    // 3. Normalize recipient list & ensure recipient is provided
    const recipients = Array.isArray(options.to) ? options.to : [options.to];
    const cleanedRecipients = recipients
      .map((r) => r.trim())
      .filter((r) => r.length > 0 && !/[\r\n\0]/.test(r));

    if (cleanedRecipients.length === 0) {
      return {
        success: false,
        error: 'Recipient address cannot be empty.',
        errorCode: 'EMPTY_RECIPIENT',
      };
    }

    // 4. Validate subject
    const subject = options.subject.replace(/[\r\n\0]/g, ' ').trim();
    if (!subject) {
      return {
        success: false,
        error: 'Email subject cannot be empty.',
        errorCode: 'EMPTY_SUBJECT',
      };
    }

    // 5. Ensure at least HTML or plain text body is present
    if (!options.html && !options.text) {
      return {
        success: false,
        error: 'Email body (HTML or plain text) must be provided.',
        errorCode: 'EMPTY_BODY',
      };
    }

    // 6. Safe logging (Masked recipient, no OTP, no HTML content)
    const maskedRecipients = cleanedRecipients.map((r) => Logger.maskEmail(r)).join(', ');
    Logger.info(`[EMAIL SERVICE] Sending transactional email "${subject}" to ${maskedRecipients}`);

    // 7. Dispatch with provider timeout handling
    const timeoutMs = env.RESEND_TIMEOUT_MS || 10000;

    const emailPayload: CreateEmailOptions = options.html
      ? {
          from: senderResolution.sender,
          to: cleanedRecipients,
          subject,
          html: options.html,
          ...(options.text ? { text: options.text } : {}),
          ...(options.replyTo ? { replyTo: options.replyTo } : {}),
          ...(options.tags ? { tags: options.tags } : {}),
        }
      : {
          from: senderResolution.sender,
          to: cleanedRecipients,
          subject,
          text: options.text as string,
          ...(options.replyTo ? { replyTo: options.replyTo } : {}),
          ...(options.tags ? { tags: options.tags } : {}),
        };

    try {
      const sendPromise = client.emails.send(emailPayload);

      const timeoutPromise = new Promise<never>((_, reject) => {
        const timer = setTimeout(() => {
          reject(new Error(`Resend email delivery timed out after ${timeoutMs}ms`));
        }, timeoutMs);
        timer.unref?.();
      });

      const response = await Promise.race([sendPromise, timeoutPromise]);

      if (response.error) {
        Logger.error(
          `[EMAIL SERVICE] Resend provider returned an error: ${response.error.name || 'Error'} - ${response.error.message}`
        );
        return {
          success: false,
          error: response.error.message,
          errorCode: response.error.name,
        };
      }

      const messageId = response.data?.id;
      Logger.info(`[EMAIL SERVICE] Successfully dispatched email. Message ID: ${messageId}`);

      return {
        success: true,
        messageId,
      };
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown provider error';
      Logger.error(`[EMAIL SERVICE] Provider failure during email delivery: ${errorMessage}`);
      return {
        success: false,
        error: errorMessage,
        errorCode: 'PROVIDER_DISPATCH_ERROR',
      };
    }
  }

  /**
   * Helper to render and dispatch an ACADEXSYNC-branded OTP email.
   * Keeps provider logic decoupled from authentication workflows.
   */
  public static async sendOtpEmail(options: SendOtpEmailOptions): Promise<SendEmailResult> {
    const rendered = renderOtpEmail({
      otp: options.otp,
      purpose: options.purpose,
      recipientEmail: options.to,
      expiryMinutes: options.expiryMinutes,
    });

    return this.sendEmail({
      to: options.to,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
    });
  }

  /**
   * Sends a safe, non-sensitive verification test email to a supplied recipient.
   * Used for developer verification via the local test script.
   */
  public static async sendTestEmail(recipient: string): Promise<SendEmailResult> {
    const rendered = renderOtpEmail({
      otp: '123456',
      purpose: 'INTEGRATION_TEST',
      recipientEmail: recipient,
      expiryMinutes: 10,
    });

    return this.sendEmail({
      to: recipient,
      subject: 'ACADEXSYNC - Resend Integration Test Email',
      html: rendered.html,
      text: rendered.text,
      tags: [{ name: 'category', value: 'integration_test' }],
    });
  }
}
