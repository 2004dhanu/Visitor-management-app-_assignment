import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visitor/core/network/api_failure.dart';

void main() {
  final options = RequestOptions(path: '/visitors/1');

  DioException badResponse(int status, Object? body) => DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: status,
          data: body,
        ),
      );

  group('transport failures', () {
    test('a dropped connection reads as a network failure', () {
      final failure = ApiFailure.fromDio(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      expect(failure.kind, ApiFailureKind.network);
      expect(failure.message, contains('internet'));
    });

    test('a slow server reads as a timeout', () {
      final failure = ApiFailure.fromDio(
        DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );

      expect(failure.kind, ApiFailureKind.timeout);
    });
  });

  group('the API explains its own rejections', () {
    test('409 becomes a conflict carrying the server message', () {
      final failure = ApiFailure.fromDio(
        badResponse(409, {'message': 'Rahul Sharma is already checked in.'}),
      );

      expect(failure.kind, ApiFailureKind.conflict);
      expect(failure.statusCode, 409);
      expect(failure.message, 'Rahul Sharma is already checked in.');
    });

    test('404 is flagged as not found and keeps the server wording', () {
      final failure = ApiFailure.fromDio(
        badResponse(404, {'message': 'No visitor was found with that ID.'}),
      );

      expect(failure.isNotFound, isTrue);
      expect(failure.message, 'No visitor was found with that ID.');
    });

    test('422 validation errors reach the user verbatim', () {
      final failure = ApiFailure.fromDio(
        badResponse(422, {'message': 'Mobile number must be exactly 10 digits.'}),
      );

      expect(failure.kind, ApiFailureKind.badRequest);
      expect(failure.message, 'Mobile number must be exactly 10 digits.');
    });

    test('405 keeps its status code, so PATCH can fall back to PUT', () {
      final failure = ApiFailure.fromDio(badResponse(405, null));

      expect(failure.statusCode, 405);
    });
  });

  group('untrustworthy bodies', () {
    test('an HTML error page is never shown to the user', () {
      final failure = ApiFailure.fromDio(
        badResponse(500, '<html><body><h1>500 Internal Server Error</h1></body></html>'),
      );

      expect(failure.kind, ApiFailureKind.server);
      expect(failure.message, isNot(contains('<html>')));
      expect(failure.message, contains('trouble'));
    });

    test('a blank message falls back to the generic wording', () {
      final failure = ApiFailure.fromDio(badResponse(409, {'message': '   '}));

      expect(failure.kind, ApiFailureKind.conflict);
      expect(failure.message, contains('conflicts'));
    });

    test('a body with no message at all still produces something readable', () {
      final failure = ApiFailure.fromDio(badResponse(400, {'error': 'nope'}));

      expect(failure.message, isNotEmpty);
      expect(failure.kind, ApiFailureKind.badRequest);
    });
  });
}
