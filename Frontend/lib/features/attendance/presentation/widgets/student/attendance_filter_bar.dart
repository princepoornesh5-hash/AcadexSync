import 'package:flutter/material.dart';
import '../../../../../core/presentation/widgets/acadex_chip.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              AcadexChip(
                label: "All Subjects",
                isSelected: selectedSubject == null,
                onSelected: (_) => onSubjectSelected(null),
              ),
              const SizedBox(width: 8),
              ...subjects.map((sub) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AcadexChip(
                  label: sub,
                  isSelected: selectedSubject == sub,
                  onSelected: (selected) => onSubjectSelected(selected ? sub : null),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 10),
        
        // Month Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              AcadexChip(
                label: "All Months",
                isSelected: selectedMonth == null,
                onSelected: (_) => onMonthSelected(null),
              ),
              const SizedBox(width: 8),
              ...List.generate(12, (index) {
                final m = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AcadexChip(
                    label: months[index],
                    isSelected: selectedMonth == m,
                    onSelected: (selected) => onMonthSelected(selected ? m : null),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
