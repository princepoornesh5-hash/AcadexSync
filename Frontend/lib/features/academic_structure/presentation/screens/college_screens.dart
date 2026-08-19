import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class CollegeListScreen extends ConsumerWidget {
  const CollegeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegesAsync = ref.watch(collegesProvider);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcadexPageHeader(
            title: "Colleges",
            subtitle: "Manage registered colleges in the system.",
          ),
          AcadexSearchFilterBar(
            searchHint: "Search colleges...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/colleges/new'),
            actionLabel: "Add College",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: collegesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AcadexColors.warning))),
              data: (colleges) => AcadexDataTable(
                columns: const ["Code", "Name", "Principal", "Email", "Phone", "Status", "Actions"],
                rows: colleges.map((c) => DataRow(cells: [
                  DataCell(Text(c.code, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                  DataCell(Text(c.name)),
                  DataCell(Text(c.principal)),
                  DataCell(Text(c.email)),
                  DataCell(Text(c.phone)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.1) ?? AcadexColors.inkMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(c.isActive ? "Active" : "Inactive", style: TextStyle(color: c.isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), onPressed: () => context.push('/academics/colleges/edit/${c.id}')),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning), onPressed: () {}),
                      ],
                    )
                  ),
                ])).toList(),
                emptyState: AcadexEmptyState(
                  title: "No Colleges Found",
                  subtitle: "Get started by adding the first college.",
                  icon: LucideIcons.building,
                  actionLabel: "Add College",
                  onActionTap: () => context.push('/academics/colleges/new'),
                ),
              ),
            ),
          )
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
      final colleges = await ref.read(collegesProvider.future);
      _existing = colleges.firstWhere((c) => c.id == widget.collegeId);
      _nameCtrl.text = _existing!.name;
      _codeCtrl.text = _existing!.code;
      _principalCtrl.text = _existing!.principal;
      _emailCtrl.text = _existing!.email;
      _phoneCtrl.text = _existing!.phone;
      _addressCtrl.text = _existing!.address;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading college: $e')));
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
        id: _existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
        principal: _principalCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        isActive: _existing?.isActive ?? true,
      );

      if (_existing == null) {
        await ref.read(collegesProvider.notifier).addCollege(college);
      } else {
        await ref.read(collegesProvider.notifier).updateCollege(college);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('College saved successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.collegeId != null;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
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
                  onCancel: () => context.pop(),
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
