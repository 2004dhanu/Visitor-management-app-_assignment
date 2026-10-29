import 'package:dio/dio.dart';

enum ApiFailureKind {
  network,
  timeout,
  notFound,
  badRequest,
  conflict,
  server,
  parse,
  cancelled,
  unknown,
}

class ApiFailure implements Exception {
  const ApiFailure(this.kind, this.message, {this.statusCode});

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;

  bool get isNotFound => kind == ApiFailureKind.notFound;

  factory ApiFailure.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure(
          ApiFailureKind.timeout,
          'The server took too long to respond. Please try again.',
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiFailure(
          ApiFailureKind.network,
          'No internet connection. Check your network and try again.',
        );

      case DioExceptionType.cancel:
        return const ApiFailure(ApiFailureKind.cancelled, 'Request cancelled.');

      case DioExceptionType.badCertificate:
        return const ApiFailure(
          ApiFailureKind.network,
          'Could not establish a secure connection to the server.',
        );

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final fromServer = _serverMessage(error.response?.data);

        if (status == 404) {
          return ApiFailure(
            ApiFailureKind.notFound,
            fromServer ?? 'That record could not be found on the server.',
            statusCode: status,
          );
        }
        if (status == 409) {
          return ApiFailure(
            ApiFailureKind.conflict,
            fromServer ??
                "That action conflicts with the visitor's current status.",
            statusCode: status,
          );
        }
        if (status != null && status >= 400 && status < 500) {
          return ApiFailure(
            ApiFailureKind.badRequest,
            fromServer ?? 'The server rejected the request ($status).',
            statusCode: status,
          );
        }
        return ApiFailure(
          ApiFailureKind.server,
          fromServer ??
              'The server is having trouble right now. Please try again shortly.',
          statusCode: status,
        );
    }
  }

  static String? _serverMessage(Object? data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  @override
  String toString() => message;
}

class BusinessRuleFailure implements Exception {
  const BusinessRuleFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
