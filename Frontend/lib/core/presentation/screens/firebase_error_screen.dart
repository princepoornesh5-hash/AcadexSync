import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../firebase/firebase_initializer.dart';
import '../../firebase/firebase_config.dart';

class FirebaseErrorScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const FirebaseErrorScreen({super.key, required this.onRetry});

  @override
  State<FirebaseErrorScreen> createState() => _FirebaseErrorScreenState();
}

class _FirebaseErrorScreenState extends State<FirebaseErrorScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    // Attempt re-initialization
    await FirebaseInitializer.initialize(FirebaseEnv.production);
    setState(() => _isRetrying = false);
    
    // Call parent to rebuild and check state
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: Scaffold(
        backgroundColor: DashboardColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: DashboardColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.serverCrash,
                    size: 64,
                    color: DashboardColors.error,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'System Offline',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Acadex could not connect to its backend. Please check your internet connection or contact the system administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: DashboardColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isRetrying ? null : _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isRetrying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Retry Connection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
