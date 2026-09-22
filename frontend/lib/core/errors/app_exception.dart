/// Base exception class for all SpendWise application errors.
abstract class AppException implements Exception {
  final String message;
  final dynamic details;

  const AppException(this.message, {this.details});

  @override
  String toString() => message;
}

/// Represents an API HTTP error (4xx or 5xx).
class ApiException extends AppException {
  final int? statusCode;

  const ApiException(
    super.message, {
    this.statusCode,
    super.details,
  });

  @override
  String toString() => statusCode != null ? '[$statusCode] $message' : message;
}

/// Represents network/connectivity failures (timeout, socket exception, host unreachable).
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Unable to connect to the server. Please check your internet connection.',
    dynamic details,
  ]) : super(details: details);
}

/// Represents authentication failures (e.g. 401 Unauthorized / expired token).
class AuthException extends ApiException {
  const AuthException([
    super.message = 'Session expired or unauthorized. Please log in again.',
    dynamic details,
  ]) : super(statusCode: 401, details: details);
}
