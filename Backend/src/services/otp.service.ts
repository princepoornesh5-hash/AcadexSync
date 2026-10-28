import crypto from 'crypto';
import { Otp, IOtp } from '../models/otp.model';
import { OtpPurpose, OtpDeliveryMethod } from '../constants/status';
import { env } from '../config/env';
import { ApiError } from '../utils/apiError';
import { OtpDeliveryService } from './otpDelivery.service';
import mongoose from 'mongoose';

export interface RequestOtpOptions {
  destination: string;
  purpose: OtpPurpose;
  userId?: mongoose.Types.ObjectId | string | null;
  invitationId?: mongoose.Types.ObjectId | string | null;
  deliveryMethod?: OtpDeliveryMethod;
  expiresInSeconds?: number;
}

export interface VerifyOtpOptions {
  destination?: string;
  userId?: mongoose.Types.ObjectId | string | null;
  invitationId?: mongoose.Types.ObjectId | string | null;
  purpose: OtpPurpose;
  otp: string;
}

export class OtpService {
  /**
   * Cryptographically secure random numeric OTP generator (defaults to 6 digits).
   */
  static generateOtpCode(length = 6): string {
    const min = Math.pow(10, length - 1);
    const max = Math.pow(10, length) - 1;
    return crypto.randomInt(min, max + 1).toString();
  }

  /**
   * Hashes OTP code using HMAC SHA-256 with secret salt.
   */
  static hashOtpCode(otp: string): string {
    return crypto
      .createHmac('sha256', env.JWT_RESET_SECRET)
      .update(otp)
      .digest('hex');
  }

  /**
   * Constant-time comparison of OTP hashes to prevent timing attacks.
   */
  static verifyOtpHash(rawOtp: string, expectedHash: string): boolean {
    const hash = this.hashOtpCode(rawOtp);
    const bufA = Buffer.from(hash, 'hex');
    const bufB = Buffer.from(expectedHash, 'hex');
    if (bufA.length !== bufB.length) return false;
    return crypto.timingSafeEqual(bufA, bufB);
  }

  /**
   * Creates, persists, and delivers a new OTP challenge with rate limiting,
   * resend cooldown, and bounded expiration (defaults to 5 minutes).
   */
  static async requestOtp(
    optionsOrUserId: RequestOtpOptions | mongoose.Types.ObjectId | string,
    purposeParam?: OtpPurpose,
    destinationParam?: string,
    deliveryMethodParam?: OtpDeliveryMethod,
    expiresInSecondsParam?: number
  ): Promise<{ success: boolean; expiresInSeconds: number; cooldownSeconds: number }> {
    let destination: string;
    let purpose: OtpPurpose;
    let userId: mongoose.Types.ObjectId | null = null;
    let invitationId: mongoose.Types.ObjectId | null = null;
    let deliveryMethod: OtpDeliveryMethod = OtpDeliveryMethod.EMAIL;
    let expiresInSeconds = env.OTP_EXPIRES_IN || 300; // Default 5 minutes (300s)

    if (typeof optionsOrUserId === 'object' && !(optionsOrUserId instanceof mongoose.Types.ObjectId)) {
      const opts = optionsOrUserId as RequestOtpOptions;
      destination = opts.destination;
      purpose = opts.purpose;
      if (opts.userId) {
        userId = new mongoose.Types.ObjectId(opts.userId);
      }
      if (opts.invitationId) {
        invitationId = new mongoose.Types.ObjectId(opts.invitationId);
      }
      if (opts.deliveryMethod) {
        deliveryMethod = opts.deliveryMethod;
      }
      if (opts.expiresInSeconds) {
        expiresInSeconds = opts.expiresInSeconds;
      }
    } else {
      userId = new mongoose.Types.ObjectId(optionsOrUserId);
      purpose = purposeParam!;
      destination = destinationParam!;
      deliveryMethod = deliveryMethodParam || OtpDeliveryMethod.EMAIL;
      if (expiresInSecondsParam) {
        expiresInSeconds = expiresInSecondsParam;
      }
    }

    if (!destination || destination.trim() === '') {
      throw ApiError.badRequest('Destination address (email or phone) is required');
    }

    const normalizedDestination = destination.trim().toLowerCase();

    // 1. Check resend cooldown
    const cooldownQuery: Record<string, unknown> = {
      purpose,
      $or: [
        { destination: normalizedDestination },
        ...(userId ? [{ userId }] : []),
        ...(invitationId ? [{ invitationId }] : []),
      ],
    };

    const latestOtp = await Otp.findOne(cooldownQuery).sort({ createdAt: -1 });

    if (latestOtp) {
      const secondsSinceCreation = (Date.now() - latestOtp.createdAt.getTime()) / 1000;
      if (secondsSinceCreation < env.OTP_RESEND_COOLDOWN) {
        const waitTime = Math.ceil(env.OTP_RESEND_COOLDOWN - secondsSinceCreation);
        throw ApiError.tooManyRequests(
          `Please wait ${waitTime} seconds before requesting another code.`
        );
      }
    }

    // 2. Invalidate previous unconsumed OTPs for this destination/user/invitation and purpose
    await Otp.updateMany(
      {
        purpose,
        consumedAt: null,
        $or: [
          { destination: normalizedDestination },
          ...(userId ? [{ userId }] : []),
          ...(invitationId ? [{ invitationId }] : []),
        ],
      },
      {
        $set: { consumedAt: new Date() },
      }
    );

    // 3. Generate secure numeric code & HMAC hash
    const rawOtp = this.generateOtpCode(6);
    const otpHash = this.hashOtpCode(rawOtp);
    const expiresAt = new Date(Date.now() + expiresInSeconds * 1000);

    // 4. Persist OTP record
    const createdOtp = await Otp.create({
      userId,
      invitationId,
      purpose,
      deliveryMethod,
      destination: normalizedDestination,
      otpHash,
      expiresAt,
      attempts: 0,
      consumedAt: null,
    });

    // 5. Dispatch via delivery adapter (Resend for email)
    try {
      const delivered = await OtpDeliveryService.sendOtp({
        destination: normalizedDestination,
        otp: rawOtp,
        purpose,
        deliveryMethod,
      });

      if (!delivered) {
        await Otp.findByIdAndDelete(createdOtp._id).catch(() => {});
        throw ApiError.internal('Failed to deliver verification code. Please try again later.');
      }
    } catch (deliveryError) {
      // Remove un-delivered OTP to avoid leaving user blocked by cooldown
      await Otp.findByIdAndDelete(createdOtp._id).catch(() => {});
      throw deliveryError;
    }

    return {
      success: true,
      expiresInSeconds,
      cooldownSeconds: env.OTP_RESEND_COOLDOWN,
    };
  }

