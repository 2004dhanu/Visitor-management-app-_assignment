import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/utils/app_date.dart';
import 'visitor.dart';
import 'visitor_status.dart';

class PassDelivery {
  const PassDelivery({required this.sent, required this.message});

  final bool sent;
  final String message;

  static PassDelivery? fromRegistration(Map<String, dynamic> record) {
    final sent = record['pass_email_sent'];
    if (sent is! bool) return null;

    final message = record['pass_email_message'];
    return PassDelivery(
      sent: sent,
      message: message is String && message.trim().isNotEmpty
          ? message.trim()
          : (sent ? 'Pass link emailed.' : 'The pass email was not sent.'),
    );
  }
}

class RegistrationResult {
  const RegistrationResult({required this.visitor, this.delivery});

  final Visitor visitor;
  final PassDelivery? delivery;
}

class VisitorRepository {
  VisitorRepository(this._client);

  final ApiClient _client;

  String get _collection => AppConfig.visitorsPath;

  String _item(String id) => '$_collection/$id';

  Future<List<Visitor>> fetchAll() async {
    final data = await _client.get(_collection);
    if (data is! List) {
      throw const ApiFailure(
        ApiFailureKind.parse,
        'The server returned an unexpected response for the visitor list.',
      );
    }

    final visitors = <Visitor>[];
    for (final entry in data) {
      final record = _asJsonMap(entry);
      if (record != null) visitors.add(Visitor.fromJson(record));
    }

    visitors.sort((a, b) {
      final left = AppDate.tryParseLocal(a.createdAt);
      final right = AppDate.tryParseLocal(b.createdAt);
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });

    return visitors;
  }

  Future<Visitor> fetchById(String id) async {
    final data = await _client.get(_item(id));
    final record = _asJsonMap(data);
    if (record == null) {
      throw const ApiFailure(
        ApiFailureKind.parse,
        'The server returned an unexpected response for this visitor.',
      );
    }
    return Visitor.fromJson(record);
  }

  Future<RegistrationResult> create(Visitor draft) async {
    final body = draft
        .copyWith(createdAt: () => draft.createdAt ?? AppDate.nowIso())
        .toCreateJson();

    final data = await _client.post(_collection, body: body);
    final record = _asJsonMap(data);
    if (record == null || Visitor.fromJson(record).id.isEmpty) {
      throw const ApiFailure(
        ApiFailureKind.parse,
        'The visitor was sent but the server did not return an ID.',
      );
    }

    return RegistrationResult(
      visitor: Visitor.fromJson(record),
      delivery: PassDelivery.fromRegistration(record),
    );
  }

  Future<PassDelivery> sendPass(String id) async {
    try {
      final data = await _client.post('${_item(id)}/send-pass');
      final record = _asJsonMap(data) ?? const {};
      return PassDelivery(
        sent: record['sent'] == true,
        message: _messageOf(record) ?? 'Pass email sent.',
      );
    } on ApiFailure catch (failure) {
      if (failure.kind == ApiFailureKind.badRequest) {
        return PassDelivery(sent: false, message: failure.message);
      }
      rethrow;
    }
  }

  String? _messageOf(Map<String, dynamic> record) {
    final message = record['message'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        : null;
  }

  Future<Visitor> update(Visitor visitor) async {
    final data = await _client.put(_item(visitor.id), body: visitor.toUpdateJson());
    return _decodeOr(data, visitor);
  }

  Future<void> delete(String id) => _client.delete(_item(id));

  Future<Visitor> checkIn(Visitor visitor) {
    final timestamp = AppDate.nowIso();
    return _patchStatus(
      visitor,
      patch: {
        'status': VisitorStatus.checkedIn.apiValue,
        'check_in_time': timestamp,
      },
      expected: visitor.copyWith(
        status: VisitorStatus.checkedIn,
        checkInTime: () => timestamp,
      ),
    );
  }

  Future<Visitor> checkOut(Visitor visitor) {
    final timestamp = AppDate.nowIso();
    return _patchStatus(
      visitor,
      patch: {
        'status': VisitorStatus.checkedOut.apiValue,
        'check_out_time': timestamp,
      },
      expected: visitor.copyWith(
        status: VisitorStatus.checkedOut,
        checkOutTime: () => timestamp,
      ),
    );
  }

  Future<Visitor> _patchStatus(
    Visitor visitor, {
    required Map<String, dynamic> patch,
    required Visitor expected,
  }) async {
    try {
      final data = await _client.patch(_item(visitor.id), body: patch);
      return _decodeOr(data, expected);
    } on ApiFailure catch (failure) {
      if (failure.statusCode != 405) rethrow;
      final data = await _client.put(_item(visitor.id), body: expected.toUpdateJson());
      return _decodeOr(data, expected);
    }
  }

  Visitor _decodeOr(Object? data, Visitor fallback) {
    final record = _asJsonMap(data);
    if (record == null) return fallback;
    final parsed = Visitor.fromJson(record);
    return parsed.id.isEmpty ? fallback : parsed;
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }
}
