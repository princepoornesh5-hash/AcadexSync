import { validateProductionConfig, EnvConfig } from '../../src/config/env';

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
  // 1. Happy path
  // ──────────────────────────────────────────────────────────────────────────

  test('1. Valid high-entropy production configuration passes validation', () => {
    expect(() => validateProductionConfig(validProductionBase)).not.toThrow();
  });

  test('2. Render generateValue UUID-style secrets (36 chars, no "development") pass', () => {
    // Render generateValue produces UUID-style strings e.g. "550e8400-e29b-41d4-a716-446655440000" (36 chars)
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

  test('3. Multiple explicit CORS origins (comma-separated) pass validation', () => {
    const multiOriginConfig = {
      ...validProductionBase,
      CORS_ORIGIN: 'https://acadexsync.netlify.app,https://admin.acadexsync.netlify.app',
    };
    expect(() => validateProductionConfig(multiOriginConfig)).not.toThrow();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. MongoDB URI validation
  // ──────────────────────────────────────────────────────────────────────────

  test('4. Fails fast if MONGODB_URI is empty string', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, MONGODB_URI: '' })).toThrow(
      /MONGODB_URI is required and cannot be empty in production/
    );
  });

  test('5. Fails fast if MONGODB_URI is undefined', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, MONGODB_URI: undefined })).toThrow(
      /MONGODB_URI is required and cannot be empty in production/
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. JWT_SECRET
  // ──────────────────────────────────────────────────────────────────────────

  test('6. Fails fast if JWT_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_SECRET: 'acadex_development_jwt_secret_min_32_chars!' })
    ).toThrow(/JWT_SECRET is using an insecure development default/);
  });

  test('7. Fails fast if JWT_SECRET is shorter than 32 characters', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_SECRET: 'short' })
    ).toThrow(/JWT_SECRET must be at least 32 characters/);
  });

  test('8. Fails fast if JWT_SECRET contains the word "development"', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_SECRET: 'some_other_development_secret_here_xyzab!!' })
    ).toThrow(/JWT_SECRET is using an insecure development default/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. JWT_ACCESS_SECRET
  // ──────────────────────────────────────────────────────────────────────────

  test('9. Fails fast if JWT_ACCESS_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_ACCESS_SECRET: 'acadex_development_access_token_secret_min_32_chars!' })
    ).toThrow(/JWT_ACCESS_SECRET is using an insecure development default/);
  });

  test('10. Fails fast if JWT_ACCESS_SECRET is shorter than 32 characters', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_ACCESS_SECRET: 'short_key_under_32_chars' })
    ).toThrow(/JWT_ACCESS_SECRET must be at least 32 characters/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. JWT_REFRESH_SECRET
  // ──────────────────────────────────────────────────────────────────────────

  test('11. Fails fast if JWT_REFRESH_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_REFRESH_SECRET: 'acadex_development_refresh_token_secret_min_32_chars!' })
    ).toThrow(/JWT_REFRESH_SECRET is using an insecure development default/);
  });

  test('12. Fails fast if JWT_REFRESH_SECRET is shorter than 32 characters', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_REFRESH_SECRET: 'tooshort' })
    ).toThrow(/JWT_REFRESH_SECRET must be at least 32 characters/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 6. JWT_RESET_SECRET
  // ──────────────────────────────────────────────────────────────────────────

  test('13. Fails fast if JWT_RESET_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, JWT_RESET_SECRET: 'acadex_development_reset_token_secret_min_32_chars!' })
    ).toThrow(/JWT_RESET_SECRET is using an insecure development default/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 7. ACTIVATION_CODE_SECRET
  // ──────────────────────────────────────────────────────────────────────────

  test('14. Fails fast if ACTIVATION_CODE_SECRET uses the known development default', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, ACTIVATION_CODE_SECRET: 'acadex_development_activation_secret_32_chars!' })
    ).toThrow(/ACTIVATION_CODE_SECRET is using an insecure development default/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 8. CORS validation
  // ──────────────────────────────────────────────────────────────────────────

  test('15. Fails fast if CORS_ORIGIN is bare wildcard "*"', () => {
    expect(() => validateProductionConfig({ ...validProductionBase, CORS_ORIGIN: '*' })).toThrow(
      /CORS_ORIGIN cannot be "\*" \(wildcard\) in production/
    );
  });

  test('16. Fails fast if CORS_ORIGIN list contains "*" mixed with real origins', () => {
    expect(() =>
      validateProductionConfig({ ...validProductionBase, CORS_ORIGIN: 'https://acadex.edu, *' })
    ).toThrow(/CORS_ORIGIN cannot be "\*" \(wildcard\) in production/);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 9. Multiple simultaneous violations
  // ──────────────────────────────────────────────────────────────────────────

  test('17. Multiple violations are all included in a single error message', () => {
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
  // 10. Secret value never appears in error text
  // ──────────────────────────────────────────────────────────────────────────

  test('18. Error messages never leak the actual secret value', () => {
    const secretValue = 'acadex_development_jwt_secret_min_32_chars!';
    let caught: Error | null = null;
    try {
      validateProductionConfig({ ...validProductionBase, JWT_SECRET: secretValue });
    } catch (e: any) {
      caught = e;
    }
    expect(caught).not.toBeNull();
    expect(caught!.message).not.toContain(secretValue);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 11. Five secrets independently configurable
  // ──────────────────────────────────────────────────────────────────────────

  test('19. Five secrets are independently configurable — all different values accepted', () => {
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
});
