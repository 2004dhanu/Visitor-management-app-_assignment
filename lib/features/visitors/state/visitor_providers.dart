import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/utils/app_date.dart';
import '../data/visitor.dart';
import '../data/visitor_repository.dart';
import '../data/visitor_status.dart';


final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final visitorRepositoryProvider = Provider<VisitorRepository>(
  (ref) => VisitorRepository(ref.watch(apiClientProvider)),
);


class VisitorListNotifier extends AsyncNotifier<List<Visitor>> {
  final Set<String> _inFlight = <String>{};

  @override
  Future<List<Visitor>> build() =>
      ref.read(visitorRepositoryProvider).fetchAll();

  VisitorRepository get _repository => ref.read(visitorRepositoryProvider);

  List<Visitor> get _visitors => state.value ?? const <Visitor>[];

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.fetchAll);
  }

  Future<RegistrationResult> register(Visitor draft) async {
    final result = await _repository.create(draft);
    state = AsyncValue.data(<Visitor>[result.visitor, ..._visitors]);
    return result;
  }

  Future<PassDelivery> sendPass(String id) => _repository.sendPass(id);

  Future<Visitor> edit(Visitor visitor) async {
    final updated = await _repository.update(visitor);
    _replace(updated);
    return updated;
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    state = AsyncValue.data(
      _visitors.where((visitor) => visitor.id != id).toList(),
    );
  }

  Future<Visitor> checkIn(String id) => _changeStatus(id, checkingIn: true);

  Future<Visitor> checkOut(String id) => _changeStatus(id, checkingIn: false);

  Future<Visitor> fetchFresh(String id) async {
    final visitor = await _repository.fetchById(id);
    _upsert(visitor);
    return visitor;
  }

  Future<Visitor> _changeStatus(String id, {required bool checkingIn}) async {
    if (!_inFlight.add(id)) {
      throw const BusinessRuleFailure(
        'That action is already being processed.',
      );
    }

    try {
      final visitor = await _resolve(id);
      final status = visitor.status;

      if (checkingIn && !status.canCheckIn) {
        throw BusinessRuleFailure(
          status.isComplete
              ? '${visitor.name} has already completed this visit and cannot check in again.'
              : '${visitor.name} is already checked in.',
        );
      }
      if (!checkingIn && !status.canCheckOut) {
        throw BusinessRuleFailure(
          status.isComplete
              ? '${visitor.name} has already checked out.'
              : '${visitor.name} has not checked in yet.',
        );
      }

      final updated = checkingIn
          ? await _repository.checkIn(visitor)
          : await _repository.checkOut(visitor);
      _replace(updated);
      return updated;
    } finally {
      _inFlight.remove(id);
    }
  }

  Future<Visitor> _resolve(String id) async {
    for (final visitor in _visitors) {
      if (visitor.id == id) return visitor;
    }
    return fetchFresh(id);
  }

  void _replace(Visitor updated) {
    state = AsyncValue.data(<Visitor>[
      for (final visitor in _visitors)
        if (visitor.id == updated.id) updated else visitor,
    ]);
  }

  void _upsert(Visitor visitor) {
    final known = _visitors.any((existing) => existing.id == visitor.id);
    state = AsyncValue.data(
      known
          ? <Visitor>[
              for (final existing in _visitors)
                if (existing.id == visitor.id) visitor else existing,
            ]
          : <Visitor>[visitor, ..._visitors],
    );
  }
}

final visitorListProvider =
    AsyncNotifierProvider<VisitorListNotifier, List<Visitor>>(
  VisitorListNotifier.new,
);


enum VisitorSort {
  recent('Recently added'),
  name('Name A–Z');

  const VisitorSort(this.label);

  final String label;
}

class VisitorFilter {
  const VisitorFilter({
    this.query = '',
    this.project,
    this.status,
    this.sort = VisitorSort.recent,
  });

  final String query;
  final String? project;
  final VisitorStatus? status;
  final VisitorSort sort;

