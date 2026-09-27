import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/calendar_event_model.dart';
import '../providers/calendar_providers.dart';

class CalendarEventDetailSheet extends ConsumerStatefulWidget {
  final CalendarEventModel event;
  final VoidCallback? onChanged;

  const CalendarEventDetailSheet({
    super.key,
    required this.event,
    this.onChanged,
  });

  @override
  ConsumerState<CalendarEventDetailSheet> createState() =>
      _CalendarEventDetailSheetState();
}

class _CalendarEventDetailSheetState
    extends ConsumerState<CalendarEventDetailSheet> {
  bool _isLoading = false;

  Future<void> _handleCancelEvent() async {
    final reasonController = TextEditingController();
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this event?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Event'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ref.read(calendarEventsProvider.notifier).cancelEvent(
              widget.event.id,
              reason: reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : null,
            );
        if (mounted) {
          Navigator.of(context).pop();
          widget.onChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel event: $e')),
          );
        }
      }
    }
  }

  Future<void> _handlePublishEvent() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(calendarEventsProvider.notifier).publishEvent(widget.event.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event published successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    String timeLabel = 'All Day';
    if (!event.allDay && event.startTime != null) {
      timeLabel = event.startTime!;
      if (event.endTime != null) {
        timeLabel += ' – ${event.endTime}';
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Category & Status row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.eventType.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AcadexColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (event.status == CalendarEventStatus.cancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Cancelled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  )
                else if (event.status == CalendarEventStatus.draft)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Draft',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // Details list
            _buildDetailRow(
              LucideIcons.calendar,
              'Date',
              event.startDate == event.endDate
                  ? event.startDate
                  : '${event.startDate} to ${event.endDate}',
            ),
            const SizedBox(height: 10),

            _buildDetailRow(LucideIcons.clock, 'Time', timeLabel),
            const SizedBox(height: 10),

            if (event.academicContext != null && event.academicContext!.isNotEmpty) ...[
              _buildDetailRow(LucideIcons.graduationCap, 'Scope', event.academicContext!),
              const SizedBox(height: 10),
            ],

            if (event.location != null && event.location!.isNotEmpty) ...[
              _buildDetailRow(LucideIcons.mapPin, 'Location', event.location!),
              const SizedBox(height: 10),
            ],

            _buildDetailRow(
              LucideIcons.user,
              'Published by',
              '${event.creatorName} (${event.creatorRole.name.toUpperCase()})',
            ),
            const SizedBox(height: 14),

            // Description
            if (event.description.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AcadexColors.hairline),
                ),
                child: Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            if (event.sourceType == CalendarSourceType.derived &&
                event.navigationTarget != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(event.navigationTarget!);
                  },
                  icon: const Icon(LucideIcons.externalLink, size: 16),
                  label: const Text('View Assignment Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  if (event.status == CalendarEventStatus.draft && event.canEdit)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handlePublishEvent,
                        icon: const Icon(LucideIcons.send, size: 16),
                        label: const Text('Publish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcadexColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (event.canCancel) ...[
                    if (event.status == CalendarEventStatus.draft)
                      const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleCancelEvent,
                        icon: const Icon(LucideIcons.ban, size: 16, color: Colors.red),
                        label: const Text(
                          'Cancel Event',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
