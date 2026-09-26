import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class CollegeListScreen extends ConsumerStatefulWidget {
  const CollegeListScreen({super.key});

  @override
  ConsumerState<CollegeListScreen> createState() => _CollegeListScreenState();
}

class _CollegeListScreenState extends ConsumerState<CollegeListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'inactive'

  void _confirmDeleteCollege(BuildContext context, College college) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: 440),
        title: const Text('Permanently Delete College?'),
        content: Text(
          'Are you sure you want to permanently delete "${college.name}" (${college.code})? '
          'This will permanently delete all departments, courses, academic data, and users associated with this college. '
          'This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(collegesProvider.notifier).deleteCollegePermanently(college.id);
                if (context.mounted) {
                  AcadexSnackBar.showSuccess(
                    context,
                    'College "${college.name}" deleted permanently',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AcadexSnackBar.showError(
                    context,
                    e,
                    fallbackMessage: 'Failed to delete college',
                  );
                }
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collegesAsync = ref.watch(collegesProvider);
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState is AuthAuthenticated && authState.user.role == AppRole.superAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Colleges",
            subtitle: "Manage registered institutions and campus details.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search colleges by name or code...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/colleges/new'),
            actionLabel: "Add College",
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
            child: collegesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => AcadexErrorState.fromError(
                error: err,
                title: "Unable to load colleges",
                onRetry: () => ref.invalidate(collegesProvider),
              ),
              data: (colleges) {
                final filtered = colleges.where((c) {
                  // Status filter
                  if (_statusFilter == 'active' && !c.isActive) return false;
                  if (_statusFilter == 'inactive' && c.isActive) return false;
                  // Search filter
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(q) ||
                      c.code.toLowerCase().contains(q) ||
                      c.principal.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  if (colleges.isNotEmpty) {
                    return AcadexEmptyState.filterEmpty(
                      title: "No colleges match criteria",
                      subtitle: "Try clearing search or filters to see all colleges.",
                      onClearFilters: () {
                        setState(() {
                          _searchQuery = '';
                          _statusFilter = 'all';
                        });
                      },
                    );
                  }
                  return AcadexEmptyState(
                    title: "No Colleges Found",
                    subtitle: "Get started by adding the first college.",
                    icon: LucideIcons.building,
                    actionLabel: "Add College",
                    onActionTap: () => context.push('/academics/colleges/new'),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return GestureDetector(
                        onTap: () => context.push('/academics/colleges/${c.id}'),
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
                                      c.name,
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
                                      color: c.isActive
                                          ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                                          : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft),
                                      borderRadius: AcadexRadius.borderRadiusFull,
                                    ),
                                    child: Text(
                                      c.isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: c.isActive ? AcadexColors.success : AcadexColors.inkMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Code: ${c.code} • ${c.principal}",
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                              if (c.email.isNotEmpty || c.phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "${c.email}${c.phone.isNotEmpty ? ' • ${c.phone}' : ''}",
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
                                    icon: Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                                    tooltip: "View Details",
                                    onPressed: () => context.push('/academics/colleges/${c.id}'),
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
                                    tooltip: "Edit College",
                                    onPressed: () => context.push('/academics/colleges/edit/${c.id}'),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  if (isSuperAdmin) ...[
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.error),
                                      tooltip: "Delete College",
                                      onPressed: () => _confirmDeleteCollege(context, c),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
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
                  columns: const ["Code", "Name", "Principal", "Email", "Phone", "Status", "Actions"],
                  rows: filtered.map((c) => DataRow(
                    cells: [
                      DataCell(Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(c.name)),
                      DataCell(Text(c.principal)),
                      DataCell(Text(c.email)),
                      DataCell(Text(c.phone)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.isActive ? AcadexColors.successLight : AcadexColors.canvasSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.isActive ? "Active" : "Inactive",
                            style: TextStyle(
                              color: c.isActive ? AcadexColors.success : AcadexColors.inkMuted,
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
                              onPressed: () => context.push('/academics/colleges/${c.id}'),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.edit, size: 18),
                              tooltip: "Edit College",
                              onPressed: () => context.push('/academics/colleges/edit/${c.id}'),
                            ),
                            if (isSuperAdmin)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.error),
                                tooltip: "Delete College",
                                onPressed: () => _confirmDeleteCollege(context, c),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CollegeFormScreen extends ConsumerStatefulWidget {
  final String? collegeId;
  const CollegeFormScreen({super.key, this.collegeId});

  @override
  ConsumerState<CollegeFormScreen> createState() => _CollegeFormScreenState();
}

class _CollegeFormScreenState extends ConsumerState<CollegeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _principalCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _isLoading = false;
  College? _existing;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _principalCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();

    if (widget.collegeId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      College? college;
      try {
        college = await ref.read(collegeByIdProvider(widget.collegeId!).future);
      } catch (_) {
        college = await ref.read(academicRepositoryProvider).getCollegeById(widget.collegeId!);
      }
      
      if (college != null && mounted) {
        _existing = college;
        _nameCtrl.text = college.name;
        _codeCtrl.text = college.code;
        _principalCtrl.text = college.principal;
        _emailCtrl.text = college.email;
        _phoneCtrl.text = college.phone;
        _addressCtrl.text = college.address;
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to load college details',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _principalCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final college = College(
        // id is ignored on create (backend assigns _id), required for update
        id: _existing?.id ?? widget.collegeId ?? '',
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        principal: _principalCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null && widget.collegeId == null) {
        await ref.read(collegesProvider.notifier).addCollege(college);
      } else {
        await ref.read(collegesProvider.notifier).updateCollege(college);
        if (widget.collegeId != null) {
          ref.invalidate(collegeByIdProvider(widget.collegeId!));
          ref.invalidate(collegeSummaryProvider(widget.collegeId!));
        }
      }

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          (_existing == null && widget.collegeId == null)
              ? 'College created successfully'
              : 'College updated successfully',
        );
        context.safePop(fallbackRoute: '/academics/colleges');
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to save college',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.collegeId != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.safePop(fallbackRoute: '/academics/colleges'),
        ),
        title: Text(isEdit ? "Edit College" : "Add College", style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: AcadexFormCard(
                  title: "College Details",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/colleges'),
                  onSave: _save,
                  child: Column(
                    children: [
                      AcadexFormField(
                        label: "College Name",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. Global Institute of Technology"),
                        ),
                      ),
                      AcadexFormField(
                        label: "College Code",
                        child: TextFormField(
                          controller: _codeCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. GIT"),
                        ),
                      ),
                      AcadexFormField(
                        label: "Principal Name",
                        child: TextFormField(
                          controller: _principalCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. Dr. Smith"),
                        ),
                      ),
                      AcadexFormField(
                        label: "Address",
                        child: TextFormField(
                          controller: _addressCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: "e.g. 123 University Ave"),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Email",
                              child: TextFormField(
                                controller: _emailCtrl,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "e.g. admin@college.edu"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AcadexFormField(
                              label: "Phone",
                              child: TextFormField(
                                controller: _phoneCtrl,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                                style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                                decoration: const InputDecoration(hintText: "e.g. 9876543210"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
