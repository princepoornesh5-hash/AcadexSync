import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';

class AppSearchField extends StatefulWidget {
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
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final has = _controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search, size: 20, color: AcadexColors.textMutedLight),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: AcadexColors.textMutedLight),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                  widget.onClear?.call();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: AcadexColors.surfaceLight,
        border: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.borderLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.emeraldTeal, width: 1.5),
        ),
      ),
    );
  }
}
