import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'sparkline.dart';

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = const [],
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final List<int> trend;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Material(
      color: isLight ? AppColors.tileWash(color) : AppColors.slate800,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isLight
                  ? color.withValues(alpha: 0.12)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md - 4,
              AppSpacing.md - 4,
              AppSpacing.md - 4,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 34,
                  width: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(height: AppSpacing.md - 2),
                if (isLoading)
                  Container(
                    height: 28,
                    width: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                else
                  Text(
                    '$value',
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      height: 1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm - 2),
                Sparkline(values: trend, color: color, height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
