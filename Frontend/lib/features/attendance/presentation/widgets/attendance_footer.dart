import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AttendanceFooter extends StatelessWidget {
  final bool isReadyToSave;
  final VoidCallback onSave;

  const AttendanceFooter({
    super.key,
    required this.isReadyToSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: isReadyToSave ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Review & Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
