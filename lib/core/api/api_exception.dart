sealed class ApiException implements Exception {
  const ApiException();
}

final class NetworkTimeoutException extends ApiException {
  const NetworkTimeoutException();

  @override
  String toString() => 'Network timeout';
}

final class NetworkException extends ApiException {
  const NetworkException(this.message);

  final String message;

  @override
  String toString() => 'Network error: $message';
}

final class NotFoundException extends ApiException {
  const NotFoundException();

  @override
  String toString() => 'Resource not found';
}

final class UnauthorizedException extends ApiException {
  const UnauthorizedException();

  @override
  String toString() => 'Unauthorized';
}

final class ServerException extends ApiException {
  const ServerException(this.code, {this.feature});

  final String code;
  final String? feature;

  bool get isPlanned => code == 'planned_endpoint';

  @override
  String toString() => 'Server error: $code';
}

final class UnknownException extends ApiException {
  const UnknownException(this.message);

  final String message;

  @override
  String toString() => 'Unknown error: $message';
}
