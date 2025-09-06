import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  
  const Failure(this.message, [this.code]);
  
  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class ServerFailure extends Failure {
  final int? statusCode;
  
  const ServerFailure(super.message, [super.code, this.statusCode]);
  
  @override
  List<Object?> get props => [message, code, statusCode];
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

class AudioFailure extends Failure {
  const AudioFailure(super.message, [super.code]);
}

class WebSocketFailure extends Failure {
  const WebSocketFailure(super.message, [super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  final Map<String, String>? errors;
  
  const ValidationFailure(super.message, [super.code, this.errors]);
  
  @override
  List<Object?> get props => [message, code, errors];
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, [super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}