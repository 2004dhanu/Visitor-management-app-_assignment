import 'package:flutter_test/flutter_test.dart';
import 'package:visitor/core/utils/app_date.dart';
import 'package:visitor/core/utils/validators.dart';
import 'package:visitor/features/visitors/data/visitor.dart';
import 'package:visitor/features/visitors/data/visitor_qr.dart';
import 'package:visitor/features/visitors/data/visitor_status.dart';

void main() {
  group('VisitorStatus transitions', () {
    test('only a registered visitor may check in', () {
      expect(VisitorStatus.registered.canCheckIn, isTrue);
      expect(VisitorStatus.checkedIn.canCheckIn, isFalse);
      expect(VisitorStatus.checkedOut.canCheckIn, isFalse);
    });

    test('only a checked-in visitor may check out', () {
      expect(VisitorStatus.registered.canCheckOut, isFalse);
      expect(VisitorStatus.checkedIn.canCheckOut, isTrue);
      expect(VisitorStatus.checkedOut.canCheckOut, isFalse);
    });

    test('a completed visit allows no further action', () {
      expect(VisitorStatus.checkedOut.isComplete, isTrue);
      expect(VisitorStatus.checkedOut.canCheckIn, isFalse);
      expect(VisitorStatus.checkedOut.canCheckOut, isFalse);
    });

    test('parses the API values the server sends', () {
      expect(VisitorStatus.fromApi('Registered'), VisitorStatus.registered);
      expect(VisitorStatus.fromApi('Checked In'), VisitorStatus.checkedIn);
      expect(VisitorStatus.fromApi('Checked Out'), VisitorStatus.checkedOut);
    });

    test('tolerates hand-edited records and unknown values', () {
      expect(VisitorStatus.fromApi('checked_in'), VisitorStatus.checkedIn);
      expect(VisitorStatus.fromApi('CHECKEDOUT'), VisitorStatus.checkedOut);
      expect(VisitorStatus.fromApi('  Checked  In '), VisitorStatus.checkedIn);
      expect(VisitorStatus.fromApi(null), VisitorStatus.registered);
      expect(VisitorStatus.fromApi('nonsense'), VisitorStatus.registered);
    });
  });

  group('Validators', () {
    test('mobile must be exactly ten digits', () {
      expect(Validators.mobile('9876543210'), isNull);
      expect(Validators.mobile('98765'), isNotNull);
      expect(Validators.mobile('98765432100'), isNotNull);
      expect(Validators.mobile('98765abcde'), isNotNull);
      expect(Validators.mobile(''), isNotNull);
      expect(Validators.mobile(null), isNotNull);
    });

    test('email is optional but validated when supplied', () {
      expect(Validators.optionalEmail(null), isNull);
      expect(Validators.optionalEmail(''), isNull);
      expect(Validators.optionalEmail('   '), isNull);
      expect(Validators.optionalEmail('rahul@example.com'), isNull);
      expect(Validators.optionalEmail('rahul@'), isNotNull);
      expect(Validators.optionalEmail('not-an-email'), isNotNull);
    });

    test('required fields reject whitespace-only input', () {
      expect(Validators.requiredField('Rahul'), isNull);
      expect(Validators.requiredField('   '), isNotNull);
      expect(Validators.requiredField(null), isNotNull);
    });
  });

  group('VisitorQr', () {
    test('round-trips a visitor ID', () {
      expect(VisitorQr.decode(VisitorQr.encode('7')), '7');
      expect(VisitorQr.decode(VisitorQr.encode('VIS001')), 'VIS001');
    });

    test('rejects QR codes that are not visitor passes', () {
      expect(VisitorQr.decode('https://example.com'), isNull);
      expect(VisitorQr.decode('7'), isNull);
      expect(VisitorQr.decode('VMS:'), isNull);
      expect(VisitorQr.decode(''), isNull);
      expect(VisitorQr.decode(null), isNull);
    });
  });

  group('Visitor.fromJson', () {
    test('reads a well-formed record', () {
      final visitor = Visitor.fromJson(const {
        'id': 'VIS001',
        'name': 'Rahul Sharma',
        'mobile': '9876543210',
        'email': 'rahul@example.com',
        'visitor_type': 'Customer',
        'project': 'Project A',
        'purpose': 'Site Visit',
        'status': 'Registered',
        'created_at': '2026-10-26T10:00:00+05:30',
        'check_in_time': null,
        'check_out_time': null,
      });

      expect(visitor.id, 'VIS001');
      expect(visitor.name, 'Rahul Sharma');
      expect(visitor.status, VisitorStatus.registered);
      expect(visitor.checkInTime, isNull);
      expect(visitor.isPersisted, isTrue);
    });

    test('coerces numeric IDs and mobiles into strings', () {
      final visitor = Visitor.fromJson(const {
        'id': 7,
        'name': 'Priya',
        'mobile': 9876543210,
      });

      expect(visitor.id, '7');
      expect(visitor.mobile, '9876543210');
    });

    test('survives missing and empty fields', () {
      final visitor = Visitor.fromJson(const {'id': '3', 'name': 'Anil'});

      expect(visitor.id, '3');
      expect(visitor.email, isNull);
      expect(visitor.project, '');
      expect(visitor.visitorType, 'Other');
      expect(visitor.status, VisitorStatus.registered);
    });

    test('treats empty strings as absent for nullable fields', () {
      final visitor = Visitor.fromJson(const {
        'id': '4',
        'name': 'Sana',
        'email': '',
        'check_in_time': '',
      });

      expect(visitor.email, isNull);
      expect(visitor.checkInTime, isNull);
    });
  });

  group('Visitor.matches', () {
    const visitor = Visitor(
      id: '1',
      name: 'Rahul Sharma',
      mobile: '9876543210',
      email: null,
      visitorType: 'Customer',
      project: 'Project A',
      purpose: 'Site Visit',
      status: VisitorStatus.registered,
      createdAt: null,
      checkInTime: null,
      checkOutTime: null,
    );

    test('matches on name, case-insensitively', () {
      expect(visitor.matches('rahul'), isTrue);
      expect(visitor.matches('SHARMA'), isTrue);
      expect(visitor.matches('priya'), isFalse);
    });

    test('matches on mobile, ignoring punctuation and spaces', () {
      expect(visitor.matches('98765'), isTrue);
      expect(visitor.matches('987 654'), isTrue);
      expect(visitor.matches('12345'), isFalse);
    });

    test('an empty term matches everything', () {
      expect(visitor.matches(''), isTrue);
      expect(visitor.matches('   '), isTrue);
    });
  });

  group('AppDate', () {
    test('emits an ISO string with an explicit offset', () {
      final iso = AppDate.toIso(DateTime(2026, 10, 26, 10, 30));
      expect(iso, startsWith('2026-10-26T10:30:00'));
      expect(RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(iso), isTrue);
    });

    test('round-trips through parsing', () {
      final now = DateTime(2026, 10, 26, 10, 30);
      expect(AppDate.tryParseLocal(AppDate.toIso(now)), now);
    });

    test('isToday follows the device local date', () {
      expect(AppDate.isToday(AppDate.nowIso()), isTrue);
      expect(AppDate.isToday('2020-01-01T00:00:00+05:30'), isFalse);
      expect(AppDate.isToday(null), isFalse);
      expect(AppDate.isToday('not a date'), isFalse);
    });
  });
}
