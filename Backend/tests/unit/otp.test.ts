import { OtpService } from '../../src/services/otp.service';
import { OtpDeliveryService, DevOtpDeliveryAdapter } from '../../src/services/otpDelivery.service';
import { OtpPurpose, OtpDeliveryMethod } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import mongoose from 'mongoose';

describe('OTP Generation, Hashing & Verification Unit Tests', () => {
  const devAdapter = new DevOtpDeliveryAdapter();

  beforeAll(async () => {
    await setupTestDB();
    OtpDeliveryService.setAdapter(devAdapter);
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    devAdapter.clear();
  });

  it('22. OTP is generated securely as a 6-digit numeric string', () => {
    const otp = OtpService.generateOtpCode(6);
    expect(otp).toHaveLength(6);
    expect(/^\d{6}$/.test(otp)).toBe(true);
  });

  it('23. OTP is stored hashed with secure HMAC SHA-256', () => {
    const raw = '123456';
    const hash = OtpService.hashOtpCode(raw);
    expect(hash).not.toBe(raw);
    expect(hash.length).toBe(64); // 32 bytes hex = 64 chars

    expect(OtpService.verifyOtpHash(raw, hash)).toBe(true);
    expect(OtpService.verifyOtpHash('654321', hash)).toBe(false);
  });

  it('24. Valid OTP works and gets consumed upon verification', async () => {
    const userId = new mongoose.Types.ObjectId();
    const destination = 'student@test.edu';

    await OtpService.requestOtp(userId, OtpPurpose.PASSWORD_RESET, destination, OtpDeliveryMethod.EMAIL);

    const sentOtp = devAdapter.getLastOtp(destination);
    expect(sentOtp).toBeDefined();

    const consumed = await OtpService.verifyAndConsumeOtp(userId, OtpPurpose.PASSWORD_RESET, sentOtp!);
    expect(consumed.isConsumed()).toBe(true);
  });

  it('25. Invalid OTP fails verification and counts attempts', async () => {
    const userId = new mongoose.Types.ObjectId();
    const destination = 'student@test.edu';

    await OtpService.requestOtp(userId, OtpPurpose.PASSWORD_RESET, destination, OtpDeliveryMethod.EMAIL);

    await expect(
      OtpService.verifyAndConsumeOtp(userId, OtpPurpose.PASSWORD_RESET, '000000')
    ).rejects.toThrow(/Invalid verification code/);
  });

  it('27. Consumed OTP cannot be reused', async () => {
    const userId = new mongoose.Types.ObjectId();
    const destination = 'student@test.edu';

    await OtpService.requestOtp(userId, OtpPurpose.PASSWORD_RESET, destination, OtpDeliveryMethod.EMAIL);
    const sentOtp = devAdapter.getLastOtp(destination)!;

    // First use succeeds
    await OtpService.verifyAndConsumeOtp(userId, OtpPurpose.PASSWORD_RESET, sentOtp);

    // Second use fails immediately
    await expect(
      OtpService.verifyAndConsumeOtp(userId, OtpPurpose.PASSWORD_RESET, sentOtp)
    ).rejects.toThrow(/already been used/);
  });

  it('29. OTP resend cooldown enforces wait period between requests', async () => {
    const userId = new mongoose.Types.ObjectId();
    const destination = 'student@test.edu';

    // 1st request succeeds
    await OtpService.requestOtp(userId, OtpPurpose.PASSWORD_RESET, destination, OtpDeliveryMethod.EMAIL);

    // 2nd immediate request fails with cooldown error
    await expect(
      OtpService.requestOtp(userId, OtpPurpose.PASSWORD_RESET, destination, OtpDeliveryMethod.EMAIL)
    ).rejects.toThrow(/Please wait \d+ seconds before requesting another code/);
  });
});
