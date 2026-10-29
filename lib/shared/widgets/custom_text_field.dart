import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        text: label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontSize: 13.5,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          if (isRequired)
            TextSpan(
              text: '  *',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.isRequired = false,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.textCapitalization = TextCapitalization.words,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final bool isRequired;
  final int maxLines;
  final int? maxLength;

  final bool showCounter;

  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, isRequired: isRequired),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          enabled: enabled,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: showCounter ? null : '',
            counterStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.md - 4,
                      right: AppSpacing.sm + 2,
                      bottom: maxLines > 1 ? (maxLines - 1) * 22 : 0,
                    ),
                    child: Icon(prefixIcon, size: 19),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),
      ],
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  const CustomDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.itemLabel,
    this.hint,
    this.validator,
    this.prefixIcon,
    this.isRequired = false,
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String Function(T item)? itemLabel;
  final String? hint;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final bool isRequired;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, isRequired: isRequired),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          initialValue: value,
          validator: validator,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(AppRadius.md),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md - 4,
                      right: AppSpacing.sm + 2,
                    ),
                    child: Icon(prefixIcon, size: 19),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel?.call(item) ?? item.toString()),
              ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
