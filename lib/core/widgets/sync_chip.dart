import 'package:flutter/material.dart';

import '../sync/sync_status.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// "Synced", "2 changes waiting" or "Offline", shown under list headers.
class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.status});

  final SyncStatus? status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = status;

    IconData icon;
    String label;
    Color tint;
    if (s == null || s.phase == SyncPhase.syncing) {
      icon = Icons.sync_rounded;
      label = 'Syncing';
      tint = c.primary;
    } else if (s.phase == SyncPhase.offline) {
      icon = Icons.cloud_off_rounded;
      label = s.pending > 0 ? 'Offline · ${plural(s.pending, 'change')} waiting' : 'Offline';
      tint = const Color(0xFFE07A4F);
    } else if (s.pending > 0) {
      icon = Icons.sync_rounded;
      label = '${plural(s.pending, 'change')} waiting';
      tint = c.primary;
    } else {
      icon = Icons.cloud_done_rounded;
      label = 'Synced';
      tint = const Color(0xFF2FA36B);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tint),
            ),
          ],
        ),
      ),
    );
  }
}
