import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum CustomButtonVariant {
  primary,

  secondary,

  tonal,

  danger,
}

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CustomButtonVariant variant;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null && !isLoading;

    final (Color background, Color foreground, Color? border) = switch (variant) {
      CustomButtonVariant.primary => (scheme.primary, scheme.onPrimary, null),
      CustomButtonVariant.secondary => (
          theme.brightness == Brightness.light
              ? Colors.white
              : AppColors.slate800,
          scheme.onSurface,
          scheme.outlineVariant,
        ),
      CustomButtonVariant.tonal => (
          scheme.primary.withValues(alpha: 0.10),
          scheme.primary,
          null,
        ),
      CustomButtonVariant.danger => (AppColors.danger, Colors.white, null),
    };

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          );

    final button = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: border == null ? null : Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 1),
              child: child,
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
