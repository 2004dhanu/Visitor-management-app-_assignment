import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date.dart';
import '../../../shared/widgets/screen_header.dart';
import '../data/visitor.dart';
import 'status_chip.dart';

class VisitorAvatar extends StatelessWidget {
  const VisitorAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 52,
  });

  final String name;
  final Color color;
  final double size;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class VisitorCard extends StatelessWidget {
  const VisitorCard({
    super.key,
    required this.visitor,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.compact = false,
  });

  final Visitor visitor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  String get _timestamp {
    final latest =
        visitor.checkOutTime ?? visitor.checkInTime ?? visitor.createdAt;
    return compact
        ? AppDate.relativeLabel(latest)
        : AppDate.relativeLong(latest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = StatusChip.colorFor(visitor.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md - 3 : AppSpacing.md - 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VisitorAvatar(
                name: visitor.name,
                color: accent,
                size: compact ? 42 : 52,
              ),
              SizedBox(width: compact ? AppSpacing.sm + 2 : AppSpacing.md - 4),
              Expanded(
                child: compact
                    ? _CompactBody(visitor: visitor, timestamp: _timestamp)
                    : _FullBody(
                        visitor: visitor,
                        timestamp: _timestamp,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
              ),
              if (compact)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({required this.visitor, required this.timestamp});

  final Visitor visitor;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 7,
              child: Text(
                visitor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 15.5),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              flex: 3,
              child: Text(
                timestamp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 1),
        _MetaLine(visitor: visitor),
        const SizedBox(height: AppSpacing.sm),
        StatusChip(status: visitor.status, dense: true),
      ],
    );
  }
}

class _FullBody extends StatelessWidget {
  const _FullBody({
    required this.visitor,
    required this.timestamp,
    required this.onEdit,
    required this.onDelete,
  });

  final Visitor visitor;
  final String timestamp;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  visitor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SquareIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit visitor',
              tinted: true,
              size: 36,
              iconSize: 16,
              onPressed: onEdit,
            ),
            const SizedBox(width: AppSpacing.sm - 2),
            SquareIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete visitor',
              tinted: true,
              color: AppColors.danger,
              size: 36,
              iconSize: 16,
              onPressed: onDelete,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        _IconText(
          icon: Icons.phone_outlined,
          text: visitor.mobile,
          emphasise: true,
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        _MetaLine(visitor: visitor),
        const SizedBox(height: AppSpacing.sm + 2),
        Row(
          children: [
            StatusChip(status: visitor.status),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                timestamp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.visitor});

  final Visitor visitor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _IconText(
            icon: Icons.apartment_rounded,
            text: visitor.project,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm - 2),
          child: Text(
            '|',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ),
        Expanded(
          child: _IconText(
            icon: Icons.groups_outlined,
            text: visitor.visitorType,
          ),
        ),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.text,
    this.emphasise = false,
  });

  final IconData icon;
  final String text;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs + 2),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: emphasise ? FontWeight.w600 : FontWeight.w500,
              color: emphasise
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
