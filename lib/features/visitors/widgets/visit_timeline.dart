import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date.dart';
import '../data/visitor.dart';

class VisitTimeline extends StatelessWidget {
  const VisitTimeline({super.key, required this.visitor});

  final Visitor visitor;

  @override
  Widget build(BuildContext context) {
    final entries = [
      _Entry(
        icon: Icons.person_outline_rounded,
        label: 'Registered',
        iso: visitor.createdAt,
        color: AppColors.registered,
      ),
      _Entry(
        icon: Icons.login_rounded,
        label: 'Checked in',
        iso: visitor.checkInTime,
        color: AppColors.checkedIn,
      ),
      _Entry(
        icon: Icons.logout_rounded,
        label: 'Checked out',
        iso: visitor.checkOutTime,
        color: AppColors.exit,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _Entry {
  const _Entry({
    required this.icon,
    required this.label,
    required this.iso,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String? iso;
  final Color color;

  bool get happened => AppDate.tryParseLocal(iso) != null;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final _Entry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = entry.happened;
    final accent = done ? entry.color : theme.colorScheme.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                height: 13,
                width: 13,
                margin: const EdgeInsets.only(top: AppSpacing.md - 2),
                decoration: BoxDecoration(
                  color: done ? accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 4,
                  vertical: AppSpacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  color: done
                      ? accent.withValues(alpha: 0.07)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md - 2),
                ),
                child: Row(
                  children: [
                    Icon(entry.icon, size: 17, color: accent),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      flex: 4,
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 13.5,
                          color: done
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      flex: 5,
                      child: Text(
                        done ? AppDate.format(entry.iso) : 'Pending',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
