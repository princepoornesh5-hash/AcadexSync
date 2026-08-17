import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';

class ValidationBanner extends StatelessWidget {
  final int remainingCount;

  const ValidationBanner({super.key, required this.remainingCount});

  @override
  Widget build(BuildContext context) {
    if (remainingCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: DashboardColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Validation Error: $remainingCount students have missing attendance statuses.",
              style: const TextStyle(color: DashboardColors.error, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
