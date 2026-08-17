enum FirebaseEnv {
  development,
  testing,
  production,
}

class FirebaseConfig {
  final FirebaseEnv environment;
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String storageBucket;

  const FirebaseConfig({
    required this.environment,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.storageBucket,
  });

  // Safe factory that defaults to development environment and checks configuration keys
  factory FirebaseConfig.fromEnvironment(FirebaseEnv env) {
    switch (env) {
      case FirebaseEnv.production:
        return const FirebaseConfig(
          environment: FirebaseEnv.production,
          apiKey: String.fromEnvironment('PROD_FIREBASE_API_KEY', defaultValue: 'prod-placeholder-key'),
          appId: String.fromEnvironment('PROD_FIREBASE_APP_ID', defaultValue: 'prod-placeholder-app-id'),
          messagingSenderId: String.fromEnvironment('PROD_FIREBASE_SENDER_ID', defaultValue: 'prod-placeholder-sender-id'),
          projectId: String.fromEnvironment('PROD_FIREBASE_PROJECT_ID', defaultValue: 'acadex-prod'),
          storageBucket: String.fromEnvironment('PROD_FIREBASE_STORAGE_BUCKET', defaultValue: 'acadex-prod.appspot.com'),
        );
      case FirebaseEnv.testing:
        return const FirebaseConfig(
          environment: FirebaseEnv.testing,
          apiKey: String.fromEnvironment('TEST_FIREBASE_API_KEY', defaultValue: 'test-placeholder-key'),
          appId: String.fromEnvironment('TEST_FIREBASE_APP_ID', defaultValue: 'test-placeholder-app-id'),
          messagingSenderId: String.fromEnvironment('TEST_FIREBASE_SENDER_ID', defaultValue: 'test-placeholder-sender-id'),
          projectId: String.fromEnvironment('TEST_FIREBASE_PROJECT_ID', defaultValue: 'acadex-test'),
          storageBucket: String.fromEnvironment('TEST_FIREBASE_STORAGE_BUCKET', defaultValue: 'acadex-test.appspot.com'),
        );
      case FirebaseEnv.development:
        return const FirebaseConfig(
          environment: FirebaseEnv.development,
          apiKey: String.fromEnvironment('DEV_FIREBASE_API_KEY', defaultValue: 'dev-placeholder-key'),
          appId: String.fromEnvironment('DEV_FIREBASE_APP_ID', defaultValue: 'dev-placeholder-app-id'),
          messagingSenderId: String.fromEnvironment('DEV_FIREBASE_SENDER_ID', defaultValue: 'dev-placeholder-sender-id'),
          projectId: String.fromEnvironment('DEV_FIREBASE_PROJECT_ID', defaultValue: 'acadex-dev'),
          storageBucket: String.fromEnvironment('DEV_FIREBASE_STORAGE_BUCKET', defaultValue: 'acadex-dev.appspot.com'),
        );
    }
  }

  bool get isPlaceholder => apiKey.contains('placeholder');
}
