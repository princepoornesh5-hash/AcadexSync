import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class AcademicYearListScreen extends ConsumerWidget {
  const AcademicYearListScreen({super.key});

  void _showActivationDialog(BuildContext context, WidgetRef ref, AcademicYear year) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
        title: Text("Set Current Academic Year", style: AcadexTypography.heading3(color: Theme.of(ctx).colorScheme.onSurface)),
        content: Text(
          'Set "${year.name}" as the current academic year?\n\nThe previous current academic year will be marked as completed.',
          style: AcadexTypography.body(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8)),
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
            child: const Text("Confirm Activation"),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(academicYearsProvider.notifier).activateAcademicYear(year.collegeId, year.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${year.name} is now the active academic year.'),
                      backgroundColor: AcadexColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.warning),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final theme = Theme.of(context);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Academic Years",
            subtitle: "Manage academic sessions and cycles for your college.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search academic years...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/academic_years/new'),
            actionLabel: "Add Academic Year",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: yearsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: theme.primaryColor)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AcadexColors.warning))),
              data: (years) => AcadexDataTable(
                columns: const ["Academic Year", "Start Date", "End Date", "Status", "Current", "Actions"],
                rows: years.map((y) {
                  final isCurrent = y.isCurrent || y.status == 'active';
                  AcadexBadgeVariant statusVariant;
                  if (y.status == 'active') {
                    statusVariant = AcadexBadgeVariant.success;
                  } else if (y.status == 'upcoming') {
                    statusVariant = AcadexBadgeVariant.info;
                  } else if (y.status == 'completed') {
                    statusVariant = AcadexBadgeVariant.neutral;
                  } else {
                    statusVariant = AcadexBadgeVariant.warning;
                  }

                  return DataRow(cells: [
                    DataCell(
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 16, color: isCurrent ? AcadexColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Text(y.name, style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(Text(y.startDate.toString().split(' ')[0])),
                    DataCell(Text(y.endDate.toString().split(' ')[0])),
                    DataCell(AcadexBadge(label: y.status.toUpperCase(), variant: statusVariant)),
                    DataCell(
                      isCurrent
                          ? const AcadexBadge(label: "CURRENT", variant: AcadexBadgeVariant.primary)
                          : TextButton(
                              child: const Text("Set Current"),
                              onPressed: () => _showActivationDialog(context, ref, y),
                            ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.edit, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            onPressed: () => context.push('/academics/academic_years/edit/${y.id}'),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning),
                            onPressed: () async {
                              await ref.read(academicYearsProvider.notifier).deactivateAcademicYear(y.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Academic Years",
                  subtitle: "Create an academic session to organize semesters and batches.",
                  icon: LucideIcons.calendar,
                  actionLabel: "Add Academic Year",
                  onActionTap: () => context.push('/academics/academic_years/new'),
                ),
              ),
            ),
          )
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
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  String _selectedStatus = 'upcoming';
  bool _isCurrent = false;
  bool _isLoading = false;
  AcademicYear? _existing;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _startCtrl = TextEditingController();
    _endCtrl = TextEditingController();

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
      _startCtrl.text = _existing!.startDate.toIso8601String().split('T').first;
      _endCtrl.text = _existing!.endDate.toIso8601String().split('T').first;
      _selectedStatus = _existing!.status;
      _isCurrent = _existing!.isCurrent;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading academic year: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final collegeId = authState is AuthAuthenticated ? authState.user.collegeId ?? 'c1' : 'c1';

      final start = DateTime.parse(_startCtrl.text.trim());
      final end = DateTime.parse(_endCtrl.text.trim());

      if (!end.isAfter(start)) {
        throw Exception("End date must be strictly after start date.");
      }

      final ay = AcademicYear(
        id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        collegeId: _existing?.collegeId ?? collegeId,
        name: _nameCtrl.text.trim(),
        startDate: start,
        endDate: end,
        status: _isCurrent ? 'active' : _selectedStatus,
        isCurrent: _isCurrent,
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(academicYearsProvider.notifier).addAcademicYear(ay);
      } else {
        await ref.read(academicYearsProvider.notifier).updateAcademicYear(ay);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Academic Year saved successfully'), backgroundColor: AcadexColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.warning));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? "Edit Academic Year" : "Add Academic Year", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Academic Year Details",
                  onCancel: () => context.pop(),
                  onSave: _save,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AcadexFormField(
                        label: "Academic Year Name",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. 2026–27 or 2027–28"),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Start Date",
                              child: TextFormField(
                                controller: _startCtrl,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "YYYY-MM-DD"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AcadexFormField(
                              label: "End Date",
                              child: TextFormField(
                                controller: _endCtrl,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "YYYY-MM-DD"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AcadexFormField(
                        label: "Status",
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'upcoming', child: Text("Upcoming")),
                            DropdownMenuItem(value: 'active', child: Text("Active")),
                            DropdownMenuItem(value: 'completed', child: Text("Completed")),
                            DropdownMenuItem(value: 'archived', child: Text("Archived")),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedStatus = v;
                                if (v == 'active') _isCurrent = true;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _isCurrent,
                        title: Text("Set as Current Active Year", style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text("Only one academic year can be active per college at a time.", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        onChanged: (checked) {
                          setState(() {
                            _isCurrent = checked ?? false;
                            if (_isCurrent) _selectedStatus = 'active';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

