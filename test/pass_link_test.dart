import 'package:flutter_test/flutter_test.dart';
import 'package:visitor/features/visitors/data/visitor.dart';
import 'package:visitor/features/visitors/data/visitor_repository.dart';

void main() {
  group('Visitor pass link', () {
    test('reads the pass URL the API returns', () {
      final visitor = Visitor.fromJson(const {
        'id': '7',
        'name': 'Priya Nair',
        'pass_url': 'https://example.com/api/pass/abc123',
      });

      expect(visitor.passUrl, 'https://example.com/api/pass/abc123');
      expect(visitor.hasPass, isTrue);
    });

    test('a backend without pass links leaves it absent', () {
      final visitor = Visitor.fromJson(const {'id': '7', 'name': 'Priya Nair'});

      expect(visitor.passUrl, isNull);
      expect(visitor.hasPass, isFalse);
    });

    test('an empty pass URL counts as absent, not as a link', () {
      final visitor = Visitor.fromJson(const {
        'id': '7',
        'name': 'Priya Nair',
        'pass_url': '',
      });

      expect(visitor.passUrl, isNull);
      expect(visitor.hasPass, isFalse);
    });

    test('copyWith can clear the link without clearing everything else', () {
      final visitor = Visitor.fromJson(const {
        'id': '7',
        'name': 'Priya Nair',
        'pass_url': 'https://example.com/api/pass/abc123',
      });

      final cleared = visitor.copyWith(passUrl: () => null);

      expect(cleared.hasPass, isFalse);
      expect(cleared.name, 'Priya Nair');
      expect(visitor.hasPass, isTrue, reason: 'the original is untouched');
    });
  });

  group('PassDelivery.fromRegistration', () {
    test('reports a sent email with the server wording', () {
      final delivery = PassDelivery.fromRegistration(const {
        'pass_email_sent': true,
        'pass_email_message': 'Pass link emailed to priya@example.com.',
      });

      expect(delivery, isNotNull);
      expect(delivery!.sent, isTrue);
      expect(delivery.message, contains('priya@example.com'));
    });

    test('reports a refused send as an outcome, not an error', () {
      final delivery = PassDelivery.fromRegistration(const {
        'pass_email_sent': false,
        'pass_email_message': 'Visitor has no email address.',
      });

      expect(delivery!.sent, isFalse);
      expect(delivery.message, 'Visitor has no email address.');
    });

    test('a backend that sends no pass emails reports nothing at all', () {
      expect(PassDelivery.fromRegistration(const {'id': '7'}), isNull);
    });

    test('a non-boolean flag is treated as no delivery information', () {
      expect(
        PassDelivery.fromRegistration(const {'pass_email_sent': 'yes'}),
        isNull,
      );
    });

    test('a blank message still produces readable wording', () {
      final sent = PassDelivery.fromRegistration(const {
        'pass_email_sent': true,
        'pass_email_message': '   ',
      });
      final failed = PassDelivery.fromRegistration(const {
        'pass_email_sent': false,
      });

      expect(sent!.message, isNotEmpty);
      expect(failed!.message, isNotEmpty);
      expect(failed.message, isNot(equals(sent.message)));
    });
  });
}
