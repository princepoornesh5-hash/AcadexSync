import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final deptMap = ref.watch(departmentMapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isHod = user?.role == AppRole.hod;
    final userDeptId = user?.departmentId ?? '';

    final canManageRooms = user?.role == AppRole.superAdmin ||
        user?.role == AppRole.collegeAdmin ||
        user?.role == AppRole.hod;

    final terminology = ref.watch(terminologyProvider);
    final roomLabel = terminology.roomName();
    final roomsLabel = terminology.roomName(plural: true);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexPageHeader(
            title: roomsLabel,
            subtitle: "Manage classrooms, lecture halls, laboratories, and seating capacities.",
            actions: [
              if (canManageRooms)
                AcadexButton(
                  key: const Key('add_room_header_btn'),
                  label: "Add $roomLabel",
                  icon: LucideIcons.plus,
                  size: AcadexButtonSize.sm,
                  onPressed: () => context.push('/academics/rooms/new'),
                ),
            ],
          ),
          AcadexSearchFilterBar(
            searchHint: "Search ${roomsLabel.toLowerCase()} by code, name, or department...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: canManageRooms ? () => context.push('/academics/rooms/new') : null,
            actionLabel: "Add $roomLabel",
          ),
          const SizedBox(height: 10),

          // Filters: Room Type and Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                // Type Filter Chips
                for (final t in [
                  ('all', 'All Types'),
                  ('lecture', 'Lecture Hall'),
                  ('lab', 'Laboratory'),
                  ('seminar', 'Seminar Room'),
                  ('other', 'Other'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(t.$2),
                      selected: _typeFilter == t.$1,
                      onSelected: (_) => setState(() => _typeFilter = t.$1),
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AcadexColors.primary,
                      labelStyle: TextStyle(
                        color: _typeFilter == t.$1
                            ? AcadexColors.primary
                            : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        fontWeight: _typeFilter == t.$1 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _typeFilter == t.$1
                            ? AcadexColors.primary
                            : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),
                // Status Filter Chips
                for (final s in [
                  ('all', 'All Status'),
                  ('active', 'Active'),
                  ('inactive', 'Inactive'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.$2),
                      selected: _statusFilter == s.$1,
                      onSelected: (_) => setState(() => _statusFilter = s.$1),
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AcadexColors.primary,
                      labelStyle: TextStyle(
                        color: _statusFilter == s.$1
                            ? AcadexColors.primary
                            : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        fontWeight: _statusFilter == s.$1 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _statusFilter == s.$1
                            ? AcadexColors.primary
                            : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => AcadexErrorState.fromError(
                error: err,
                title: "Unable to load $roomsLabel",
                onRetry: () => ref.invalidate(roomsProvider),
              ),
              data: (rooms) {
                final filtered = rooms.where((r) {
                  // HOD scoping: see department-specific rooms or campus-wide shared rooms
                  if (isHod && userDeptId.isNotEmpty) {
                    if (r.departmentId != null && r.departmentId!.isNotEmpty && r.departmentId != userDeptId) {
                      return false;
                    }
                  }

                  // Type filter
                  if (_typeFilter != 'all' && r.type.toLowerCase() != _typeFilter) {
                    return false;
                  }

                  // Status filter
                  if (_statusFilter == 'active' && !r.isActive) return false;
                  if (_statusFilter == 'inactive' && r.isActive) return false;

                  // Search query
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final deptName = r.departmentId != null ? (deptMap[r.departmentId]?.name ?? '') : 'Shared';
                  return r.name.toLowerCase().contains(q) ||
                      r.code.toLowerCase().contains(q) ||
                      r.type.toLowerCase().contains(q) ||
                      deptName.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: AcadexCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.doorClosed, size: 48, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                          const SizedBox(height: 16),
                          Text(
                            rooms.isEmpty ? "No $roomsLabel Yet" : "No Matching $roomsLabel",
                            style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rooms.isEmpty
                                ? "Establish classrooms, laboratories, and lecture halls to enable timetable scheduling."
                                : "No $roomsLabel match your current search and filter criteria.",
                            textAlign: TextAlign.center,
                            style: AcadexTypography.body(color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                          ),
                          if (canManageRooms && rooms.isEmpty) ...[
                            const SizedBox(height: 20),
                            AcadexButton(
                              label: "+ Create First $roomLabel",
                              icon: LucideIcons.plus,
                              onPressed: () => context.push('/academics/rooms/new'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                if (isMobile) {
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      final deptName = r.departmentId != null && r.departmentId!.isNotEmpty
                          ? (deptMap[r.departmentId]?.name ?? 'Department')
                          : 'Campus Shared';

                      return AcadexCard(
                        padding: const EdgeInsets.all(14),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AcadexColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AcadexRadius.sm),
                                        ),
                                        child: Text(
                                          r.code,
                                          style: const TextStyle(
                                            color: AcadexColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          r.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AcadexBadge(
                                  label: r.isActive ? "Active" : "Inactive",
                                  variant: r.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(LucideIcons.users, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                const SizedBox(width: 4),
                                Text(
                                  "Capacity: ${r.capacity}",
                                  style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                ),
                                const SizedBox(width: 12),
                                Icon(LucideIcons.tag, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                const SizedBox(width: 4),
                                Text(
                                  r.type.toUpperCase(),
                                  style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              deptName,
                              style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                            ),
                            if (canManageRooms) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AcadexButton(
                                    label: "Edit",
                                    icon: LucideIcons.edit,
                                    variant: AcadexButtonVariant.secondary,
                                    onPressed: () => context.push('/academics/rooms/edit/${r.id}'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                }

                // Desktop Data Table
                return AcadexDataTable(
                  columns: const [
                    "Code",
                    "Room Name",
                    "Type",
                    "Capacity",
                    "Department / Allocation",
                    "Status",
                    "Actions",
                  ],
                  rows: filtered.map((r) {
                    final deptName = r.departmentId != null && r.departmentId!.isNotEmpty
                        ? (deptMap[r.departmentId]?.name ?? r.departmentId!)
                        : 'Campus Shared';

                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AcadexRadius.sm),
                            ),
                            child: Text(
                              r.code,
                              style: const TextStyle(
                                color: AcadexColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              const Icon(LucideIcons.doorClosed, size: 16, color: AcadexColors.primary),
                              const SizedBox(width: 8),
                              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(Text(r.type.toUpperCase())),
                        DataCell(
                          Row(
                            children: [
                              const Icon(LucideIcons.users, size: 14, color: AcadexColors.inkMuted),
                              const SizedBox(width: 6),
                              Text("${r.capacity} seats", style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(Text(deptName)),
                        DataCell(
                          AcadexBadge(
                            label: r.isActive ? "Active" : "Inactive",
                            variant: r.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                          ),
                        ),
                        DataCell(
                          canManageRooms
                              ? IconButton(
                                  icon: const Icon(LucideIcons.edit, size: 18),
                                  tooltip: "Edit Room",
                                  onPressed: () => context.push('/academics/rooms/edit/${r.id}'),
                                )
                              : const SizedBox.shrink(),
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

class RoomFormScreen extends ConsumerStatefulWidget {
  final String? id;
  final String? initialDepartmentId;

  const RoomFormScreen({super.key, this.id, this.initialDepartmentId});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _capacityCtrl;
  String _selectedType = 'lecture';
  String? _selectedDepartmentId;
  bool _isActive = true;
  bool _isLoading = false;
  Room? _existing;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _capacityCtrl = TextEditingController(text: '60');
    _selectedDepartmentId = widget.initialDepartmentId;

    if (widget.id != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await ref.read(roomsProvider.future);
      _existing = rooms.where((r) => r.id == widget.id).firstOrNull;
      if (_existing != null) {
        _nameCtrl.text = _existing!.name;
        _codeCtrl.text = _existing!.code;
        _capacityCtrl.text = _existing!.capacity.toString();
        _selectedType = _existing!.type;
        _selectedDepartmentId = _existing!.departmentId;
        _isActive = _existing!.isActive;
      }
    } catch (e) {
      if (mounted) AcadexSnackBar.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String collegeId) async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 60;
    if (capacity <= 0) {
      AcadexSnackBar.showWarning(context, 'Room capacity must be at least 1');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final room = Room(
        id: _existing?.id ?? '',
        collegeId: _existing?.collegeId ?? collegeId,
        departmentId: _selectedDepartmentId != null && _selectedDepartmentId!.isNotEmpty
            ? _selectedDepartmentId
            : null,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        capacity: capacity,
        type: _selectedType,
        status: _isActive ? 'active' : 'inactive',
        isActive: _isActive,
      );

      if (_existing == null) {
        await ref.read(roomsProvider.notifier).addRoom(room);
        if (mounted) {
          AcadexSnackBar.showSuccess(context, 'Room created successfully.');
          context.safePop(fallbackRoute: '/academics/rooms');
        }
      } else {
        await ref.read(roomsProvider.notifier).updateRoom(room);
        if (mounted) {
          AcadexSnackBar.showSuccess(context, 'Room updated successfully.');
          context.safePop(fallbackRoute: '/academics/rooms');
        }
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
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isHod = user?.role == AppRole.hod;
    final userDeptId = user?.departmentId ?? '';
    final departments = ref.watch(departmentsProvider).valueOrNull ?? [];
    final institutionConfig = ref.watch(institutionConfigProvider);

    var resolvedCollegeId = user?.collegeId ?? '';
    if (resolvedCollegeId.isEmpty && isHod && userDeptId.isNotEmpty) {
      final dept = departments.where((d) => d.id == userDeptId).firstOrNull;
      if (dept != null && dept.collegeId.isNotEmpty) {
        resolvedCollegeId = dept.collegeId;
      }
    }
    if (resolvedCollegeId.isEmpty) {
      resolvedCollegeId = institutionConfig.valueOrNull?.collegeId ?? '';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final departmentsAsync = ref.watch(departmentsProvider);
    final deptMap = ref.watch(departmentMapProvider);

    if (isHod && userDeptId.isNotEmpty) {
      _selectedDepartmentId ??= userDeptId;
    }

    final terminology = ref.watch(terminologyProvider);
    final roomLabel = terminology.roomName();

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/rooms'),
        ),
        title: Text(
          isEdit ? "Edit $roomLabel" : "Create $roomLabel",
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
                  title: "$roomLabel Details",
                  saveLabel: isEdit ? "Update $roomLabel" : "Create $roomLabel",
                  isSaving: _isLoading,
                  onCancel: () => context.safePop(fallbackRoute: '/academics/rooms'),
                  onSave: () => _save(resolvedCollegeId),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department Info (Locked for HOD, optional selector for College Admin)
                      if (isHod) ...[
                        AcadexFormField(
                          label: "Department",
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                              borderRadius: AcadexRadius.borderRadiusMd,
                              border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.building2, size: 16, color: AcadexColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    deptMap[userDeptId]?.name ?? userDeptId,
                                    style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const AcadexBadge(label: "YOUR DEPARTMENT", variant: AcadexBadgeVariant.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        AcadexFormField(
                          label: "Allocated Department (Optional for Shared Rooms)",
                          child: departmentsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text(AcadexException.sanitizedMessage(e), style: const TextStyle(color: AcadexColors.error)),
                            data: (depts) => DropdownButtonFormField<String?>(
                              initialValue: _selectedDepartmentId,
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              decoration: const InputDecoration(hintText: "Campus Shared (All Departments)"),
                              items: [
                                const DropdownMenuItem(value: null, child: Text("Campus Shared (All Departments)")),
                                ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                              ],
                              onChanged: (v) => setState(() => _selectedDepartmentId = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Room Code / Number
                      AcadexFormField(
                        label: "Room Code / Number *",
                        child: TextFormField(
                          controller: _codeCtrl,
                          decoration: const InputDecoration(
                            hintText: "e.g., LH-101, LAB-2, CS-204",
                            prefixIcon: Icon(LucideIcons.hash, size: 18),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Room code is required";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Room Name
                      AcadexFormField(
                        label: "Room Name *",
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: "e.g., Computer Systems Lab, Lecture Hall A",
                            prefixIcon: Icon(LucideIcons.doorClosed, size: 18),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Room name is required";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Seating Capacity & Room Type Row
                      Row(
                        children: [
                          Expanded(
                            child: AcadexFormField(
                              label: "Seating Capacity *",
                              child: TextFormField(
                                controller: _capacityCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: "e.g., 60",
                                  prefixIcon: Icon(LucideIcons.users, size: 18),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Capacity is required";
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n <= 0) return "Must be > 0";
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AcadexFormField(
                              label: "Room Type *",
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedType,
                                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.tag, size: 18)),
                                items: const [
                                  DropdownMenuItem(value: 'lecture', child: Text("Lecture Hall")),
                                  DropdownMenuItem(value: 'lab', child: Text("Laboratory")),
                                  DropdownMenuItem(value: 'seminar', child: Text("Seminar Room")),
                                  DropdownMenuItem(value: 'other', child: Text("Other")),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedType = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Active Status Switch (Edit Mode)
                      if (isEdit) ...[
                        Row(
                          children: [
                            Switch(
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isActive ? "Active (Available for Timetables)" : "Inactive (Deactivated)",
                              style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
