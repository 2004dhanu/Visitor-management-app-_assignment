import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/step_indicator.dart';
import '../data/visitor.dart';
import '../state/visitor_providers.dart';
import '../widgets/status_chip.dart';
import '../widgets/visit_timeline.dart';
import '../widgets/visitor_card.dart';
import '../widgets/visitor_qr_card.dart';

class VisitorDetailsScreen extends ConsumerStatefulWidget {
  const VisitorDetailsScreen({super.key, required this.visitorId});

  final String visitorId;

  @override
  ConsumerState<VisitorDetailsScreen> createState() =>
      _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends ConsumerState<VisitorDetailsScreen> {
  bool _isBusy = false;
  bool _isFetching = false;
  bool _isSendingPass = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    if (ref.read(visitorByIdProvider(widget.visitorId)) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    }
  }

  Future<void> _fetch() async {
    if (_isFetching || !mounted) return;
    setState(() {
      _isFetching = true;
      _fetchError = null;
    });
    try {
      await ref.read(visitorListProvider.notifier).fetchFresh(widget.visitorId);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _fetchError = failure.message);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _copy(String value, String what) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    AppFeedback.success(context, '$what copied to clipboard');
  }

  Future<void> _resendPass(Visitor visitor) async {
    if (_isSendingPass) return;
    setState(() => _isSendingPass = true);

    try {
      final delivery =
          await ref.read(visitorListProvider.notifier).sendPass(visitor.id);
      if (!mounted) return;
      if (delivery.sent) {
        AppFeedback.success(context, delivery.message);
      } else {
        AppFeedback.info(context, delivery.message);
      }
    } on ApiFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    } finally {
      if (mounted) setState(() => _isSendingPass = false);
    }
  }

  Future<void> _changeStatus({required bool checkingIn}) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      final notifier = ref.read(visitorListProvider.notifier);
      final updated = checkingIn
          ? await notifier.checkIn(widget.visitorId)
          : await notifier.checkOut(widget.visitorId);

      if (!mounted) return;
      AppFeedback.success(
        context,
        checkingIn
            ? '${updated.name} checked in at ${AppDate.formatTime(updated.checkInTime)}'
            : '${updated.name} checked out at ${AppDate.formatTime(updated.checkOutTime)}',
      );
    } on BusinessRuleFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    } on ApiFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmDelete(Visitor visitor) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete visitor?',
      message:
          '${visitor.name}\'s record will be permanently removed. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(visitorListProvider.notifier).remove(visitor.id);
      if (!mounted) return;
      AppFeedback.success(context, '${visitor.name} was deleted');
      context.pop();
    } on ApiFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitor = ref.watch(visitorByIdProvider(widget.visitorId));

    if (visitor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visitor Details')),
        body: _isFetching
            ? const LoadingView(message: 'Loading visitor…')
            : _fetchError != null
                ? ErrorStateView(message: _fetchError!, onRetry: _fetch)
                : const EmptyStateView(
                    icon: Icons.person_off_outlined,
                    title: 'Visitor not found',
                    message:
                        'This record is not available. It may have been deleted.',
                  ),
      );
    }

    final status = visitor.status;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Visitor Details',
              subtitle: 'View and manage visitor information',
              compactTitle: true,
              leading: SquareIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
              actions: [
                SquareIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit visitor',
                  tinted: true,
                  onPressed: () =>
                      context.push('/visitors/${visitor.id}/edit'),
                ),
                SquareIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete visitor',
                  tinted: true,
                  color: AppColors.danger,
                  onPressed: () => _confirmDelete(visitor),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                children: [
                  _VisitorHero(visitor: visitor),
                  const SizedBox(height: AppSpacing.md),

                  SectionCard(
                    title: 'Visitor Information',
                    subtitle: 'Basic details about the visitor',
                    icon: Icons.person_outline_rounded,
                    bodyPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md - 2,
                    ),
                    children: [
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Mobile Number',
                        value: visitor.mobile,
                        onCopy: () => _copy(visitor.mobile, 'Mobile number'),
                      ),
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: visitor.email ?? 'Not provided',
                        onCopy: visitor.email == null
                            ? null
                            : () => _copy(visitor.email!, 'Email'),
                      ),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Visitor Type',
                        valueWidget: SoftBadge(
                          label: visitor.visitorType,
                          color: AppColors.registered,
                        ),
                      ),
                      _InfoRow(
                        icon: Icons.apartment_rounded,
                        label: 'Project',
                        value: visitor.project,
                      ),
                      _InfoRow(
                        icon: Icons.notes_rounded,
                        label: 'Purpose of Visit',
                        value: visitor.purpose,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  SectionCard(
                    title: 'Visit Timeline',
                    subtitle: 'Track the complete visit history',
                    icon: Icons.schedule_rounded,
                    children: [VisitTimeline(visitor: visitor)],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  SectionCard(
                    title: 'Visitor Pass',
                    subtitle: 'Scan this QR code at the gate',
                    icon: Icons.qr_code_2_rounded,
                    trailing: SoftBadge(
                      label: status.isComplete ? 'Used' : 'Valid Pass',
                      icon: status.isComplete
                          ? Icons.check_circle_outline_rounded
                          : Icons.verified_rounded,
                      color: status.isComplete
                          ? AppColors.checkedOut
                          : AppColors.checkedIn,
                      dense: true,
                    ),
                    children: [
                      VisitorQrPanel(
                        visitor: visitor,
                        onCopyId: () => _copy(visitor.id, 'Pass ID'),
                      ),
                    ],
                  ),

                  if (visitor.hasPass) ...[
                    const SizedBox(height: AppSpacing.md),
                    _PassLinkCard(
                      visitor: visitor,
                      isSending: _isSendingPass,
                      onCopy: () => _copy(visitor.passUrl!, 'Pass link'),
                      onResend: () => _resendPass(visitor),
                    ),
                  ],

                  if (status.isComplete) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _CompletionCard(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: status.isComplete
          ? null
          : StickyFooter(
              children: [
                CustomButton(
                  label: status.canCheckIn ? 'Check In' : 'Check Out',
                  icon: status.canCheckIn
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
                  isLoading: _isBusy,
                  onPressed: () =>
                      _changeStatus(checkingIn: status.canCheckIn),
                ),
              ],
            ),
    );
  }
}

