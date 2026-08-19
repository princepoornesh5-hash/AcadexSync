import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId; // If null, create mode

  const UserFormScreen({super.key, this.userId});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _empIdCtrl;
  late TextEditingController _rollNoCtrl;
  
  AppRole _selectedRole = AppRole.student;
  UserStatus _selectedStatus = UserStatus.active;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _empIdCtrl = TextEditingController();
    _rollNoCtrl = TextEditingController();

    if (widget.userId != null) {
      _loadExistingUser();
    }
  }

  Future<void> _loadExistingUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(userRepositoryProvider).getUserById(widget.userId!);
      if (user != null) {
        _nameCtrl.text = user.name;
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phone;
        _empIdCtrl.text = user.employeeId ?? '';
        _rollNoCtrl.text = user.rollNumber ?? '';
        setState(() {
          _selectedRole = user.role;
          _selectedStatus = user.status;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _empIdCtrl.dispose();
    _rollNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = UserProfileModel(
      id: widget.userId ?? '',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
      status: _selectedStatus,
      employeeId: _selectedRole != AppRole.student ? _empIdCtrl.text.trim() : null,
      rollNumber: _selectedRole == AppRole.student ? _rollNoCtrl.text.trim() : null,
    );

    try {
      if (widget.userId == null) {
        await ref.read(userManagementProvider.notifier).createUser(user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully')));
          context.pop();
        }
      } else {
        await ref.read(userManagementProvider.notifier).updateUser(user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully')));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.userId == null ? 'Create User' : 'Edit User',
          style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AcadexFormCard(
                      title: "Basic Information",
                      icon: LucideIcons.user,
                      child: Column(
                        children: [
                          _buildTextField('Full Name', _nameCtrl, required: true, icon: LucideIcons.user),
                          const SizedBox(height: 16),
                          _buildTextField('Email Address', _emailCtrl, required: true, isEmail: true, icon: LucideIcons.mail),
                          const SizedBox(height: 16),
                          _buildTextField('Phone Number', _phoneCtrl, required: true, icon: LucideIcons.phone),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AcadexFormCard(
                      title: "Role & Status",
                      icon: LucideIcons.shield,
                      child: Row(
                        children: [
                          Expanded(child: _buildDropdown<AppRole>('Role', AppRole.values, _selectedRole, (v) => setState(() => _selectedRole = v!))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDropdown<UserStatus>('Status', UserStatus.values, _selectedStatus, (v) => setState(() => _selectedStatus = v!))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AcadexFormCard(
                      title: "Identifiers",
                      icon: LucideIcons.hash,
                      child: Column(
                        children: [
                          if (_selectedRole != AppRole.student)
                            _buildTextField('Employee ID', _empIdCtrl, icon: LucideIcons.idCard),
                          if (_selectedRole == AppRole.student)
                            _buildTextField('Roll Number', _rollNoCtrl, icon: LucideIcons.hash),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text("Cancel", style: AcadexTypography.body(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: ref.watch(userManagementProvider).isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                          ),
                          child: ref.watch(userManagementProvider).isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Save User', style: AcadexTypography.body(color: Colors.white).copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, bool isEmail = false, IconData? icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      ),
      validator: (val) {
        if (required && (val == null || val.isEmpty)) return 'This field is required';
        if (isEmail && val != null && !val.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildDropdown<T>(String label, List<T> items, T value, ValueChanged<T?> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
          value: value,
          isExpanded: true,
          items: items.map((e) {
            String display = '';
            if (e is AppRole) display = e.displayName;
            if (e is UserStatus) display = e.displayName;
            return DropdownMenuItem(value: e, child: Text(display));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
