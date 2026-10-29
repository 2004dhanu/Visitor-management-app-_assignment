import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/visitor.dart';
import '../data/visitor_status.dart';
import '../state/visitor_providers.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/visitor_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listState = ref.watch(visitorListProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final visitors = listState.value ?? const <Visitor>[];
    final recent = visitors.take(3).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(visitorListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
            children: [
              const _AppHeader(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: _HeroCard(),
              ),
              const SizedBox(height: AppSpacing.lg),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Today's activity",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const _TodayPill(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md - 2),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: listState.hasError && !listState.hasValue
                    ? Card(
                        child: ErrorStateView(
                          title: 'Could not load statistics',
                          message: listState.error.toString(),
                          onRetry: () =>
                              ref.read(visitorListProvider.notifier).refresh(),
                        ),
                      )
                    : _StatGrid(stats: stats, isLoading: listState.isLoading),
              ),

              if (recent.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.sm + 2,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent visitors',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(visitorFilterProvider.notifier).clear();
                          context.go('/visitors');
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View all'),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final visitor in recent)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      AppSpacing.sm + 4,
                    ),
                    child: VisitorCard(
                      visitor: visitor,
                      compact: true,
                      onTap: () => context.push('/visitors/${visitor.id}'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends ConsumerWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Visitor Management',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                Text(
                  'Safe people. Safer spaces.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SquareIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: () => ref.read(visitorListProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 4,
        vertical: AppSpacing.sm + 1,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : AppColors.slate800,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm - 2),
          Text(
            DateFormat('EEE, d MMM').format(DateTime.now()),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          boxShadow: AppShadows.floating(theme.brightness),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _SkylinePainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM')
                        .format(DateTime.now())
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm - 2),
                  Text(
                    _greeting,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 27,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm - 2),
                  const Text(
                    'Register a visitor or scan a pass at the gate '
                    'to keep your workplace secure.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg - 4),
                  Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: _HeroAction(
                          label: 'Register Visitor',
                          icon: Icons.person_add_alt_1_rounded,
                          filled: true,
                          onTap: () => context.push('/register'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        flex: 9,
                        child: _HeroAction(
                          label: 'Scan QR',
                          icon: Icons.qr_code_scanner_rounded,
                          filled: false,
                          onTap: () => context.go('/scan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.2),
      size.height * 0.52,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    const heights = [0.46, 0.62, 0.36];
    const widths = [0.13, 0.15, 0.11];
    var left = size.width * 0.62;

    for (var i = 0; i < heights.length; i++) {
      final blockWidth = size.width * widths[i];
      final blockHeight = size.height * heights[i];
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            left,
            size.height - blockHeight,
            blockWidth,
            blockHeight,
          ),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        paint,
      );
      left += blockWidth + size.width * 0.03;
    }
  }

  @override
  bool shouldRepaint(_SkylinePainter oldDelegate) => false;
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.indigo : Colors.white;

    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 4,
            vertical: AppSpacing.md - 1,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.sm - 2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 17, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends ConsumerWidget {
  const _StatGrid({required this.stats, required this.isLoading});

  final DashboardStats stats;
  final bool isLoading;

  void _showFiltered(
    BuildContext context,
    WidgetRef ref,
    VisitorStatus? status,
  ) {
    final notifier = ref.read(visitorFilterProvider.notifier);
    notifier.clear();
    notifier.setStatus(status);
    context.go('/visitors');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm + 2;
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = constraints.maxWidth >= 330 && textScale < 1.3 ? 3 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        final cards = [
          DashboardStatCard(
            label: 'Total today',
            value: stats.registeredToday,
            icon: Icons.groups_rounded,
            color: AppColors.registered,
            trend: stats.registeredTrend,
            isLoading: isLoading,
            onTap: () => _showFiltered(context, ref, null),
          ),
          DashboardStatCard(
            label: 'Inside now',
            value: stats.currentlyCheckedIn,
            icon: Icons.login_rounded,
            color: AppColors.checkedIn,
            trend: stats.checkInTrend,
            isLoading: isLoading,
            onTap: () => _showFiltered(context, ref, VisitorStatus.checkedIn),
          ),
          DashboardStatCard(
            label: 'Checked out',
            value: stats.checkedOutToday,
            icon: Icons.logout_rounded,
            color: AppColors.exit,
            trend: stats.checkOutTrend,
            isLoading: isLoading,
            onTap: () => _showFiltered(context, ref, VisitorStatus.checkedOut),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}
