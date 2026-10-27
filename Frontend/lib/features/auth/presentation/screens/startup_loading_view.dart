import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Minimal, direct startup loading placeholder shown only during the brief milliseconds
/// while auth state is resolving from secure storage.
/// Ready for a future minimal logo-only splash lasting ~1 second once the logo is supplied.
class StartupLoadingView extends StatelessWidget {
  const StartupLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AcadexColors.primary),
          ),
        ),
      ),
    );
  }
}