  bool get isActive =>
      query.trim().isNotEmpty || project != null || status != null;

  VisitorFilter copyWith({
    String? query,
    String? Function()? project,
    VisitorStatus? Function()? status,
    VisitorSort? sort,
  }) {
    return VisitorFilter(
      query: query ?? this.query,
      project: project == null ? this.project : project(),
      status: status == null ? this.status : status(),
      sort: sort ?? this.sort,
    );
  }
}

class VisitorFilterNotifier extends Notifier<VisitorFilter> {
  @override
  VisitorFilter build() => const VisitorFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setProject(String? value) =>
      state = state.copyWith(project: () => value);

  void setStatus(VisitorStatus? value) =>
      state = state.copyWith(status: () => value);

  void setSort(VisitorSort value) => state = state.copyWith(sort: value);

  void clear() => state = VisitorFilter(sort: state.sort);
}

final visitorFilterProvider =
    NotifierProvider<VisitorFilterNotifier, VisitorFilter>(
  VisitorFilterNotifier.new,
);


final filteredVisitorsProvider = Provider<List<Visitor>>((ref) {
  final all = ref.watch(visitorListProvider).value ?? const <Visitor>[];
  final filter = ref.watch(visitorFilterProvider);

  final matches = all.where((visitor) {
    if (!visitor.matches(filter.query)) return false;
    if (filter.project != null && visitor.project != filter.project) {
      return false;
    }
    if (filter.status != null && visitor.status != filter.status) return false;
    return true;
  }).toList();

  if (filter.sort == VisitorSort.name) {
    matches.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  return matches;
});

final visitorByIdProvider = Provider.family<Visitor?, String>((ref, id) {
  final all = ref.watch(visitorListProvider).value ?? const <Visitor>[];
  for (final visitor in all) {
    if (visitor.id == id) return visitor;
  }
  return null;
});

class DashboardStats {
  const DashboardStats({
    required this.registeredToday,
    required this.currentlyCheckedIn,
    required this.checkedOutToday,
    this.registeredTrend = const [],
    this.checkInTrend = const [],
    this.checkOutTrend = const [],
  });

  final int registeredToday;
  final int currentlyCheckedIn;
  final int checkedOutToday;

  final List<int> registeredTrend;
  final List<int> checkInTrend;
  final List<int> checkOutTrend;

  static const DashboardStats empty = DashboardStats(
    registeredToday: 0,
    currentlyCheckedIn: 0,
    checkedOutToday: 0,
  );
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final all = ref.watch(visitorListProvider).value ?? const <Visitor>[];

  var registeredToday = 0;
  var currentlyCheckedIn = 0;
  var checkedOutToday = 0;

  final registeredTrend = List<int>.filled(7, 0);
  final checkInTrend = List<int>.filled(7, 0);
  final checkOutTrend = List<int>.filled(7, 0);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  void bucket(List<int> trend, String? iso) {
    final date = AppDate.tryParseLocal(iso);
    if (date == null) return;
    final day = DateTime(date.year, date.month, date.day);
    final index = 6 - today.difference(day).inDays;
    if (index >= 0 && index < 7) trend[index]++;
  }

  for (final visitor in all) {
    if (AppDate.isToday(visitor.createdAt)) registeredToday++;
    if (visitor.status == VisitorStatus.checkedIn) currentlyCheckedIn++;
    if (AppDate.isToday(visitor.checkOutTime)) checkedOutToday++;

    bucket(registeredTrend, visitor.createdAt);
    bucket(checkInTrend, visitor.checkInTime);
    bucket(checkOutTrend, visitor.checkOutTime);
  }

  return DashboardStats(
    registeredToday: registeredToday,
    currentlyCheckedIn: currentlyCheckedIn,
    checkedOutToday: checkedOutToday,
    registeredTrend: registeredTrend,
    checkInTrend: checkInTrend,
    checkOutTrend: checkOutTrend,
  );
});
