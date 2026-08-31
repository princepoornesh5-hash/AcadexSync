import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class DepartmentListScreen extends ConsumerStatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  ConsumerState<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends ConsumerState<DepartmentListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'inactive'

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Departments",
            subtitle: "Manage academic departments, curricula, and departmental leadership.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search departments by name or code...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/departments/new'),
            actionLabel: "Add Department",
          ),
          const SizedBox(height: 10),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (final f in [('all', 'All'), ('active', 'Active'), ('inactive', 'Inactive')])
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
            child: deptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Error: $err", style: const TextStyle(color: AcadexColors.error)),
              ),
              data: (depts) {
                final filtered = depts.where((d) {
                  // Status filter
                  if (_statusFilter == 'active' && !d.isActive) return false;
                  if (_statusFilter == 'inactive' && d.isActive) return false;
                  // Search query
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return d.name.toLowerCase().contains(q) || d.code.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return AcadexEmptyState(
                    title: "No Departments Found",
                    subtitle: _searchQuery.isNotEmpty
                        ? "No departments match '$_searchQuery'."
                        : "Get started by adding the first academic department.",
                    icon: LucideIcons.layers,
                    actionLabel: "Add Department",
                    onActionTap: () => context.push('/academics/departments/new'),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final d = filtered[i];
                      return GestureDetector(
                        onTap: () => context.push('/academics/departments/${d.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: AcadexRadius.borderRadiusLg,
                            border: Border.all(
                              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      d.name,
                                      style: AcadexTypography.body(
                                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: d.isActive
                                          ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                                          : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft),
                                      borderRadius: AcadexRadius.borderRadiusFull,
                                    ),
                                    child: Text(
                                      d.isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: d.isActive ? AcadexColors.success : AcadexColors.inkMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Code: ${d.code}",
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                              if (d.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  d.description,
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                                    tooltip: "View Details",
                                    onPressed: () => context.push('/academics/departments/${d.id}'),
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
                                    tooltip: "Edit Department",
                                    onPressed: () => context.push('/academics/departments/edit/${d.id}'),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                  columns: const ["Code", "Department Name", "Description", "Status", "Actions"],
                  rows: filtered.map((d) {
                    return DataRow(
                      onSelectChanged: (_) => context.push('/academics/departments/${d.id}'),
                      cells: [
                        DataCell(Text(d.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(d.name)),
                        DataCell(
                          Text(
                            d.description.isNotEmpty ? d.description : '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: d.isActive ? AcadexColors.successLight : AcadexColors.canvasSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              d.isActive ? "Active" : "Inactive",
                              style: TextStyle(
                                color: d.isActive ? AcadexColors.success : AcadexColors.inkMuted,
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
                                onPressed: () => context.push('/academics/departments/${d.id}'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18),
                                tooltip: "Edit Department",
                                onPressed: () => context.push('/academics/departments/edit/${d.id}'),
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

class DepartmentFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const DepartmentFormScreen({super.key, this.id});

  @override
  ConsumerState<DepartmentFormScreen> createState() => _DepartmentFormScreenState();
}

class _DepartmentFormScreenState extends ConsumerState<DepartmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  bool _isLoading = false;
  Department? _existing;
  String? _selectedCollegeId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _descCtrl = TextEditingController();

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final depts = await ref.read(departmentsProvider.future);
      _existing = depts.firstWhere((c) => c.id == widget.id);
      _nameCtrl.text = _existing!.name;
      _codeCtrl.text = _existing!.code;
      _descCtrl.text = _existing!.description;
      _selectedCollegeId = _existing!.collegeId;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading department: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String? userCollegeId, bool isSuperAdmin) async {
    if (!_formKey.currentState!.validate()) return;
    
    // For Super Admin without assigned collegeId, college must be selected
    final targetCollegeId = isSuperAdmin && (userCollegeId == null || userCollegeId.isEmpty)
        ? _selectedCollegeId
        : (userCollegeId ?? _selectedCollegeId ?? '');

    if (isSuperAdmin && (targetCollegeId == null || targetCollegeId.isEmpty) && _existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('College is required for Super Admin')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dept = Department(
        id: _existing?.id ?? '',
        collegeId: targetCollegeId ?? '',
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        description: _descCtrl.text.trim(),
        hodId: _existing?.hodId ?? '',
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(departmentsProvider.notifier).addDepartment(dept);
      } else {
        await ref.read(departmentsProvider.notifier).updateDepartment(dept);
        ref.invalidate(departmentByIdProvider(widget.id!));
        ref.invalidate(departmentSummaryProvider(widget.id!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existing == null ? 'Department created successfully' : 'Department updated successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/academics/departments');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AcadexColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isSuperAdmin = user?.role == AppRole.superAdmin;
    final userCollegeId = user?.collegeId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collegesAsync = ref.watch(collegesProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/departments'),
        ),
        title: Text(
          isEdit ? "Edit Department" : "Add Department",
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "Department Details",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/departments'),
                  onSave: () => _save(userCollegeId, isSuperAdmin),
                  child: Column(
                    children: [
                      // Only show College selector if Super Admin is creating a department globally
                      if (isSuperAdmin && (userCollegeId == null || userCollegeId.isEmpty) && !isEdit) ...[
                        AcadexFormField(
                          label: "College *",
                          child: collegesAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => Text('Error loading colleges', style: const TextStyle(color: AcadexColors.error)),
                            data: (colleges) => DropdownButtonFormField<String>(
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              initialValue: _selectedCollegeId,
                              decoration: const InputDecoration(hintText: "Select College"),
                              validator: (v) => v == null ? 'College is required' : null,
                              items: colleges.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _selectedCollegeId = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      AcadexFormField(
                        label: "Department Name *",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Department Name is required';
                            if (v.trim().length < 2) return 'Must be at least 2 characters';
                            if (v.trim().length > 100) return 'Must be at most 100 characters';
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "e.g. Computer Science & Engineering"),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AcadexFormField(
                        label: "Department Code *",
                        child: TextFormField(
                          controller: _codeCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Department Code is required';
                            if (v.trim().length < 2) return 'Must be at least 2 characters';
                            if (v.trim().length > 20) return 'Must be at most 20 characters';
                            final regex = RegExp(r'^[A-Za-z0-9\-_]+$');
                            if (!regex.hasMatch(v.trim())) {
                              return 'Only alphanumeric characters, hyphens, and underscores';
                            }
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "e.g. CSE"),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AcadexFormField(
                        label: "Description (Optional)",
                        child: TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          validator: (v) {
                            if (v != null && v.trim().length > 500) return 'Must be at most 500 characters';
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "Brief description of the department"),
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
