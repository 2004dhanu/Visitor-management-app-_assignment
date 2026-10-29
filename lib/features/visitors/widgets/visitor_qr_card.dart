import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../data/visitor.dart';
import '../data/visitor_qr.dart';
import '../data/visitor_status.dart';

class VisitorQrPanel extends StatelessWidget {
  const VisitorQrPanel({
    super.key,
    required this.visitor,
    this.onCopyId,
    this.size = 180,
  });

  final Visitor visitor;
  final VoidCallback? onCopyId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = visitor.status == VisitorStatus.checkedOut;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg - 2),
          decoration: BoxDecoration(
            color: AppColors.indigo.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              SizedBox(
                height: size + 44,
                width: size + 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: _Brackets()),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: QrImageView(
                        data: VisitorQr.encode(visitor.id),
                        version: QrVersions.auto,
                        size: size,
                        gapless: true,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md - 4),
              _PassIdChip(id: visitor.id, onCopy: onCopyId),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 4),
        Text(
          isComplete
              ? 'This pass has been used for check-in and check-out.'
              : 'Present this code at the gate for check-in and check-out.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.5),
        ),
      ],
    );
  }
}

class _PassIdChip extends StatelessWidget {
  const _PassIdChip({required this.id, this.onCopy});

  final String id;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md - 2,
        AppSpacing.sm - 2,
        AppSpacing.sm - 2,
        AppSpacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : AppColors.slate800,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PASS ID',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '#VP-${id.padLeft(4, '0')}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (onCopy != null) ...[
            const SizedBox(width: AppSpacing.md - 4),
            IconButton(
              onPressed: onCopy,
              tooltip: 'Copy pass ID',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _Brackets extends StatelessWidget {
  const _Brackets();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _Corner(top: true, left: true),
        _Corner(top: true, left: false),
        _Corner(top: false, left: true),
        _Corner(top: false, left: false),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.indigo, width: 2.5);
    const radius = Radius.circular(AppRadius.sm);

    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? radius : Radius.zero,
            topRight: top && !left ? radius : Radius.zero,
            bottomLeft: !top && left ? radius : Radius.zero,
            bottomRight: !top && !left ? radius : Radius.zero,
          ),
        ),
      ),
    );
  }
}
