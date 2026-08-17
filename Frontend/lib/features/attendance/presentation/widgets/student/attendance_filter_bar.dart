import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';

class AttendanceFilterBar extends StatelessWidget {
  final List<String> subjects;
  final String? selectedSubject;
  final ValueChanged<String?> onSubjectSelected;
  
  final int? selectedMonth;
  final ValueChanged<int?> onMonthSelected;

  const AttendanceFilterBar({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.onSubjectSelected,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildChip(
                label: "All Subjects",
                isSelected: selectedSubject == null,
                onTap: () => onSubjectSelected(null),
              ),
              const SizedBox(width: 8),
              ...subjects.map((sub) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  label: sub,
                  isSelected: selectedSubject == sub,
                  onTap: () => onSubjectSelected(sub),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Month Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildChip(
                label: "All Time",
                isSelected: selectedMonth == null,
                onTap: () => onMonthSelected(null),
              ),
              const SizedBox(width: 8),
              ...List.generate(12, (index) {
                final m = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(
                    label: months[index],
                    isSelected: selectedMonth == m,
                    onTap: () => onMonthSelected(m),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DashboardColors.primary : DashboardColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? DashboardColors.primary : DashboardColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : DashboardColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
