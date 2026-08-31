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
import '../../../auth/domain/models/user_model.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';
import 'activation_result_screen.dart';

class HodListScreen extends ConsumerStatefulWidget {
  const HodListScreen({super.key});

  @override
  ConsumerState<HodListScreen> createState() => _HodListScreenState();
}

class _HodListScreenState extends ConsumerState<HodListScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // 'all' | 'active' | 'pending'

  @override
  Widget build(BuildContext context) {
    final hodsAsync = ref.watch(hodsProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final deptsMap = {for (final d in deptsAsync.valueOrNull ?? <Department>[]) d.id: d.name};

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Department Heads (HODs)",
            subtitle: "Provision academic department leaders, manage credentials, and monitor department metrics.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search HODs by name, PIN number, or email...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/hods/provision'),
            actionLabel: "Provision HOD",
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                for (final f in [
                  ('all', 'All HODs'),
                  ('active', 'Active Leaders'),
                  ('pending', 'Pending Activation'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) => setState(() => _filter = f.$1),
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AcadexColors.primary,
                      labelStyle: TextStyle(
                        color: _filter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        fontWeight: _filter == f.$1 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _filter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: hodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Error: $err", style: const TextStyle(color: AcadexColors.error)),
              ),
              data: (hods) {
                final filtered = hods.where((h) {
                  if (_filter == 'active' && h.accountStatus != AccountStatus.active) return false;
                  if (_filter == 'pending' && h.accountStatus != AccountStatus.pendingActivation) return false;

                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final deptName = (deptsMap[h.departmentId ?? ''] ?? '').toLowerCase();
                  return h.name.toLowerCase().contains(q) ||
                      (h.instituteId ?? '').toLowerCase().contains(q) ||
                      h.email.toLowerCase().contains(q) ||
                      deptName.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return AcadexEmptyState(
                    title: "No Department Heads Found",
                    subtitle: _searchQuery.isNotEmpty
                        ? "No HODs match '$_searchQuery'."
                        : "Provision a Head of Department to lead academic departments and curriculum.",
                    icon: LucideIcons.userCheck,
                    actionLabel: "Provision HOD",
                    onActionTap: () => context.push('/academics/hods/provision'),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final h = filtered[i];
                      final deptName = deptsMap[h.departmentId ?? ''] ?? 'Unassigned Dept';
                      final isPending = h.accountStatus == AccountStatus.pendingActivation;

                      return GestureDetector(
                        onTap: () => context.push('/academics/hods/${h.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: AcadexRadius.borderRadiusLg,
                            border: Border.all(
                              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AcadexColors.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            h.instituteId ?? 'HOD',
                                            style: const TextStyle(
                                              color: AcadexColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            h.name,
                                            style: AcadexTypography.body(
                                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                            ).copyWith(fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? AcadexColors.warningLight
                                          : (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight),
                                      borderRadius: AcadexRadius.borderRadiusFull,
                                    ),
                                    child: Text(
                                      isPending ? "Pending Activation" : "Active",
                                      style: TextStyle(
                                        color: isPending ? AcadexColors.warning : AcadexColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(LucideIcons.building2, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      deptName,
                                      style: AcadexTypography.caption(
                                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(LucideIcons.mail, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      h.email,
                                      style: AcadexTypography.caption(
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.arrowRight, size: 16, color: AcadexColors.primary),
                                    tooltip: "View Details",
                                    onPressed: () => context.push('/academics/hods/${h.id}'),
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
                                    tooltip: "Edit Profile",
                                    onPressed: () => context.push('/academics/hods/edit/${h.id}'),
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
                  columns: const ["HOD Name", "PIN Number", "Department", "Email Address", "Phone", "Account Status", "Actions"],
                  rows: filtered.map((h) {
                    final isPending = h.accountStatus == AccountStatus.pendingActivation;
                    return DataRow(
                      onSelectChanged: (_) => context.push('/academics/hods/${h.id}'),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              const Icon(LucideIcons.userCheck, size: 16, color: AcadexColors.primary),
                              const SizedBox(width: 8),
                              Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              h.instituteId ?? '—',
                              style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(Text(deptsMap[h.departmentId ?? ''] ?? h.departmentId ?? 'Unassigned')),
                        DataCell(Text(h.email)),
                        DataCell(Text(h.phone ?? '—')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending ? AcadexColors.warningLight : AcadexColors.successLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPending ? "Pending Activation" : "Active",
                              style: TextStyle(
                                color: isPending ? AcadexColors.warning : AcadexColors.success,
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
                                onPressed: () => context.push('/academics/hods/${h.id}'),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 18),
                                tooltip: "Edit Profile",
                                onPressed: () => context.push('/academics/hods/edit/${h.id}'),
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

class ProvisionHodScreen extends ConsumerStatefulWidget {
  final String? initialDepartmentId;
  const ProvisionHodScreen({super.key, this.initialDepartmentId});

  @override
  ConsumerState<ProvisionHodScreen> createState() => _ProvisionHodScreenState();
}

class _ProvisionHodScreenState extends ConsumerState<ProvisionHodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _instituteIdCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  String? _selectedDepartmentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _instituteIdCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _selectedDepartmentId = widget.initialDepartmentId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instituteIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active department'), backgroundColor: AcadexColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final depts = await ref.read(departmentsProvider.future);
      final dept = depts.firstWhere((d) => d.id == _selectedDepartmentId);

      College? college;
      if (dept.collegeId.isNotEmpty) {
        try {
          college = await ref.read(collegeByIdProvider(dept.collegeId).future);
        } catch (_) {}
      }
      final actualCollegeCode = college?.code ?? '';
      final actualCollegeName = college?.name ?? "Department of ${dept.name}";

      final result = await ref.read(hodsProvider.notifier).provisionHod(
        departmentId: _selectedDepartmentId!,
        name: _nameCtrl.text.trim(),
        instituteId: _instituteIdCtrl.text.trim().toUpperCase(),
        email: _emailCtrl.text.trim().toLowerCase(),
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      );

      final enrichedResult = result.copyWith(
        collegeCode: actualCollegeCode,
        departmentName: dept.name,
      );

      if (mounted) {
        // Navigate to ActivationResultScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ActivationResultScreen(
              result: ProvisionAdminResult(
                activationCode: enrichedResult.activationCode,
                adminName: enrichedResult.user.name,
                adminInstituteId: enrichedResult.user.instituteId ?? '',
                adminEmail: enrichedResult.user.email,
                adminPhone: enrichedResult.user.phone,
                collegeName: actualCollegeName,
                collegeCode: actualCollegeCode,
                invitationId: enrichedResult.invitationId,
                expiresAt: enrichedResult.expiresAt,
              ),
            ),
          ),
        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/hods'),
        ),
        title: Text(
          "Provision Department Head (HOD)",
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
                  title: "HOD Credentials & Department Assignment",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/hods'),
                  onSave: _submit,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department Selector
                      AcadexFormField(
                        label: "Assigned Department *",
                        child: departmentsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading departments: $e', style: const TextStyle(color: AcadexColors.error)),
                          data: (depts) {
                            final activeDepts = depts.where((d) => d.isActive).toList();
                            if (activeDepts.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.warningLight,
                                  borderRadius: AcadexRadius.borderRadiusMd,
                                  border: Border.all(color: AcadexColors.warning),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("No Active Departments", style: TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.warning)),
                                    const SizedBox(height: 4),
                                    const Text("You must create an active department before provisioning an HOD."),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => context.push('/academics/departments/new'),
                                      child: const Text("Create Department"),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              value: _selectedDepartmentId,
                              decoration: const InputDecoration(hintText: "Select Academic Department"),
                              validator: (v) => v == null ? 'Department is required' : null,
                              items: activeDepts.map((d) => DropdownMenuItem(value: d.id, child: Text("${d.name} (${d.code})"))).toList(),
                              onChanged: (v) => setState(() => _selectedDepartmentId = v),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Full Name
                      AcadexFormField(
                        label: "Full Name (with Title) *",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            if (v.trim().length < 2) return 'Min 2 characters';
                            if (v.trim().length > 100) return 'Max 100 characters';
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "e.g. Dr. Alan Turing"),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // PIN Number & Phone Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "HOD PIN Number *",
                              child: TextFormField(
                                controller: _instituteIdCtrl,
                                textCapitalization: TextCapitalization.characters,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'PIN Number is required';
                                  if (v.trim().length < 2) return 'Min 2 characters';
                                  if (v.trim().length > 50) return 'Max 50 characters';
                                  return null;
                                },
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "e.g. HOD-CS-01"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AcadexFormField(
                              label: "Phone Number (Optional)",
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(hintText: "9876543210"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Official Email Address
                      AcadexFormField(
                        label: "Official Academic Email *",
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          decoration: const InputDecoration(hintText: "hod.cs@college.edu"),
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

class HodEditScreen extends ConsumerStatefulWidget {
  final String id;
  const HodEditScreen({super.key, required this.id});

  @override
  ConsumerState<HodEditScreen> createState() => _HodEditScreenState();
}

class _HodEditScreenState extends ConsumerState<HodEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final hod = await ref.read(hodByIdProvider(widget.id).future);
      _nameCtrl.text = hod.name;
      _emailCtrl.text = hod.email;
      _phoneCtrl.text = hod.phone ?? '';
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading HOD: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(hodsProvider.notifier).updateProfile(
        widget.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HOD profile updated successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/academics/hods');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/hods'),
        ),
        title: Text(
          "Edit HOD Profile",
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
                  title: "Update Contact Information",
                  onCancel: () => context.safePop(fallbackRoute: '/academics/hods'),
                  onSave: _save,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AcadexFormField(
                        label: "Full Name *",
                        child: TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AcadexFormField(
                        label: "Email Address *",
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AcadexFormField(
                        label: "Phone Number",
                        child: TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
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
