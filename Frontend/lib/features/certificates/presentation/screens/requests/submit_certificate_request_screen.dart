import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_request_providers.dart';

class SubmitCertificateRequestScreen extends ConsumerStatefulWidget {
  const SubmitCertificateRequestScreen({super.key});

  @override
  ConsumerState<SubmitCertificateRequestScreen> createState() => _SubmitCertificateRequestScreenState();
}

class _SubmitCertificateRequestScreenState extends ConsumerState<SubmitCertificateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  ConfiguredCertificateType? _selectedType;
  final _reasonController = TextEditingController();
  final _purposeController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(certificateTypesProvider);
    final studentsAsync = ref.watch(studentsProvider);
    
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text('New Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      body: (typesAsync.isLoading || studentsAsync.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Select Certificate Type'),
                    Builder(builder: (context) {
                      final types = typesAsync.value ?? [];
                      if (types.isEmpty) return const Text('No certificate types available.');

                      return DropdownButtonFormField<ConfiguredCertificateType>(
                        decoration: _inputDecoration('Certificate Type'),
                        initialValue: _selectedType,
                        items: types.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedType = val;
                            _reasonController.clear();
                            _purposeController.clear();
                          });
                        },
                        validator: (val) => val == null ? 'Required' : null,
                      );
                    }),
                    
                    if (_selectedType != null && _selectedType!.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedType!.description,
                        style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary),
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (_selectedType != null && _selectedType!.requiresReason) ...[
                      _buildSectionTitle('Reason'),
                      TextFormField(
                        controller: _reasonController,
                        decoration: _inputDecoration('Reason for request'),
                        maxLines: 3,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Reason is required for this certificate type' : null,
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_selectedType != null && _selectedType!.requiresPurpose) ...[
                      _buildSectionTitle('Purpose'),
                      TextFormField(
                        controller: _purposeController,
                        decoration: _inputDecoration('Purpose of certificate'),
                        maxLines: 2,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Purpose is required for this certificate type' : null,
                      ),
                      const SizedBox(height: 32),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _submitRequest,
                        child: Text('Submit Request', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: DashboardColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: DashboardColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: DashboardColors.border),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    final studentsAsync = ref.read(studentsProvider);
    final students = studentsAsync.value ?? [];
    final student = students.whereType<Student>().where((s) => s.id == user.id).firstOrNull;

    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student profile not found.')));
      return;
    }

    final req = CertificateRequest(
      id: '',
      studentId: student.rollNumber,
      studentUserId: user.id,
      collegeId: student.collegeId,
      departmentId: student.departmentId,
      courseId: student.courseId,
      academicYearId: '',
      certificateTypeId: _selectedType!.id,
      certificateTypeName: _selectedType!.name,
      reason: _selectedType!.requiresReason ? _reasonController.text.trim() : null,
      purpose: _selectedType!.requiresPurpose ? _purposeController.text.trim() : null,
      requestedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final notifier = ref.read(certificateRequestManagementProvider.notifier);
    await notifier.createRequest(req);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted successfully.')));
      context.pop();
    }
  }
}
