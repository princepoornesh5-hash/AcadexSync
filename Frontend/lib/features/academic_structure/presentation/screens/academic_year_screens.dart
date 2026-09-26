import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class AcademicYearListScreen extends ConsumerStatefulWidget {
  const AcademicYearListScreen({super.key});

  @override
  ConsumerState<AcademicYearListScreen> createState() => _AcademicYearListScreenState();
}

class _AcademicYearListScreenState extends ConsumerState<AcademicYearListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'current' | 'active' | 'upcoming' | 'completed'

  void _showSetCurrentDialog(BuildContext context, AcademicYear year) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set as Current Academic Year?"),
        content: Text(
          'Set "${year.name}" as the active ongoing academic year?\n\nAny other current academic year for your college will be automatically unset.',
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Set as Current"),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(academicYearsProvider.notifier).setAsCurrent(year.id);
                if (context.mounted) {
                  AcadexSnackBar.showSuccess(context, '${year.name} is now set as the current academic year.');
                }
              } catch (e) {
                if (context.mounted) {
                  AcadexSnackBar.showError(context, e);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Academic Years",
            subtitle: "Manage institutional academic sessions, calendars, and current cycle tracking.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search academic years...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/academic_years/new'),
            actionLabel: "Create Academic Year",
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (final f in [
                  ('all', 'All'),
                  ('current', 'Current Year'),
                  ('active', 'Active'),
                  ('upcoming', 'Upcoming'),
                  ('completed', 'Completed'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: _statusFilter == f.$1,
                      onSelected: (_) => setState(() => _statusFilter = f.$1),
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AcadexColors.primary,
                      labelStyle: TextStyle(
                        color: _statusFilter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        fontWeight: _statusFilter == f.$1 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _statusFilter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: yearsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => AcadexErrorState.fromError(
                error: err,
                title: "Unable to load academic years",
                onRetry: () => ref.invalidate(academicYearsProvider),
              ),
              data: (years) {
                final filtered = years.where((y) {
                  // Filter logic
                  if (_statusFilter == 'current' && !y.isCurrent) return false;
                  if (_statusFilter == 'active' && (!y.isActive || y.status == 'completed' || y.status == 'archived')) return false;
                  if (_statusFilter == 'upcoming' && y.status != 'upcoming') return false;
                  if (_statusFilter == 'completed' && y.status != 'completed' && y.status != 'archived') return false;

                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return y.name.toLowerCase().contains(q) || y.status.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  if (years.isEmpty) {
                    return AcadexEmptyState(
                      title: "No Academic Years Found",
                      subtitle: "Create an academic session to organize semesters and student cohorts.",
                      icon: LucideIcons.calendar,
                      actionLabel: "Create Academic Year",
                      onActionTap: () => context.push('/academics/academic_years/new'),
                    );
                  }

                  return AcadexEmptyState.filterEmpty(
                    filterSummary: _searchQuery.isNotEmpty ? "query '$_searchQuery'" : "selected filter",
                    onClearFilters: () => setState(() {
                      _searchQuery = '';
                      _statusFilter = 'all';
                    }),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final y = filtered[i];

                      return GestureDetector(
                        onTap: () => context.push('/academics/academic_years/${y.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: AcadexRadius.borderRadiusLg,
                            border: Border.all(
                              color: y.isCurrent
                                  ? AcadexColors.primary
                                  : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                              width: y.isCurrent ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.calendar,
                                        size: 16,
                                        color: y.isCurrent ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        y.name,
                                        style: AcadexTypography.body(
                                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                        ).copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  if (y.isCurrent)
                                    const AcadexBadge(label: "CURRENT", variant: AcadexBadgeVariant.primary)
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: y.isActive
                                            ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                                            : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft),
                                        borderRadius: AcadexRadius.borderRadiusFull,
                                      ),
                                      child: Text(
                                        y.isActive ? "Active" : "Archived",
                                        style: TextStyle(
                                          color: y.isActive ? AcadexColors.success : AcadexColors.inkMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${dateFormat.format(y.startDate)} – ${dateFormat.format(y.endDate)}",
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (!y.isCurrent)
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        minimumSize: const Size(50, 28),
                                      ),
                                      icon: const Icon(LucideIcons.checkCircle, size: 14),
                                      label: const Text("Set as Current", style: TextStyle(fontSize: 12)),
                                      onPressed: () => _showSetCurrentDialog(context, y),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                                        tooltip: "View Details",
                                        onPressed: () => context.push('/academics/academic_years/${y.id}'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: Icon(
                                          LucideIcons.edit,
                                          size: 18,
                                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                        ),
                                        tooltip: "Edit Academic Year",
                                        onPressed: () => context.push('/academics/academic_years/edit/${y.id}'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return AcadexDataTable(
                  columns: const ["Academic Year", "Start Date", "End Date", "Current Session", "Status", "Actions"],
                  rows: filtered.map((y) {
                    return DataRow(
                      onSelectChanged: (_) => context.push('/academics/academic_years/${y.id}'),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Icon(LucideIcons.calendar, size: 16, color: y.isCurrent ? AcadexColors.primary : AcadexColors.inkMuted),
                              const SizedBox(width: 8),
                              Text(y.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(Text(dateFormat.format(y.startDate))),
                        DataCell(Text(dateFormat.format(y.endDate))),
                        DataCell(
                          y.isCurrent
                              ? const AcadexBadge(label: "CURRENT", variant: AcadexBadgeVariant.primary)
                              : TextButton(
                                  child: const Text("Set as Current"),
                                  onPressed: () => _showSetCurrentDialog(context, y),
                                ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: y.isActive ? AcadexColors.successLight : AcadexColors.canvasSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              y.isActive ? "Active" : "Archived",
                              style: TextStyle(
                                color: y.isActive ? AcadexColors.success : AcadexColors.inkMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.eye, size: 18),
                                tooltip: "View Details",
                                onPressed: () => context.push('/academics/academic_years/${y.id}'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18),
                                tooltip: "Edit",
                                onPressed: () => context.push('/academics/academic_years/edit/${y.id}'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AcademicYearFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const AcademicYearFormScreen({super.key, this.id});

  @override
  ConsumerState<AcademicYearFormScreen> createState() => _AcademicYearFormScreenState();
}

class _AcademicYearFormScreenState extends ConsumerState<AcademicYearFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _isLoading = false;
  AcademicYear? _existing;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    final now = DateTime.now();
    _startDate = AcademicYearDateUtils.toUtcDate(DateTime(now.year, 6, 1));
    _endDate = AcademicYearDateUtils.toUtcDate(DateTime(now.year + 1, 5, 31));

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final years = await ref.read(academicYearsProvider.future);
      _existing = years.firstWhere((y) => y.id == widget.id);
      _nameCtrl.text = _existing!.name;
      _startDate = AcademicYearDateUtils.toUtcDate(_existing!.startDate);
      _endDate = AcademicYearDateUtils.toUtcDate(_existing!.endDate);
      _isCurrent = _existing!.isCurrent;
    } catch (e) {
      if (mounted) AcadexSnackBar.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final currentVal = isStart ? _startDate : _endDate;
    final initial = currentVal != null
        ? DateTime(currentVal.year, currentVal.month, currentVal.day)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        final normalized = AcademicYearDateUtils.toUtcDate(picked);
        if (isStart) {
          _startDate = normalized;
        } else {
          _endDate = normalized;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      AcadexSnackBar.showWarning(context, 'Start Date and End Date are required.');
      return;
    }
    if (!AcademicYearDateUtils.isRangeValid(_startDate!, _endDate!)) {
      AcadexSnackBar.showWarning(context, 'End Date must be after Start Date.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ay = AcademicYear(
        id: _existing?.id ?? '',
        collegeId: _existing?.collegeId ?? '',
        name: _nameCtrl.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        status: _isCurrent ? 'active' : (_existing?.status ?? 'upcoming'),
        isCurrent: _isCurrent,
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(academicYearsProvider.notifier).addAcademicYear(ay);
      } else {
        await ref.read(academicYearsProvider.notifier).updateAcademicYear(ay);
        ref.invalidate(academicYearByIdProvider(widget.id!));
      }

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          _existing == null ? 'Academic Year created successfully.' : 'Academic Year updated successfully.',
        );
        context.safePop(fallbackRoute: '/academics/academic-years');
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/academic-years'),
        ),
        title: Text(
          isEdit ? "Edit Academic Year" : "Create Academic Year",
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: (isEdit && _existing == null && _isLoading)
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: isEdit ? "Edit Academic Year" : "Academic Year Details",
                  isSaving: _isLoading,
                  saveLabel: isEdit ? "Update Academic Year" : "Create Academic Year",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/academic-years'),
                  onSave: _save,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AcadexFormField(
                        label: "Academic Year Name *",
                        child: TextFormField(
                          key: const Key('academic_year_name_input'),
                          controller: _nameCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Academic Year Name is required';
                            if (v.trim().length < 4) return 'Must be at least 4 characters (e.g. 2026-2027)';
                            if (v.trim().length > 50) return 'Must be at most 50 characters';
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "e.g. 2026–2027"),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Start Date *",
                              child: InkWell(
                                key: const Key('academic_year_start_date_btn'),
                                onTap: () => _pickDate(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                    ),
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _startDate != null ? dateFormat.format(_startDate!) : "Select Date",
                                          style: AcadexTypography.body(
                                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(LucideIcons.calendar, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AcadexFormField(
                              label: "End Date *",
                              child: InkWell(
                                key: const Key('academic_year_end_date_btn'),
                                onTap: () => _pickDate(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                    ),
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _endDate != null ? dateFormat.format(_endDate!) : "Select Date",
                                          style: AcadexTypography.body(
                                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(LucideIcons.calendar, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                          borderRadius: AcadexRadius.borderRadiusMd,
                          border: Border.all(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: SwitchListTile(
                            key: const Key('academic_year_current_switch'),
                            contentPadding: EdgeInsets.zero,
                            value: _isCurrent,
                            activeThumbColor: AcadexColors.primary,
                            title: Text(
                              "Set as Current Academic Year",
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              "Setting this as current will automatically unset any existing current academic year in this college.",
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontSize: 11),
                            ),
                            onChanged: (v) => setState(() => _isCurrent = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
