import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.tinted = false,
    this.size = 42,
    this.iconSize = 19,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool tinted;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    final isLight = theme.brightness == Brightness.light;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: tinted
            ? accent.withValues(alpha: 0.10)
            : (isLight ? Colors.white : AppColors.slate800),
        borderRadius: BorderRadius.circular(AppRadius.md - 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md - 2),
          child: Ink(
            height: size,
            width: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md - 2),
              border: tinted
                  ? null
                  : Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: tinted ? accent : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.compactTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  final bool compactTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: compactTitle
              ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)
              : theme.textTheme.headlineMedium?.copyWith(fontSize: 30),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.md - 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md - 4),
          ],
          Expanded(child: titleBlock),
          for (final action in actions) ...[
            const SizedBox(width: AppSpacing.sm + 2),
            action,
          ],
        ],
      ),
    );
  }
}
