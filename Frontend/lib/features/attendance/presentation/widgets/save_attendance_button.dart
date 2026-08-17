import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class SaveAttendanceButton extends StatelessWidget {
  final int remainingCount;
  final VoidCallback onSave;

  const SaveAttendanceButton({
    super.key,
    required this.remainingCount,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = remainingCount == 0;
    
    return ElevatedButton.icon(
      onPressed: isValid ? onSave : () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cannot save! $remainingCount students are not marked."),
            backgroundColor: DashboardColors.error,
          ),
        );
      },
      icon: const Icon(Icons.save),
      label: const Text("Save"),
      style: ElevatedButton.styleFrom(
        backgroundColor: isValid ? DashboardColors.success : Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
