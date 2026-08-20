import { OtpPurpose, OtpDeliveryMethod } from '../constants/status';
import { Logger } from '../utils/logger';

export interface SendOtpOptions {
  destination: string;
  otp: string;
  purpose: OtpPurpose;
  deliveryMethod: OtpDeliveryMethod;
}

export interface IOtpDeliveryAdapter {
  sendOtp(options: SendOtpOptions): Promise<boolean>;
}

/**
 * In-Memory Testing & Development OTP Delivery Adapter
 * Stores the last delivered OTP in-memory for unit/integration testing
 * without logging or exposing secrets in production.
 */
export class DevOtpDeliveryAdapter implements IOtpDeliveryAdapter {
  private lastDelivered: Map<string, string> = new Map();

  async sendOtp(options: SendOtpOptions): Promise<boolean> {
    this.lastDelivered.set(options.destination, options.otp);
    if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
      Logger.info(
        `[DEV OTP DELIVERY] OTP sent to ${options.destination} via ${options.deliveryMethod} for ${options.purpose}`
      );
    }
    return true;
  }

  getLastOtp(destination: string): string | undefined {
    return this.lastDelivered.get(destination);
  }

  clear(): void {
    this.lastDelivered.clear();
  }
}

/**
 * Production Email Delivery Adapter placeholder
 */
export class EmailDeliveryAdapter implements IOtpDeliveryAdapter {
  async sendOtp(options: SendOtpOptions): Promise<boolean> {
    Logger.info(`[EMAIL OTP] Sending OTP to ${options.destination}`);
    // Future integration: AWS SES / Sendgrid / Nodemailer
    return true;
  }
}

/**
 * Production SMS Delivery Adapter placeholder
 */
export class SmsDeliveryAdapter implements IOtpDeliveryAdapter {
  async sendOtp(options: SendOtpOptions): Promise<boolean> {
    Logger.info(`[SMS OTP] Sending OTP to ${options.destination}`);
    // Future integration: Twilio / AWS SNS / MSG91
    return true;
  }
}

export class OtpDeliveryService {
  private static adapter: IOtpDeliveryAdapter = new DevOtpDeliveryAdapter();

  static setAdapter(newAdapter: IOtpDeliveryAdapter): void {
    this.adapter = newAdapter;
  }

  static getAdapter(): IOtpDeliveryAdapter {
    return this.adapter;
  }

  static async sendOtp(options: SendOtpOptions): Promise<boolean> {
    return this.adapter.sendOtp(options);
  }
}
