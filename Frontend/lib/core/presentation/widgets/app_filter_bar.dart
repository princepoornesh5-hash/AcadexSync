import 'package:flutter/material.dart';
import 'acadex_chip.dart';

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

/// Legacy bridge widget delegating to [AcadexFilterBar].
/// Maintained for test compatibility. Prefer using [AcadexFilterBar] directly.
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
    return AcadexFilterBar<T>(
      options: options
          .map((o) => AcadexFilterOption<T>(
                label: o.label,
                value: o.value,
                count: o.count,
              ))
          .toList(),
      selectedValue: selectedValue,
      onSelected: onSelected,
    );
  }
}
