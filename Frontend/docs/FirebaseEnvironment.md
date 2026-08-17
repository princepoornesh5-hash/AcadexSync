# Firebase Environment Strategies

Acadex supports environment isolation to ensure testing does not affect production user data.

## Configuration Separation

We map configuration flags dynamically using command line arguments or environment variable bindings:

- **Development**: Bind arguments or keys prefixed with `DEV_`. Uses database: `acadex-dev`.
- **Testing**: Bind arguments or keys prefixed with `TEST_`. Uses database: `acadex-test`.
- **Production**: Bind arguments or keys prefixed with `PROD_`. Uses database: `acadex-prod`.

To run development target:
```bash
flutter run --dart-define=DEV_FIREBASE_API_KEY=your-dev-api-key ...
```

If these environment variables are absent, the application launches using the **Fallback Mock Mode** to avoid runtime configuration exceptions.
