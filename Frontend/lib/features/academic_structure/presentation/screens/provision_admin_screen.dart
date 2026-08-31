import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../providers/academic_providers.dart';
import 'activation_result_screen.dart';

class ProvisionAdminScreen extends ConsumerStatefulWidget {
  final String collegeId;

  const ProvisionAdminScreen({super.key, required this.collegeId});

  @override
  ConsumerState<ProvisionAdminScreen> createState() => _ProvisionAdminScreenState();
}

class _ProvisionAdminScreenState extends ConsumerState<ProvisionAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _instituteIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instituteIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String collegeName, String collegeCode) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'instituteId': _instituteIdCtrl.text.trim().toUpperCase(),
        if (_emailCtrl.text.trim().isNotEmpty)
          'email': _emailCtrl.text.trim().toLowerCase(),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone': _phoneCtrl.text.trim(),
      };

      final result = await ref
          .read(provisionCollegeAdminProvider.notifier)
          .provision(widget.collegeId, payload);

      final fullResult = result.copyWith(
        collegeName: collegeName,
        collegeCode: collegeCode,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        // Replace current screen with activation result
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ActivationResultScreen(result: fullResult),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errText = e.toString().replaceFirst('Exception: ', '').replaceAll('DioException [bad response]: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circleAlert, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(errText)),
              ],
            ),
            backgroundColor: AcadexColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collegeAsync = ref.watch(collegeByIdProvider(widget.collegeId));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/colleges/${widget.collegeId}'),
        ),
        title: Text(
          'Provision College Admin',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: collegeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Failed to load college: $err', style: const TextStyle(color: AcadexColors.error)),
        ),
        data: (college) {
          return AcadexPageContainer(
            maxWidth: AcadexLayout.formMaxWidth,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // College Banner Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withValues(alpha: 0.08),
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: AcadexColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AcadexColors.primary,
                            borderRadius: AcadexRadius.borderRadiusSm,
                          ),
                          child: const Icon(LucideIcons.building, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                college.name,
                                style: AcadexTypography.body(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ).copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Code: ${college.code} • Principal: ${college.principal}',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Provisioning Form
                  AcadexCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrator Account Details',
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A single-use activation code will be generated. The administrator uses this code to set their password at /activate.',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Full Name
                        AcadexFormField(
                          label: 'Full Name *',
                          child: TextFormField(
                            controller: _nameCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Full Name is required';
                              if (v.trim().length < 2) return 'Name must be at least 2 characters';
                              return null;
                            },
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'e.g. Dr. Rajesh Kumar',
                              prefixIcon: Icon(LucideIcons.user, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // PIN Number
                        AcadexFormField(
                          label: 'PIN Number *',
                          child: TextFormField(
                            controller: _instituteIdCtrl,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'PIN Number is required';
                              if (v.trim().length < 2) return 'PIN Number must be at least 2 characters';
                              return null;
                            },
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'PIN Number *',
                              hintText: 'e.g. GIT-ADMIN-01',
                              prefixIcon: Icon(LucideIcons.idCard, size: 18),
                              helperText: 'Official institutional PIN Number used by administrator to log in.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email (Optional)
                        AcadexFormField(
                          label: 'Email (Optional)',
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return 'Enter a valid email address';
                                }
                              }
                              return null;
                            },
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Email (Optional)',
                              hintText: 'e.g. admin@git.edu',
                              prefixIcon: Icon(LucideIcons.mail, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Phone (Optional)
                        AcadexFormField(
                          label: 'Phone (Optional)',
                          child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty && v.trim().length < 7) {
                                return 'Phone must be at least 7 digits';
                              }
                              return null;
                            },
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Phone (Optional)',
                              hintText: 'e.g. 9876543210',
                              prefixIcon: Icon(LucideIcons.phone, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AcadexButton(
                          label: 'Cancel',
                          variant: AcadexButtonVariant.secondary,
                          onPressed: _isSubmitting ? null : () => context.safePop(fallbackRoute: '/academics/colleges'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AcadexButton(
                          label: _isSubmitting ? 'Provisioning...' : 'Provision Administrator',
                          icon: _isSubmitting ? null : LucideIcons.userPlus,
                          variant: AcadexButtonVariant.primary,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : () => _submit(college.name, college.code),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
