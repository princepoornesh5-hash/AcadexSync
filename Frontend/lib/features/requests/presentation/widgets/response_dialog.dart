import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../providers/requests_providers.dart';

class ResponseDialog extends ConsumerStatefulWidget {
  final String requestId;
  final String initialAction; // APPROVED, REJECTED, RESOLVED

  const ResponseDialog({
    super.key,
    required this.requestId,
    this.initialAction = 'APPROVED',
  });

  static Future<bool?> show(
    BuildContext context, {
    required String requestId,
    String initialAction = 'APPROVED',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResponseDialog(
        requestId: requestId,
        initialAction: initialAction,
      ),
    );
  }

  @override
  ConsumerState<ResponseDialog> createState() => _ResponseDialogState();
}

class _ResponseDialogState extends ConsumerState<ResponseDialog> {
  late String _selectedAction;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.initialAction;
    if (_selectedAction == 'APPROVED') {
      _messageController.text = 'Request approved.';
    } else if (_selectedAction == 'REJECTED') {
      _messageController.text = 'Request could not be approved at this time.';
    } else if (_selectedAction == 'RESOLVED') {
      _messageController.text = 'Request has been resolved.';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onActionChanged(String action) {
    setState(() {
      _selectedAction = action;
      if (action == 'APPROVED') {
        _messageController.text = 'Request approved.';
      } else if (action == 'REJECTED') {
        _messageController.text = 'Request could not be approved at this time.';
      } else if (action == 'RESOLVED') {
        _messageController.text = 'Request has been resolved.';
      }
    });
  }

  Future<void> _submitResponse() async {
    if (_isSubmitting) return;
    final message = _messageController.text.trim();
    if (_selectedAction == 'REJECTED' && message.length < 5) {
      AcadexSnackBar.showError(
        context,
        'Please provide a rejection reason (at least 5 characters).',
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final res = await ref.read(requestActionProvider.notifier).respondToRequest(
            id: widget.requestId,
            action: _selectedAction,
            message: message,
          );

      if (mounted) {
        if (res != null) {
          AcadexSnackBar.showSuccess(context, 'Response submitted successfully.');
          Navigator.of(context).pop(true);
        } else {
          AcadexSnackBar.showError(
            context,
            'Unable to submit response. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AcadexColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActionColor(_selectedAction).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getActionIcon(_selectedAction),
                  color: _getActionColor(_selectedAction),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Respond to Request',
                  style: AcadexTypography.heading3(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Select Decision',
            style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Action choices
          Row(
            children: [
              _ActionChoice(
                label: 'Approve',
                action: 'APPROVED',
                isSelected: _selectedAction == 'APPROVED',
                color: const Color(0xFF059669),
                onTap: () => _onActionChanged('APPROVED'),
              ),
              const SizedBox(width: 8),
              _ActionChoice(
                label: 'Resolve',
                action: 'RESOLVED',
                isSelected: _selectedAction == 'RESOLVED',
                color: const Color(0xFF0D9488),
                onTap: () => _onActionChanged('RESOLVED'),
              ),
              const SizedBox(width: 8),
              _ActionChoice(
                label: 'Reject',
                action: 'REJECTED',
                isSelected: _selectedAction == 'REJECTED',
                color: const Color(0xFFDC2626),
                onTap: () => _onActionChanged('REJECTED'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Response Message',
            style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add an optional note or reasoning for the requester...',
              hintStyle: AcadexTypography.bodySmall(color: AcadexColors.inkMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AcadexColors.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AcadexColors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: AcadexButton(
                  label: 'Cancel',
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AcadexButton(
                  label: 'Confirm Decision',
                  isLoading: _isSubmitting,
                  onPressed: _submitResponse,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'APPROVED':
        return const Color(0xFF059669);
      case 'RESOLVED':
        return const Color(0xFF0D9488);
      case 'REJECTED':
        return const Color(0xFFDC2626);
      default:
        return AcadexColors.primary;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'APPROVED':
        return LucideIcons.checkCircle;
      case 'RESOLVED':
        return LucideIcons.checkCheck;
      case 'REJECTED':
        return LucideIcons.xCircle;
      default:
        return LucideIcons.send;
    }
  }
}

class _ActionChoice extends StatelessWidget {
  final String label;
  final String action;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ActionChoice({
    required this.label,
    required this.action,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AcadexColors.canvasSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AcadexColors.hairline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AcadexTypography.caption().copyWith(
                color: isSelected ? color : AcadexColors.inkSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
