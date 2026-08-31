import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/utils/navigation_extensions.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_request_providers.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_lookup_providers.dart';

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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typesAsync = ref.watch(certificateTypesProvider);
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;

    final deptMap = ref.watch(certificateDepartmentMapProvider);
    final courseMap = ref.watch(certificateCourseMapProvider);
    final departmentName = user.departmentId != null ? deptMap[user.departmentId]?.name ?? user.departmentId : 'Department of Engineering';
    final courseName = courseMap.values.firstOrNull?.name ?? 'Bachelor of Technology';

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: Text(
          'Request Official Certificate',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.safePop(fallbackRoute: '/certificates/requests'),
        ),
      ),
      body: typesAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: 'Loading available certificate types...'),
        ),
        error: (e, _) => Center(
          child: AcadexErrorState(
            title: 'Failed to load options',
            message: e.toString(),
            onRetry: () => ref.invalidate(certificateTypesProvider),
          ),
        ),
        data: (types) {
          if (types.isEmpty) {
            return Center(
              child: AcadexEmptyState(
                icon: LucideIcons.fileQuestion,
                title: 'No Certificate Types Available',
                subtitle: 'The administration has not configured any requestable certificate templates.',
                actionLabel: 'Return',
                onActionTap: () => context.safePop(fallbackRoute: '/certificates/requests'),
              ),
            );
          }

          _selectedType ??= types.first;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: Certificate Selection
                      _buildSectionHeader('1. Select Certificate Template', isDark),
                      const SizedBox(height: 14),
                      _buildCard(
                        isDark,
                        children: [
                          DropdownButtonFormField<ConfiguredCertificateType>(
                            initialValue: _selectedType,
                            decoration: _inputDecoration('Certificate Type *', isDark),
                            dropdownColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                            items: types.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                          ),
                          if (_selectedType?.description != null && _selectedType!.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _selectedType!.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (_selectedType?.requiresPurpose == true) ...[
                            TextFormField(
                              controller: _purposeController,
                              decoration: _inputDecoration(
                                'Purpose of Certificate *',
                                isDark,
                                hintText: 'e.g., Visa application, Higher studies admission, Loan application',
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Purpose is required for this certificate.' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedType?.requiresReason == true) ...[
                            TextFormField(
                              controller: _reasonController,
                              decoration: _inputDecoration(
                                'Detailed Reason / Notes *',
                                isDark,
                                hintText: 'Please provide full justification or institutional details...',
                              ),
                              maxLines: 3,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Reason is required for this certificate.' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 28),

                      // SECTION 2: Academic Identity Verification (Resolved in O(1) from UserModel)
                      _buildSectionHeader('2. Verified Student Identity', isDark),
                      const SizedBox(height: 14),
                      _buildCard(
                        isDark,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _IdentityTile(
                                  label: 'Full Name',
                                  value: user.name,
                                  icon: LucideIcons.user,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _IdentityTile(
                                  label: 'Student ID',
                                  value: user.id,
                                  icon: LucideIcons.hash,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _IdentityTile(
                                  label: 'Department',
                                  value: departmentName ?? 'Engineering',
                                  icon: LucideIcons.building2,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _IdentityTile(
                                  label: 'Course / Program',
                                  value: courseName,
                                  icon: LucideIcons.graduationCap,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // SECTION 3: Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                              ),
                              onPressed: _isSubmitting ? null : () => context.safePop(fallbackRoute: '/certificates/requests'),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                                elevation: 0,
                              ),
                              onPressed: _isSubmitting ? null : () => _submitRequest(user),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Submit Request',
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
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
        },
      ),
    );
  }

  Future<void> _submitRequest(dynamic user) async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    setState(() => _isSubmitting = true);

    try {
      final request = CertificateRequest(
        id: '',
        studentId: user.id as String,
        studentUserId: (user.firebaseUid ?? user.id) as String,
        collegeId: (user.collegeId ?? '') as String,
        departmentId: (user.departmentId ?? '') as String,
        courseId: (user.semesterId ?? '') as String,
        academicYearId: (user.sectionId ?? '') as String,
        certificateTypeId: _selectedType!.id,
        certificateTypeName: _selectedType!.name,
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        purpose: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
        status: CertificateRequestStatus.pending,
        requestedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(certificateRequestManagementProvider.notifier).createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate request submitted successfully.'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.safePop(fallbackRoute: '/certificates/requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: AcadexColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: isDark ? AcadexColors.darkCanvas : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        borderSide: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        borderSide: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _IdentityTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _IdentityTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