class _VisitorHero extends StatelessWidget {
  const _VisitorHero({required this.visitor});

  final Visitor visitor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = StatusChip.colorFor(visitor.status);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        gradient: isLight ? AppColors.subtleGradient : null,
        color: isLight ? null : AppColors.slate800,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isLight
            ? null
            : Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            height: 76,
            width: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              VisitorAvatar.initialsOf(visitor.name),
              style: TextStyle(
                color: accent,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  visitor.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 23,
                    color: isLight ? AppColors.slate900 : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(status: visitor.status),
                const SizedBox(height: AppSpacing.sm - 2),
                Text(
                  'Registered ${AppDate.relativeLong(visitor.createdAt, fallback: 'recently')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: isLight ? AppColors.slate600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.onCopy,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final VoidCallback? onCopy;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 3),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 13.5),
                  ),
            ),
          ),
          if (onCopy != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: IconButton(
                onPressed: onCopy,
                tooltip: 'Copy $label',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 15),
              ),
            ),
        ],
      ),
    );
  }
}

class _PassLinkCard extends StatelessWidget {
  const _PassLinkCard({
    required this.visitor,
    required this.isSending,
    required this.onCopy,
    required this.onResend,
  });

  final Visitor visitor;
  final bool isSending;
  final VoidCallback onCopy;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = visitor.email;

    return SectionCard(
      title: 'Visitor pass link',
      subtitle: 'Share this link with the visitor',
      icon: Icons.link_rounded,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  visitor.passUrl!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SquareIconButton(
                icon: Icons.copy_rounded,
                tooltip: 'Copy link',
                size: 34,
                iconSize: 15,
                onPressed: onCopy,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Text(
          email == null
              ? 'No email address on file — copy the link and send it to the '
                  'visitor yourself.'
              : 'Emailed to $email when they were registered.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'Copy Link',
                icon: Icons.copy_rounded,
                variant: CustomButtonVariant.secondary,
                onPressed: onCopy,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: CustomButton(
                label: 'Email Again',
                icon: Icons.mail_outline_rounded,
                variant: CustomButtonVariant.tonal,
                isLoading: isSending,
                onPressed: email == null ? null : onResend,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.checkedIn.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.checkedIn.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.checkedIn,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This visit is complete',
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(
                  'The visitor has checked out. No further action is required.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
