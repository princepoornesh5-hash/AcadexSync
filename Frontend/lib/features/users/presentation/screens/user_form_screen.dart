import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';

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
    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(widget.userId == null ? 'Create User' : 'Edit User'),
        backgroundColor: DashboardColors.surface,
        foregroundColor: DashboardColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    _buildTextField('Full Name', _nameCtrl, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Email Address', _emailCtrl, required: true, isEmail: true),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number', _phoneCtrl, required: true),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Role & Status'),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown<AppRole>('Role', AppRole.values, _selectedRole, (v) => setState(() => _selectedRole = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdown<UserStatus>('Status', UserStatus.values, _selectedStatus, (v) => setState(() => _selectedStatus = v!))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Identifiers'),
                    if (_selectedRole != AppRole.student)
                      _buildTextField('Employee ID', _empIdCtrl),
                    if (_selectedRole == AppRole.student)
                      _buildTextField('Roll Number', _rollNoCtrl),
                      
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: ref.watch(userManagementProvider).isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: ref.watch(userManagementProvider).isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Save User', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: DashboardColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.border)),
      ),
      validator: (val) {
        if (required && (val == null || val.isEmpty)) return 'This field is required';
        if (isEmail && val != null && !val.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildDropdown<T>(String label, List<T> items, T value, ValueChanged<T?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: DashboardColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.border)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
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
