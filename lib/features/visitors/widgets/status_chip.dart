import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/visitor_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.dense = false});

  final VisitorStatus status;
  final bool dense;

  static Color colorFor(VisitorStatus status) => switch (status) {
        VisitorStatus.registered => AppColors.registered,
        VisitorStatus.checkedIn => AppColors.checkedIn,
        VisitorStatus.checkedOut => AppColors.checkedOut,
      };

  static IconData iconFor(VisitorStatus status) => switch (status) {
        VisitorStatus.registered => Icons.schedule_rounded,
        VisitorStatus.checkedIn => Icons.login_rounded,
        VisitorStatus.checkedOut => Icons.check_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.sm + 4,
        vertical: dense ? 4 : AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(status), size: dense ? 11 : 13, color: color),
          SizedBox(width: dense ? 3 : AppSpacing.xs + 1),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
