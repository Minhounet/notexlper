import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
/// Use failures instead of exceptions for expected error cases.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure when a server/remote operation fails
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Failure when local storage operations fail
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// Failure when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure when a requested resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}
