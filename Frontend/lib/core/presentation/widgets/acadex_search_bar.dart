import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../features/auth/domain/models/auth_state.dart';
import '../../../features/auth/domain/models/role_enum.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class AcadexSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const AcadexSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AcadexSearchBar> createState() => _AcadexSearchBarState();
}

class _AcadexSearchBarState extends State<AcadexSearchBar> {
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
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AcadexColors.ink,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AcadexColors.inkMuted,
        ),
        prefixIcon: const Icon(LucideIcons.search, size: 18, color: AcadexColors.inkMuted),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(LucideIcons.x, size: 16, color: AcadexColors.inkMuted),
                tooltip: 'Clear search',
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                  widget.onClear?.call();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: AcadexColors.surface,
        border: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class AcadexSearchFilterBar extends ConsumerWidget {
  final String searchHint;
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterTap;
  final String actionLabel;
  final VoidCallback? onActionTap;

  const AcadexSearchFilterBar({
    super.key,
    this.searchHint = "Search...",
    required this.onSearchChanged,
    this.onFilterTap,
    this.actionLabel = "Add New",
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSmallMobile = AcadexBreakpoints.isSmallMobile(context);
    final authState = ref.watch(authProvider);
    final isGradientRole = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.superAdmin ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.student);

    const bg = AcadexColors.surface;
    const border = AcadexColors.hairline;
    const textColor = AcadexColors.ink;
    const hintColor = AcadexColors.inkMuted;
    final actionBtnBg = isGradientRole ? AcadexColors.superAdminDeepAction : AcadexColors.primary;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(color: border, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(LucideIcons.search, color: hintColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: AcadexTypography.body(color: textColor),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: AcadexTypography.body(color: hintColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onFilterTap,
            borderRadius: AcadexRadius.borderRadiusMd,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: border, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.filter, color: textColor, size: 18),
                  if (!isSmallMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      "Filter",
                      style: AcadexTypography.bodySmall(color: textColor).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (onActionTap != null) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onActionTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: actionBtnBg,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(44, 46),
              padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 12 : 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.plus, size: 18, color: Colors.white),
                if (!isSmallMobile) ...[
                  const SizedBox(width: 6),
                  Text(
                    actionLabel,
                    style: AcadexTypography.button(color: Colors.white).copyWith(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ]
      ],
    );
  }
}
