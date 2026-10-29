import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/visitor.dart';
import '../data/visitor_status.dart';
import '../state/visitor_providers.dart';
import '../widgets/status_chip.dart';
import '../widgets/visitor_card.dart';

class VisitorListScreen extends ConsumerStatefulWidget {
  const VisitorListScreen({super.key});

  @override
  ConsumerState<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends ConsumerState<VisitorListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(visitorFilterProvider).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      if (mounted) {
        AppFeedback.success(context, '${visitor.name} was deleted');
      }
    } on ApiFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listState = ref.watch(visitorListProvider);
    final filter = ref.watch(visitorFilterProvider);
    final visitors = ref.watch(filteredVisitorsProvider);
    final all = listState.value ?? const <Visitor>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Visitors',
              subtitle: 'Manage and track every visit',
              actions: [
                SquareIconButton(
                  icon: Icons.person_add_alt_1_rounded,
                  tooltip: 'Register visitor',
                  tinted: true,
                  onPressed: () => context.push('/register'),
                ),
                SquareIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onPressed: () =>
                      ref.read(visitorListProvider.notifier).refresh(),
                ),
              ],
            ),
            _SearchField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(visitorFilterProvider.notifier).setQuery(value),
              onClear: () {
                _searchController.clear();
                ref.read(visitorFilterProvider.notifier).setQuery('');
              },
            ),
            _FilterBar(all: all),
            _ListToolbar(
              shown: visitors.length,
              total: all.length,
              isFiltered: filter.isActive,
              sort: filter.sort,
              onSortChanged: (value) =>
                  ref.read(visitorFilterProvider.notifier).setSort(value),
              onClear: () {
                _searchController.clear();
                ref.read(visitorFilterProvider.notifier).clear();
              },
            ),
            Expanded(
              child: listState.when(
                skipLoadingOnRefresh: true,
                loading: () => const LoadingView(message: 'Loading visitors…'),
                error: (error, _) => ErrorStateView(
                  message: error.toString(),
                  onRetry: () =>
                      ref.read(visitorListProvider.notifier).refresh(),
                ),
                data: (_) => _VisitorListBody(
                  visitors: visitors,
                  isFiltered: filter.isActive,
                  onRefresh: () =>
                      ref.read(visitorListProvider.notifier).refresh(),
                  onOpen: (visitor) => context.push('/visitors/${visitor.id}'),
                  onEdit: (visitor) =>
                      context.push('/visitors/${visitor.id}/edit'),
                  onDelete: _confirmDelete,
                  theme: theme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitorListBody extends StatelessWidget {
  const _VisitorListBody({
    required this.visitors,
    required this.isFiltered,
    required this.onRefresh,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.theme,
  });

  final List<Visitor> visitors;
  final bool isFiltered;
  final Future<void> Function() onRefresh;
  final void Function(Visitor visitor) onOpen;
  final void Function(Visitor visitor) onEdit;
  final void Function(Visitor visitor) onDelete;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (visitors.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: isFiltered
                  ? const EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: 'No matching visitors',
                      message:
                          'Try a different name or number, or clear the filters.',
                    )
                  : const EmptyStateView(
                      icon: Icons.groups_rounded,
                      title: "You're all caught up",
                      message: 'New visitors will appear here.',
                    ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm - 4,
          AppSpacing.gutter,
          AppSpacing.navClearance,
        ),
        itemCount: visitors.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm + 4),
        itemBuilder: (context, index) {
          final visitor = visitors[index];
          return VisitorCard(
            visitor: visitor,
            onTap: () => onOpen(visitor),
            onEdit: () => onEdit(visitor),
            onDelete: () => onDelete(visitor),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.md - 4,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14.5),
        decoration: InputDecoration(
          hintText: 'Search by name or mobile',
          filled: true,
          fillColor: isLight ? Colors.white : AppColors.slate800,
          prefixIcon: const Icon(Icons.search_rounded, size: 21),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          border: _pill(theme),
          enabledBorder: _pill(theme),
          focusedBorder: _pill(theme, focused: true),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: onClear,
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _pill(ThemeData theme, {bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide(
        color: focused
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
        width: focused ? 1.6 : 1,
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.all});

  final List<Visitor> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(visitorFilterProvider);
    final notifier = ref.read(visitorFilterProvider.notifier);

    int countOf(VisitorStatus status) =>
        all.where((visitor) => visitor.status == status).length;

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        children: [
          _FilterPill(
            icon: Icons.groups_rounded,
            label: 'All',
            count: all.length,
            color: AppColors.indigo,
            selected: filter.status == null,
            onTap: () => notifier.setStatus(null),
          ),
          for (final status in VisitorStatus.values) ...[
            const SizedBox(width: AppSpacing.sm + 2),
            _FilterPill(
              icon: StatusChip.iconFor(status),
              label: status.label,
              count: countOf(status),
              color: StatusChip.colorFor(status),
              selected: filter.status == status,
              onTap: () => notifier.setStatus(
                filter.status == status ? null : status,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final foreground = selected ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: selected
          ? AppColors.indigo
          : (isLight ? Colors.white : AppColors.slate800),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? AppColors.indigo
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 4,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : color,
                ),
                const SizedBox(width: AppSpacing.sm - 2),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm - 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm - 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.24)
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListToolbar extends StatelessWidget {
  const _ListToolbar({
    required this.shown,
    required this.total,
    required this.isFiltered,
    required this.sort,
    required this.onSortChanged,
    required this.onClear,
  });

  final int shown;
  final int total;
  final bool isFiltered;
  final VisitorSort sort;
  final ValueChanged<VisitorSort> onSortChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isFiltered ? '$shown of $total visitors' : '$total visitors',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
            ),
          ),
          if (isFiltered)
            TextButton(onPressed: onClear, child: const Text('Clear')),
          PopupMenuButton<VisitorSort>(
            tooltip: 'Change order',
            initialValue: sort,
            onSelected: onSortChanged,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            itemBuilder: (_) => [
              for (final option in VisitorSort.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 4,
                vertical: AppSpacing.sm + 1,
              ),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.slate800,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_vert_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    sort.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 17,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