  /**
   * Verifies and consumes OTP with expiration, attempt limits, and single-use checks.
   */
  static async verifyAndConsumeOtp(
    optionsOrUserId: VerifyOtpOptions | mongoose.Types.ObjectId | string,
    purposeParam?: OtpPurpose,
    rawOtpParam?: string,
    expectedDestination?: string,
    expectedDeliveryMethod?: OtpDeliveryMethod
  ): Promise<IOtp> {
    let rawOtp: string;
    let purpose: OtpPurpose;
    let destination: string | undefined;
    let userId: mongoose.Types.ObjectId | null = null;
    let invitationId: mongoose.Types.ObjectId | null = null;

    if (typeof optionsOrUserId === 'object' && !(optionsOrUserId instanceof mongoose.Types.ObjectId)) {
      const opts = optionsOrUserId as VerifyOtpOptions;
      rawOtp = opts.otp;
      purpose = opts.purpose;
      destination = opts.destination ? opts.destination.trim().toLowerCase() : undefined;
      if (opts.userId) {
        userId = new mongoose.Types.ObjectId(opts.userId);
      }
      if (opts.invitationId) {
        invitationId = new mongoose.Types.ObjectId(opts.invitationId);
      }
    } else {
      userId = new mongoose.Types.ObjectId(optionsOrUserId);
      purpose = purposeParam!;
      rawOtp = rawOtpParam!;
      destination = expectedDestination ? expectedDestination.trim().toLowerCase() : undefined;
    }

    if (!rawOtp || typeof rawOtp !== 'string' || rawOtp.trim() === '') {
      throw ApiError.badRequest('Verification code is required');
    }

    const cleanOtp = rawOtp.trim();

    // Build lookup query
    const query: Record<string, unknown> = {
      purpose,
    };

    if (destination) {
      query.destination = destination;
    }
    if (userId) {
      query.userId = userId;
    }
    if (invitationId) {
      query.invitationId = invitationId;
    }
    if (expectedDeliveryMethod) {
      query.deliveryMethod = expectedDeliveryMethod;
    }

    // Find latest matching OTP
    const otpDoc = await Otp.findOne(query).sort({ createdAt: -1 });

    if (!otpDoc) {
      // Check if code was requested for a different purpose to provide precise error
      if (destination) {
        const otherPurposeOtp = await Otp.findOne({ destination }).sort({ createdAt: -1 });
        if (otherPurposeOtp && otherPurposeOtp.purpose !== purpose && !otherPurposeOtp.isConsumed()) {
          throw ApiError.badRequest('This verification code was issued for a different action.');
        }
      }
      throw ApiError.badRequest('No verification code found. Please request a new code.');
    }

    if (otpDoc.isConsumed()) {
      throw ApiError.badRequest('This verification code has already been used. Please request a new code.');
    }

    if (otpDoc.isExpired()) {
      throw ApiError.badRequest('This verification code has expired. Please request a new code.');
    }

    if (otpDoc.attempts >= env.OTP_MAX_ATTEMPTS) {
      throw ApiError.badRequest('Maximum verification attempts exceeded. Please request a new code.');
    }

    // Verify hash match using constant-time comparison
    const isValid = this.verifyOtpHash(cleanOtp, otpDoc.otpHash);
    if (!isValid) {
      otpDoc.attempts += 1;
      await otpDoc.save();
      const remaining = env.OTP_MAX_ATTEMPTS - otpDoc.attempts;
      if (remaining <= 0) {
        throw ApiError.badRequest('Maximum verification attempts exceeded. Please request a new code.');
      }
      throw ApiError.badRequest(`Invalid verification code. ${remaining} attempt(s) remaining.`);
    }

    // Consume OTP atomically
    otpDoc.consumedAt = new Date();
    await otpDoc.save();

    return otpDoc;
  }
}
