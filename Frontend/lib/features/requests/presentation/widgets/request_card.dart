import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/request_model.dart';
import 'request_status_chip.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final bool isIncoming;
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.request,
    this.isIncoming = false,
    required this.onTap,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final contextInfo = request.academicContext != null
        ? [
            request.academicContext?.subjectName,
            request.academicContext?.sectionName,
          ].where((s) => s != null && s.isNotEmpty).join(' • ')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcadexColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0507111F),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Request Type & Status Chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AcadexColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        request.requestType.icon,
                        size: 16,
                        color: AcadexColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.title.isNotEmpty
                            ? request.title
                            : request.requestType.displayName,
                        style: AcadexTypography.bodySmall().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AcadexColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RequestStatusChip(status: request.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Description preview
                Text(
                  request.description,
                  style: AcadexTypography.caption().copyWith(
                    color: AcadexColors.inkSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (contextInfo != null && contextInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AcadexColors.canvasSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      contextInfo,
                      style: AcadexTypography.caption().copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1, color: AcadexColors.hairline),
                const SizedBox(height: 8),

                // Bottom Meta: Date & Submitter / Target
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(request.createdAt),
                      style: AcadexTypography.caption().copyWith(
                        fontSize: 11,
                        color: AcadexColors.inkMuted,
                      ),
                    ),
                    Text(
                      isIncoming
                          ? 'From: ${request.requesterName} (${request.requesterRole.displayName})'
                          : 'To: ${request.targetName ?? request.targetRole.displayName}',
                      style: AcadexTypography.caption().copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.inkSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
