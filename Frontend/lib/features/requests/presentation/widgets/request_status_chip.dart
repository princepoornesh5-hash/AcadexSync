import 'package:flutter/material.dart';
import '../../domain/models/request_model.dart';
import '../../../../app/theme/app_theme.dart';

class RequestStatusChip extends StatelessWidget {
  final RequestStatus status;
  final bool showIcon;

  const RequestStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              status.icon,
              size: 13,
              color: status.color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: AcadexTypography.caption().copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
