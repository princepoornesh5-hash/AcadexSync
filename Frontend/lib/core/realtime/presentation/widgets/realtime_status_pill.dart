import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/realtime_providers.dart';
import '../../models/realtime_event.dart';

class RealtimeStatusPill extends ConsumerWidget {
  const RealtimeStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(realtimeStatusProvider);
    final status = statusAsync.valueOrNull ?? RealtimeConnectionStatus.disconnected;

    if (status == RealtimeConnectionStatus.connected) {
      // Intentionally hidden when connected normally
      return const SizedBox.shrink();
    }

    final isReconnecting = status == RealtimeConnectionStatus.reconnecting ||
        status == RealtimeConnectionStatus.connecting;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isReconnecting ? Colors.amber.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReconnecting ? Colors.amber.shade300 : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReconnecting ? LucideIcons.loader : LucideIcons.cloudOff,
            size: 14,
            color: isReconnecting ? Colors.amber.shade900 : Colors.red.shade900,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isReconnecting ? 'Reconnecting live updates...' : 'Offline (HTTP active)',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isReconnecting ? Colors.amber.shade900 : Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
