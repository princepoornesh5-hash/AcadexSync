import { validateProductionConfig, EnvConfig } from '../../src/config/env';

describe('ACADEX PROMPT 6: Production Environment Security & Configuration Validation', () => {
  const validProductionBase: EnvConfig = {
    NODE_ENV: 'production',
    PORT: 5050,
    MONGODB_URI: 'mongodb+srv://prod_user:pAssW0rd!@cluster0.mongodb.net/acadex_prod?retryWrites=true&w=majority',
    MONGODB_DATABASE: 'acadex_prod',
    JWT_SECRET: 'k8F#9xL@2mP$5vQ!7zR*4wT&1yU^3aB(6cD', // 35 chars high-entropy
    JWT_ACCESS_SECRET: 'm3P$8vQ!2zR*7wT&1yU^4aB(9cD)5eF#0gH', // 35 chars high-entropy
    JWT_REFRESH_SECRET: 'w7T&2yU^5aB(0cD)4eF#8gH$1jK@6mP!3vQ', // 35 chars high-entropy
    JWT_RESET_SECRET: 'a4B(9cD)3eF#7gH$0jK@5mP!8vQ&2zR*1wT', // 35 chars high-entropy
    ACTIVATION_CODE_SECRET: 'd0cD)4eF#8gH$1jK@6mP!3vQ&7zR*2wT^5y', // 35 chars high-entropy
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
    FIREBASE_PRIVATE_KEY: '-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC6...\n-----END PRIVATE KEY-----\n',
    GEMINI_API_KEY: 'mock_gemini_key',
    GEMINI_MODEL: 'gemini-3.5-flash-lite',
    AI_RATE_LIMIT_MAX: 30,
    AI_TIMEOUT_MS: 15000,
  };

  test('1. Valid production configuration passes validation without error', () => {
    expect(() => validateProductionConfig(validProductionBase)).not.toThrow();
  });

  test('2. Fails fast in production if MONGODB_URI is missing or empty', () => {
    const invalidConfig = { ...validProductionBase, MONGODB_URI: '' };
    expect(() => validateProductionConfig(invalidConfig)).toThrow(
      /MONGODB_URI is required and cannot be empty in production/
    );
  });

  test('3. Fails fast in production if default development JWT_SECRET is used', () => {
    const invalidConfig = {
      ...validProductionBase,
      JWT_SECRET: 'acadex_development_jwt_secret_min_32_chars!',
    };
    expect(() => validateProductionConfig(invalidConfig)).toThrow(
      /JWT_SECRET is using an insecure development default/
    );
  });

  test('4. Fails fast in production if JWT secret is shorter than 32 characters', () => {
    const invalidConfig = {
      ...validProductionBase,
      JWT_ACCESS_SECRET: 'short_key_under_32_chars',
    };
    expect(() => validateProductionConfig(invalidConfig)).toThrow(
      /JWT_ACCESS_SECRET must be at least 32 characters/
    );
  });

  test('5. Fails fast in production if CORS_ORIGIN is unrestricted wildcard (*)', () => {
    const wildcardConfig = { ...validProductionBase, CORS_ORIGIN: '*' };
    expect(() => validateProductionConfig(wildcardConfig)).toThrow(
      /CORS_ORIGIN cannot be "\*" \(wildcard\) in production/
    );

    const wildcardListConfig = {
      ...validProductionBase,
      CORS_ORIGIN: 'https://acadex.edu, *',
    };
    expect(() => validateProductionConfig(wildcardListConfig)).toThrow(
      /CORS_ORIGIN cannot be "\*" \(wildcard\) in production/
    );
  });

  test('6. Fails fast in production if ACTIVATION_CODE_SECRET is using development default', () => {
    const invalidConfig = {
      ...validProductionBase,
      ACTIVATION_CODE_SECRET: 'acadex_development_activation_secret_32_chars!',
    };
    expect(() => validateProductionConfig(invalidConfig)).toThrow(
      /ACTIVATION_CODE_SECRET is using an insecure development default/
    );
  });

  test('7. Error message never leaks secret values in exception text', () => {
    const secretWithMarker = 'acadex_development_jwt_secret_min_32_chars!';
    const invalidConfig = {
      ...validProductionBase,
      JWT_SECRET: secretWithMarker,
    };

    let caughtError: Error | null = null;
    try {
      validateProductionConfig(invalidConfig);
    } catch (e: any) {
      caughtError = e;
    }

    expect(caughtError).not.toBeNull();
    // Verify that the actual secret value itself is NOT printed in the exception string
    expect(caughtError?.message.includes(secretWithMarker)).toBe(false);
  });
});
