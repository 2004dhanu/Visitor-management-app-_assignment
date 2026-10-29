import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/custom_button.dart';
import '../data/visitor.dart';
import '../data/visitor_qr.dart';
import '../state/visitor_providers.dart';
import '../widgets/status_chip.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _controller;

  bool _handling = false;
  bool _isResolving = false;
  bool _cameraRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1200,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _syncCamera(bool shouldRun) async {
    if (_cameraRunning == shouldRun) return;
    _cameraRunning = shouldRun;
    try {
      if (shouldRun) {
        await _controller.start();
      } else {
        await _controller.stop();
      }
    } on MobileScannerException {
      return;
    }
  }

  Future<void> _pause() async {
    try {
      await _controller.stop();
    } on MobileScannerException {
      return;
    }
  }

  Future<void> _resume() async {
    if (!mounted) return;
    setState(() => _isResolving = false);
    try {
      await _controller.start();
    } on MobileScannerException {
      return;
    }
    _handling = false;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || capture.barcodes.isEmpty) return;
    _handling = true;

    final raw = capture.barcodes.first.rawValue;
    await _pause();

    final visitorId = VisitorQr.decode(raw);
    if (visitorId == null) {
      if (mounted) {
        AppFeedback.error(
          context,
          'Invalid QR code. This is not a visitor pass.',
        );
      }
      await _resume();
      return;
    }

    await _resolve(visitorId);
  }

  Future<void> _resolve(String visitorId) async {
    if (mounted) setState(() => _isResolving = true);

    try {
      final visitor =
          await ref.read(visitorListProvider.notifier).fetchFresh(visitorId);
      if (!mounted) return;
      setState(() => _isResolving = false);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ScannedVisitorSheet(visitorId: visitor.id),
      );
    } on ApiFailure catch (failure) {
      if (mounted) {
        AppFeedback.error(
          context,
          failure.isNotFound
              ? 'No visitor found for this pass. It may have been deleted.'
              : failure.message,
        );
      }
    } finally {
      await _resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabActive =
        GoRouterState.of(context).matchedLocation.startsWith('/scan');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCamera(isTabActive);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Visitor Pass'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (!state.isInitialized) return const SizedBox.shrink();
              final isOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: isOn ? 'Turn off torch' : 'Turn on torch',
                onPressed: () => _controller.toggleTorch(),
                icon: Icon(isOn ? Icons.flash_on : Icons.flash_off),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerErrorView(
              error: error,
              onRetry: () async {
                _cameraRunning = false;
                await _syncCamera(true);
              },
            ),
          ),
          const _ScanFrame(),
          if (_isResolving) const _ResolvingOverlay(),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ScannerHint(),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide * 0.68;
          return SizedBox(
            height: side,
            width: side,
            child: Stack(
              children: const [
                _Corner(top: true, left: true),
                _Corner(top: true, left: false),
                _Corner(top: false, left: true),
                _Corner(top: false, left: false),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const thickness = 4.0;
    const length = 34.0;
    const radius = Radius.circular(AppRadius.md);
    const side = BorderSide(color: Colors.white, width: thickness);

    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        height: length,
        width: length,
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

class _ScannerHint extends StatelessWidget {
  const _ScannerHint();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.navClearance - AppSpacing.lg,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.white, size: 20),
            SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                'Hold the visitor pass inside the frame to check them in or out.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvingOverlay extends StatelessWidget {
  const _ResolvingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: AppSpacing.md),
            Text(
              'Looking up visitor…',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final isUnsupported =
        error.errorCode == MobileScannerErrorCode.unsupported;

    final (String title, String message, IconData icon) = switch (true) {
      _ when isPermission => (
          'Camera permission needed',
          'Scanning visitor passes requires the camera. Allow camera access for this app in your device settings, then try again.',
          Icons.no_photography_outlined,
        ),
      _ when isUnsupported => (
          'Scanning not supported',
          'This device cannot be used to scan QR codes. You can still check visitors in from the visitor list.',
          Icons.videocam_off_outlined,
        ),
      _ => (
          'Camera unavailable',
          'The camera could not be started. Close any other app using it and try again.',
          Icons.videocam_off_outlined,
        ),
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.white70),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              if (!isUnsupported) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannedVisitorSheet extends ConsumerStatefulWidget {
  const _ScannedVisitorSheet({required this.visitorId});

  final String visitorId;

  @override
  ConsumerState<_ScannedVisitorSheet> createState() =>
      _ScannedVisitorSheetState();
}

class _ScannedVisitorSheetState extends ConsumerState<_ScannedVisitorSheet> {
  bool _isBusy = false;

  Future<void> _changeStatus({required bool checkingIn}) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      final notifier = ref.read(visitorListProvider.notifier);
      final updated = checkingIn
          ? await notifier.checkIn(widget.visitorId)
          : await notifier.checkOut(widget.visitorId);

      if (!mounted) return;
      final navigator = Navigator.of(context);
      final message = checkingIn
          ? '${updated.name} checked in at ${AppDate.formatTime(updated.checkInTime)}'
          : '${updated.name} checked out at ${AppDate.formatTime(updated.checkOutTime)}';

      navigator.pop();
      AppFeedback.success(navigator.context, message);
    } on BusinessRuleFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    } on ApiFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visitor = ref.watch(visitorByIdProvider(widget.visitorId));

    if (visitor == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('This visitor is no longer available.'),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  visitor.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(status: visitor.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${visitor.visitorType}  ·  ${visitor.project}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            visitor.mobile,
            style: theme.textTheme.bodyMedium,
          ),
          if (visitor.checkInTime != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Checked in ${AppDate.format(visitor.checkInTime)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.checkedIn,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SheetAction(
            visitor: visitor,
            isBusy: _isBusy,
            onCheckIn: () => _changeStatus(checkingIn: true),
            onCheckOut: () => _changeStatus(checkingIn: false),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          CustomButton(
            label: 'View Full Details',
            icon: Icons.open_in_new,
            variant: CustomButtonVariant.secondary,
            onPressed: _isBusy
                ? null
                : () {
                    Navigator.of(context).pop();
                    context.push('/visitors/${visitor.id}');
                  },
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.visitor,
    required this.isBusy,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final Visitor visitor;
  final bool isBusy;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    if (visitor.status.canCheckIn) {
      return CustomButton(
        label: 'Check In',
        icon: Icons.login_rounded,
        isLoading: isBusy,
        onPressed: onCheckIn,
      );
    }

    if (visitor.status.canCheckOut) {
      return CustomButton(
        label: 'Check Out',
        icon: Icons.logout_rounded,
        isLoading: isBusy,
        onPressed: onCheckOut,
      );
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              'This visit is already complete.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
