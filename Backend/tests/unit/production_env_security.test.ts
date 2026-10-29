import { validateProductionConfig, loadEnv, EnvConfig } from '../../src/config/env';

describe('ACADEX Production Environment Security & Configuration Validation', () => {
  const validProductionBase: EnvConfig = {
    NODE_ENV: 'production',
    PORT: 5050,
    MONGODB_URI: 'mongodb+srv://prod_user:pAssW0rd!@cluster0.mongodb.net/acadex_prod?retryWrites=true&w=majority',
    MONGODB_DATABASE: 'acadex_prod',
    JWT_SECRET: 'k8F9xL2mP5vQ7zR4wT1yU3aB6cDk8F9xL2mP5', // 38 chars high-entropy
    JWT_ACCESS_SECRET: 'm3P8vQ2zR7wT1yU4aB9cD5eF0gHm3P8vQ2zR7', // 38 chars
    JWT_REFRESH_SECRET: 'w7T2yU5aB0cD4eF8gH1jK6mPw7T2yU5aB0cD4', // 38 chars
    JWT_RESET_SECRET: 'a4B9cD3eF7gH0jK5mP8vQa4B9cD3eF7gH0jK5', // 38 chars
    ACTIVATION_CODE_SECRET: 'd0cD4eF8gH1jK6mP3vQd0cD4eF8gH1jK6mP3v', // 38 chars
    ACCESS_TOKEN_EXPIRES_IN: 900,
    REFRESH_TOKEN_EXPIRES_IN: 604800,
    PASSWORD_RESET_TOKEN_EXPIRES_IN: 600,
    INVITATION_EXPIRES_IN: 604800,
    OTP_EXPIRES_IN: 600,
    OTP_MAX_ATTEMPTS: 5,
    OTP_RESEND_COOLDOWN: 60,
    BCRYPT_SALT_ROUNDS: 10,
    CORS_ORIGIN: 'https://acadex.edu,https://admin.acadex.edu',
    RATE_LIMIT_WINDOW_MS: 900000,
    RATE_LIMIT_MAX: 1000,
    AUTH_RATE_LIMIT_MAX: 15,
    UPLOAD_RATE_LIMIT_MAX: 30,
    REPORT_RATE_LIMIT_MAX: 60,
    INVITATION_RATE_LIMIT_MAX: 30,
    DEVICE_TOKEN_RATE_LIMIT_MAX: 30,
    IMAGEKIT_PUBLIC_KEY: 'public_prod_key',
    IMAGEKIT_PRIVATE_KEY: 'private_prod_key',
    IMAGEKIT_URL_ENDPOINT: 'https://ik.imagekit.io/acadex_prod',
    NOTES_MAX_FILE_SIZE_MB: 25,
    PROFILE_IMAGE_MAX_FILE_SIZE_MB: 5,
    SIGNED_URL_EXPIRY_SECONDS: 300,
    FIREBASE_PROJECT_ID: 'acadex-app',
    FIREBASE_CLIENT_EMAIL: 'firebase-adminsdk@acadex-app.iam.gserviceaccount.com',
    FIREBASE_PRIVATE_KEY: '-----BEGIN PRIVATE KEY-----\nMIIEvg...\n-----END PRIVATE KEY-----\n',
    GEMINI_API_KEY: 'mock_gemini_key',
    GEMINI_MODEL: 'gemini-3.5-flash-lite',
    AI_RATE_LIMIT_MAX: 30,
    AI_TIMEOUT_MS: 15000,
    RESEND_FROM_EMAIL: 'onboarding@resend.dev',
    RESEND_TIMEOUT_MS: 10000,
  };

  // ──────────────────────────────────────────────────────────────────────────
  // 1. Happy path: Valid Production Configuration
  // ──────────────────────────────────────────────────────────────────────────

  test('1. Valid high-entropy production configuration passes validation', () => {
    expect(() => validateProductionConfig(validProductionBase)).not.toThrow();
  });

  test('2. Render generateValue UUID-style secrets (36 chars, no "development") pass', () => {
    const renderUuidConfig: EnvConfig = {
      ...validProductionBase,
      JWT_SECRET:             '550e8400-e29b-41d4-a716-446655440001',
      JWT_ACCESS_SECRET:      '550e8400-e29b-41d4-a716-446655440002',
      JWT_REFRESH_SECRET:     '550e8400-e29b-41d4-a716-446655440003',
      JWT_RESET_SECRET:       '550e8400-e29b-41d4-a716-446655440004',
      ACTIVATION_CODE_SECRET: '550e8400-e29b-41d4-a716-446655440005',
    };
    expect(() => validateProductionConfig(renderUuidConfig)).not.toThrow();
  });

  test('3. Single explicit CORS origin passes validation', () => {
    const singleOriginConfig = {
      ...validProductionBase,
      CORS_ORIGIN: 'https://acadexsync.netlify.app',
    };
    expect(() => validateProductionConfig(singleOriginConfig)).not.toThrow();
  });

  test('4. Multiple explicit CORS origins (comma-separated) pass validation', () => {
    const multiOriginConfig = {
      ...validProductionBase,
      CORS_ORIGIN: 'https://acadexsync.netlify.app,https://admin.acadexsync.netlify.app',
    };
    expect(() => validateProductionConfig(multiOriginConfig)).not.toThrow();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Mandatory MongoDB URI Validation
  // ──────────────────────────────────────────────────────────────────────────

  test('5. Fails fast if MONGODB_URI is empty string', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, MONGODB_URI: '' })).toThrow(
      /MONGODB_URI is required and cannot be empty in production/
    );
  });

  test('6. Fails fast if MONGODB_URI is undefined', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, MONGODB_URI: undefined })).toThrow(
      /MONGODB_URI is required and cannot be empty in production/
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Each Missing Production Secret is Rejected
  // ──────────────────────────────────────────────────────────────────────────

  test('7. Fails fast if JWT_SECRET is missing (undefined)', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, JWT_SECRET: undefined as any })).toThrow(
      /JWT_SECRET is required and cannot be empty in production/
    );
  });

  test('8. Fails fast if JWT_SECRET is empty string', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, JWT_SECRET: '   ' })).toThrow(
      /JWT_SECRET is required and cannot be empty in production/
    );
  });

  test('9. Fails fast if JWT_ACCESS_SECRET is missing (undefined)', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, JWT_ACCESS_SECRET: undefined as any })).toThrow(
      /JWT_ACCESS_SECRET is required and cannot be empty in production/
    );
  });

  test('10. Fails fast if JWT_REFRESH_SECRET is missing (undefined)', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, JWT_REFRESH_SECRET: undefined as any })).toThrow(
      /JWT_REFRESH_SECRET is required and cannot be empty in production/
    );
  });

  test('11. Fails fast if JWT_RESET_SECRET is missing (undefined)', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, JWT_RESET_SECRET: undefined as any })).toThrow(
      /JWT_RESET_SECRET is required and cannot be empty in production/
    );
  });

  test('12. Fails fast if ACTIVATION_CODE_SECRET is missing (undefined)', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, ACTIVATION_CODE_SECRET: undefined as any })).toThrow(
      /ACTIVATION_CODE_SECRET is required and cannot be empty in production/
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. Insecure Development Defaults Rejected
  // ──────────────────────────────────────────────────────────────────────────

  test('13. Fails fast if JWT_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_SECRET: 'acadex_development_jwt_secret_min_32_chars!' })
    ).toThrow(/JWT_SECRET is using an insecure development default/);
  });

  test('14. Fails fast if JWT_SECRET is shorter than 32 characters', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_SECRET: 'short_key_under_32_chars' })
    ).toThrow(/JWT_SECRET must be at least 32 characters/);
  });

  test('15. Fails fast if JWT_SECRET contains the word "development"', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_SECRET: 'some_other_development_secret_here_xyzab!!' })
    ).toThrow(/JWT_SECRET is using an insecure development default/);
  });

  test('16. Fails fast if JWT_ACCESS_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_ACCESS_SECRET: 'acadex_development_access_token_secret_min_32_chars!' })
    ).toThrow(/JWT_ACCESS_SECRET is using an insecure development default/);
  });

  test('17. Fails fast if JWT_REFRESH_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_REFRESH_SECRET: 'acadex_development_refresh_token_secret_min_32_chars!' })
    ).toThrow(/JWT_REFRESH_SECRET is using an insecure development default/);
  });

  test('18. Fails fast if JWT_RESET_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_RESET_SECRET: 'acadex_development_reset_token_secret_min_32_chars!' })
    ).toThrow(/JWT_RESET_SECRET is using an insecure development default/);
  });

  test('19. Fails fast if ACTIVATION_CODE_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, ACTIVATION_CODE_SECRET: 'acadex_development_activation_secret_32_chars!' })
    ).toThrow(/ACTIVATION_CODE_SECRET is using an insecure development default/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. Secret Reuse Across Different Purposes is Rejected
  // ──────────────────────────────────────────────────────────────────────────

  test('20. Fails fast if production secrets are duplicated across tokens', () => {
    const duplicateConfig: EnvConfig = {
      ...validProductionBase,
      JWT_SECRET:             'k8F9xL2mP5vQ7zR4wT1yU3aB6cDk8F9xL2mP5',
      JWT_ACCESS_SECRET:      'k8F9xL2mP5vQ7zR4wT1yU3aB6cDk8F9xL2mP5', // duplicate!
      JWT_REFRESH_SECRET:     'w7T2yU5aB0cD4eF8gH1jK6mPw7T2yU5aB0cD4',
      JWT_RESET_SECRET:       'a4B9cD3eF7gH0jK5mP8vQa4B9cD3eF7gH0jK5',
      ACTIVATION_CODE_SECRET: 'd0cD4eF8gH1jK6mP3vQd0cD4eF8gH1jK6mP3v',
    };
    expect(() => validateProductionConfig(duplicateConfig)).toThrow(
      /must each be unique values/
    );
  });

  test('21. Five secrets are independently configurable — all different values accepted', () => {
    const allDifferentConfig: EnvConfig = {
      ...validProductionBase,
      JWT_SECRET:             '7a3f2e1b9c4d8e6f0a1b2c3d4e5f6a7b8c9d0e',
      JWT_ACCESS_SECRET:      '9b4e3d2c1a6f5e4d3c2b1a9f8e7d6c5b4a3f2e',
      JWT_REFRESH_SECRET:     '1c5f4e3d2b1a9f8e7d6c5b4a3f2e1b0c9d8e7f',
      JWT_RESET_SECRET:       '3d6e5f4e3d2c1b0a9f8e7d6c5b4a3f2e1b0c9d',
      ACTIVATION_CODE_SECRET: '5e7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a',
    };
    expect(() => validateProductionConfig(allDifferentConfig)).not.toThrow();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 6. CORS Validation: Missing, Wildcard, and Mixed Allowed
  // ──────────────────────────────────────────────────────────────────────────

  test('22. Fails fast if CORS_ORIGIN is missing (undefined)', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, CORS_ORIGIN: undefined as any })).toThrow(
      /CORS_ORIGIN is required and cannot be empty in production/
    );
  });

  test('23. Fails fast if CORS_ORIGIN is empty string', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, CORS_ORIGIN: '   ' })).toThrow(
      /CORS_ORIGIN is required and cannot be empty in production/
    );
  });

  test('24. Fails fast if CORS_ORIGIN is bare wildcard "*"', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, CORS_ORIGIN: '*' })).toThrow(
      /CORS_ORIGIN cannot be "\*" \(wildcard\) in production/
    );
  });

  test('25. Fails fast if CORS_ORIGIN list contains "*" mixed with real origins', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, CORS_ORIGIN: 'https://acadex.edu, *' })
    ).toThrow(/CORS_ORIGIN cannot be "\*" \(wildcard\) in production/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 7. Multiple Simultaneous Violations Aggregated
  // ──────────────────────────────────────────────────────────────────────────

  test('26. Multiple violations are all included in a single error message', () => {
    const badConfig = {
      ...validProductionBase,
      JWT_SECRET: 'acadex_development_jwt_secret_min_32_chars!',
      JWT_ACCESS_SECRET: 'acadex_development_access_token_secret_min_32_chars!',
      CORS_ORIGIN: '*',
    };
    let caught: Error | null = null;
    try { validateProductionConfig(badConfig); } catch (e: any) { caught = e; }
    expect(caught).not.toBeNull();
    expect(caught!.message).toMatch(/JWT_SECRET/);
    expect(caught!.message).toMatch(/JWT_ACCESS_SECRET/);
    expect(caught!.message).toMatch(/CORS_ORIGIN/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 8. Secret Redaction: Secret values never appear in error messages
  // ──────────────────────────────────────────────────────────────────────────

  test('27. Error messages never leak the actual secret value', () => {
    const sensitiveSecretValue = 'super_secret_high_entropy_key_value_not_to_leak_9988!';
    let caught: Error | null = null;
    try {
      validateProductionConfig({
        ...validProductionBase,
        JWT_SECRET: sensitiveSecretValue,
        JWT_ACCESS_SECRET: sensitiveSecretValue, // triggers duplicate
      });
    } catch (e: any) {
      caught = e;
    }
    expect(caught).not.toBeNull();
    expect(caught!.message).not.toContain(sensitiveSecretValue);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 9. Development Configuration Continues to Work with Fallback Defaults
  // ──────────────────────────────────────────────────────────────────────────

  test('28. Development configuration loads seamlessly with safe dev defaults without production errors', () => {
    const devEnv = loadEnv({
      NODE_ENV: 'development',
      PORT: '5050',
    });
    expect(devEnv.NODE_ENV).toBe('development');
    expect(devEnv.JWT_SECRET).toBe('acadex_development_jwt_secret_min_32_chars!');
    expect(devEnv.CORS_ORIGIN).toBe('*');
  });

  test('29. Production loadEnv without required variables throws clear missing error without silent dev fallback', () => {
    expect(() =>
      loadEnv({
        NODE_ENV: 'production',
        PORT: '10000',
        MONGODB_URI: 'mongodb+srv://user:pass@cluster.mongodb.net/acadex',
      })
    ).toThrow(/JWT_SECRET is required and cannot be empty in production/);
  });
});
