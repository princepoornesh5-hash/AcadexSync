import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../../core/errors/acadex_error.dart';
import '../../../domain/models/user_profile_model.dart';
import '../../providers/user_profile_providers.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfileModel profile;

  const EditProfileDialog({super.key, required this.profile});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(profileEditProvider.notifier).updateProfile(
      widget.profile,
      _nameController.text.trim(),
      _phoneController.text.trim(),
    );

    final editState = ref.read(profileEditProvider);
    if (!mounted) return;

    if (editState.status == ProfileEditStatus.saved) {
      AcadexSnackBar.showSuccess(context, 'Profile updated successfully');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSaving = state.status == ProfileEditStatus.saving;

    return Dialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AcadexRadius.borderRadiusLg,
        side: const BorderSide(color: AcadexColors.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: AcadexSpacing.dialogPadding,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Personal Information',
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter contact phone number',
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AcadexColors.error.withValues(alpha: 0.1),
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AcadexColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AcadexException.sanitizedMessage(state.error),
                            style: const TextStyle(color: AcadexColors.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      AcadexButton(
                        label: 'Cancel',
                        variant: AcadexButtonVariant.secondary,
                        onPressed: isSaving ? null : () => Navigator.pop(context),
                      ),
                      AcadexButton(
                        label: isSaving ? 'Saving...' : 'Save Changes',
                        isLoading: isSaving,
                        onPressed: isSaving ? null : _handleSave,
                      ),
                    ],
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
