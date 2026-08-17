import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/models/assigned_class.dart';
import '../../../../app/theme/app_theme.dart';

class AssignedClassCard extends StatelessWidget {
  final AssignedClass assignedClass;
  final VoidCallback onTap;

  const AssignedClassCard({
    super.key,
    required this.assignedClass,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Time Slot Column
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: DashboardColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.clock, color: DashboardColors.primary, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      assignedClass.timeSlot.split(' - ')[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: DashboardColors.primary),
                    ),
                    Text(
                      assignedClass.timeSlot.split(' - ')[1],
                      style: const TextStyle(fontSize: 12, color: DashboardColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Class Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignedClass.subjectName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${assignedClass.sectionName} • ${assignedClass.semester}",
                      style: const TextStyle(color: DashboardColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (assignedClass.isAttendanceMarked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: DashboardColors.successLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: DashboardColors.success),
                                const SizedBox(width: 4),
                                const Text("Marked", style: TextStyle(color: DashboardColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: DashboardColors.warningLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pending_actions, size: 14, color: DashboardColors.warning),
                                const SizedBox(width: 4),
                                const Text("Pending", style: TextStyle(color: DashboardColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
