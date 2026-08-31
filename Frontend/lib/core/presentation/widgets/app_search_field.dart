import 'package:flutter/material.dart';
import 'acadex_search_bar.dart';

/// Legacy bridge widget delegating to [AcadexSearchBar].
/// Maintained for test compatibility. Prefer using [AcadexSearchBar] directly.
class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const AppSearchField({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexSearchBar(
      hintText: hintText,
      onChanged: onChanged,
      onClear: onClear,
      controller: controller,
    );
  }
}
