abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class ServerException extends AppException {
  final int? statusCode;
  
  const ServerException(super.message, [super.code, this.statusCode]);
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}

class AudioException extends AppException {
  const AudioException(super.message, [super.code]);
}

class WebSocketException extends AppException {
  const WebSocketException(super.message, [super.code]);
}

class CacheException extends AppException {
  const CacheException(super.message, [super.code]);
}

class PermissionException extends AppException {
  const PermissionException(super.message, [super.code]);
}

class ValidationException extends AppException {
  final Map<String, String>? errors;
  
  const ValidationException(super.message, [super.code, this.errors]);
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, [super.code]);
}