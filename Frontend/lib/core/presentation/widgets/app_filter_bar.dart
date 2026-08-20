import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';

class FilterOption<T> {
  final String label;
  final T value;
  final int? count;

  const FilterOption({
    required this.label,
    required this.value,
    this.count,
  });
}

class AppFilterBar<T> extends StatelessWidget {
  final List<FilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const AppFilterBar({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = option.value == selectedValue;
          return Padding(
            padding: const EdgeInsets.only(right: AcadexSpacing.sm),
            child: ChoiceChip(
              label: Text(
                option.count != null ? '${option.label} (${option.count})' : option.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AcadexColors.textSecondaryLight,
                ),
              ),
              selected: isSelected,
              selectedColor: AcadexColors.primaryNavy,
              backgroundColor: AcadexColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: AcadexRadius.smBorder,
                side: BorderSide(
                  color: isSelected ? AcadexColors.primaryNavy : AcadexColors.borderLight,
                ),
              ),
              onSelected: (_) => onSelected(option.value),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
